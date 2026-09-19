// Etape 2/2 : combine candidates.json (matchs + options + cotes reelles) avec picks.json
// (mes choix de marche par match, issus d'une recherche reelle H2H/forme/blessures, pas d'un
// appel a une API IA payante), construit les 4 tickets par paliers de cote et les ecrit dans
// Supabase.
//
// Format attendu de picks.json : [{ "matchId": 123, "chosenKey": "DC_1X", "justification": "..." }, ...]

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const fs = require('fs');
const { buildTickets } = require('../admin_dashboard/lib/ticket-builder');
const { getCategories, clearUpcomingPendingMatches, insertMatches, updateCategoryOdds } = require('../admin_dashboard/lib/supabase-writer');

const CANDIDATES_FILE = process.argv[2] || 'candidates.json';
const PICKS_FILE = process.argv[3] || 'picks.json';

async function main() {
  const candidates = JSON.parse(fs.readFileSync(CANDIDATES_FILE, 'utf-8'));
  const picksRaw = JSON.parse(fs.readFileSync(PICKS_FILE, 'utf-8'));

  const byId = new Map(candidates.map((c) => [c.matchId, c]));
  const picks = [];
  for (const p of picksRaw) {
    const match = byId.get(p.matchId);
    if (!match) {
      console.log(`Ignore : matchId ${p.matchId} introuvable dans ${CANDIDATES_FILE}.`);
      continue;
    }
    if (!match.optionMenu[p.chosenKey]) {
      console.log(`Ignore : option ${p.chosenKey} introuvable pour ${match.match}.`);
      continue;
    }
    picks.push({
      matchId: match.matchId,
      homeTeam: match.homeTeam,
      awayTeam: match.awayTeam,
      league: match.league,
      country: match.country,
      expectedStart: match.expectedStart,
      optionMenu: match.optionMenu,
      chosenKey: p.chosenKey,
      justification: p.justification,
    });
  }
  console.log(`${picks.length} picks valides sur ${picksRaw.length}.`);

  const tickets = buildTickets(picks);
  console.log(`${tickets.length} ticket(s) construit(s).`);
  if (tickets.length === 0) {
    console.log('Rien a ecrire. Fin.');
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
