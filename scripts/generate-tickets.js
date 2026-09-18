// Script autonome (execute par GitHub Actions, planifie tous les jours). Meme logique que
// l'ancien endpoint Vercel api/generate-tickets.js, mais en script Node simple, sans limite
// de duree (contrairement a une fonction serverless sur un plan gratuit).

const path = require('path');
const { login, fetchFootballEvents, withinWindow } = require('../admin_dashboard/lib/site-api');
const { isAllowed } = require('../admin_dashboard/lib/allowed-leagues');
const { researchAllMatches } = require('../admin_dashboard/lib/openai-research');
const { buildTickets } = require('../admin_dashboard/lib/ticket-builder');
const { getCategories, clearUpcomingPendingMatches, insertMatches, updateCategoryOdds } = require('../admin_dashboard/lib/supabase-writer');

const WINDOW_HOURS = 30;

const REQUIRED_ENV = ['SITE_USER', 'SITE_PASS', 'OPENAI_API_KEY', 'SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];

async function main() {
  const missing = REQUIRED_ENV.filter((k) => !process.env[k]);
  if (missing.length > 0) {
    throw new Error('Variables d\'environnement manquantes: ' + missing.join(', '));
  }

  console.log('Connexion au site de paris...');
  const token = await login(process.env.SITE_USER, process.env.SITE_PASS);

  console.log('Recuperation des matchs de football...');
  const allEvents = await fetchFootballEvents(token);

  const candidates = allEvents.filter(
    (m) => isAllowed(m.country, m.league) && withinWindow(m.expectedStart, WINDOW_HOURS)
  );
  console.log(`${candidates.length} matchs eligibles (competitions autorisees, fenetre ${WINDOW_HOURS}h).`);

  if (candidates.length === 0) {
    console.log('Aucun match eligible. Fin.');
    return;
  }

  console.log('Recherche IA (OpenAI) par lots...');
  const picks = await researchAllMatches(candidates, process.env.OPENAI_API_KEY);
  console.log(`${picks.length} matchs avec un pronostic resolu.`);

  const tickets = buildTickets(picks);
  console.log(`${tickets.length} ticket(s) construit(s).`);

  if (tickets.length === 0) {
    console.log('Pas assez de picks pour un ticket. Fin.');
    return;
  }

  const categories = await getCategories(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  if (categories.length < tickets.length) {
    throw new Error(`Pas assez de categories en base (${categories.length}) pour ${tickets.length} tickets.`);
  }

  await clearUpcomingPendingMatches(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

  for (let i = 0; i < tickets.length; i++) {
    const category = categories[i];
    const ticket = tickets[i];

    const rows = ticket.selections.map((s) => ({
      category_id: category.id,
      championship: s.league,
      country: s.country,
      match_time: s.expectedStart,
      team1: s.homeTeam,
      team2: s.awayTeam,
      option_chosen: s.optionDesc,
      odds: s.odds,
      justification: s.justification,
      is_visible: true,
      result: 'pending',
    }));

    await insertMatches(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, rows);
    await updateCategoryOdds(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, category.id, ticket.totalOdds);
    console.log(`${category.name} (${category.tier}): ${rows.length} selections, cote ${ticket.totalOdds.toFixed(2)}.`);
  }

  console.log('Termine avec succes.');
}

main().catch((err) => {
  console.error('ERREUR FATALE:', err.message);
  process.exit(1);
});
