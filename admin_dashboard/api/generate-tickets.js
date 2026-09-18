// Endpoint declenche par le cron Vercel (voir vercel.json). Peut aussi etre appele
// manuellement (GET) pour forcer une regeneration.
//
// Variables d'environnement requises (a definir dans Vercel > Settings > Environment Variables) :
//   SITE_USER, SITE_PASS         -> identifiants du compte sur le site de paris
//   OPENAI_API_KEY               -> cle API OpenAI (facturee separement)
//   SUPABASE_URL                 -> URL du projet Supabase
//   SUPABASE_SERVICE_ROLE_KEY    -> cle service_role (jamais la cle anon ici)
//   CRON_SECRET                  -> secret partage, verifie sur l'en-tete Authorization

const { login, fetchFootballEvents, withinWindow, eventSlug } = require('../lib/site-api');
const { isAllowed } = require('../lib/allowed-leagues');
const { researchAllMatches } = require('../lib/openai-research');
const { buildTickets } = require('../lib/ticket-builder');
const { getCategories, clearUpcomingPendingMatches, insertMatches, updateCategoryOdds } = require('../lib/supabase-writer');

const WINDOW_HOURS = 30; // fenetre glissante : matchs entre maintenant et +30h

module.exports = async function handler(req, res) {
  // Protection : seul Vercel Cron (avec le bon secret) ou un appel manuel autorise peut declencher.
  const authHeader = req.headers['authorization'] || '';
  if (process.env.CRON_SECRET && authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    res.status(401).json({ error: 'Non autorise' });
    return;
  }

  const log = [];
  try {
    log.push('Connexion au site de paris...');
    const token = await login(process.env.SITE_USER, process.env.SITE_PASS);

    log.push('Recuperation des matchs de football...');
    const allEvents = await fetchFootballEvents(token);

    const candidates = allEvents.filter(
      (m) => isAllowed(m.country, m.league) && withinWindow(m.expectedStart, WINDOW_HOURS)
    );
    log.push(`${candidates.length} matchs eligibles (competitions autorisees, fenetre ${WINDOW_HOURS}h).`);

    if (candidates.length === 0) {
      res.status(200).json({ ok: true, ticketsGenerated: 0, log });
      return;
    }

    log.push('Recherche IA (OpenAI) par lots...');
    const picks = await researchAllMatches(candidates, process.env.OPENAI_API_KEY);
    log.push(`${picks.length} matchs avec un pronostic resolu.`);

    const tickets = buildTickets(picks);
    log.push(`${tickets.length} ticket(s) construit(s).`);

    if (tickets.length === 0) {
      res.status(200).json({ ok: true, ticketsGenerated: 0, log });
      return;
    }

    const categories = await getCategories(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
    if (categories.length < tickets.length) {
      throw new Error(`Pas assez de categories en base (${categories.length}) pour ${tickets.length} tickets.`);
    }

    await clearUpcomingPendingMatches(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

    for (let i = 0; i < tickets.length; i++) {
      const category = categories[i]; // categories triees par order_index : 1,2 = free ; 3,4 = reward_ad
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
      log.push(`${category.name} (${category.tier}) : ${rows.length} selections, cote ${ticket.totalOdds.toFixed(2)}.`);
    }

    res.status(200).json({ ok: true, ticketsGenerated: tickets.length, log });
  } catch (err) {
    log.push('ERREUR: ' + err.message);
    res.status(500).json({ ok: false, error: err.message, log });
  }
};
