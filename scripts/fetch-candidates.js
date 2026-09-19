// Etape 1/2 : connexion au site, recuperation des matchs des competitions autorisees dans la
// fenetre de temps, et calcul du menu d'options (cotes reelles) pour chacun. Ecrit
// candidates.json, que Claude Code utilise ensuite pour faire la recherche (H2H, forme,
// blessures) et choisir un marche par match — sans appel a une API IA payante.

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const fs = require('fs');
const { login, fetchFootballEvents, withinWindow } = require('../admin_dashboard/lib/site-api');
const { isAllowed } = require('../admin_dashboard/lib/allowed-leagues');
const { buildOptionMenu } = require('../admin_dashboard/lib/match-options');

const WINDOW_HOURS = parseInt(process.env.WINDOW_HOURS || '30', 10);
const OUT_FILE = process.argv[2] || 'candidates.json';

async function main() {
  console.log('Connexion au site de paris...');
  const token = await login(process.env.SITE_USER, process.env.SITE_PASS);

  console.log('Recuperation des matchs de football...');
  const allEvents = await fetchFootballEvents(token);

  const candidates = allEvents
    .filter((m) => isAllowed(m.country, m.league) && withinWindow(m.expectedStart, WINDOW_HOURS))
    .map((m) => ({
      matchId: m.id,
      homeTeam: m.homeTeam,
      awayTeam: m.awayTeam,
      match: m.match,
      league: m.league,
      country: m.country,
      expectedStart: m.expectedStart,
      optionMenu: buildOptionMenu(m),
    }))
    .filter((m) => Object.keys(m.optionMenu).length > 0);

  fs.writeFileSync(OUT_FILE, JSON.stringify(candidates, null, 1));
  console.log(`${candidates.length} matchs eligibles ecrits dans ${OUT_FILE}.`);
}

main().catch((err) => {
  console.error('ERREUR FATALE:', err.message);
  process.exit(1);
});
