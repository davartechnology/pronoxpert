// Client HTTP direct pour paryajlakay.com (aucun navigateur necessaire : l'API expose
// un endpoint de connexion classique et des endpoints REST publics pour les evenements).

const SITE_AUTH_URL = 'https://hg-customer-api-prod.sporty-tech.net/api/authentication/token';
const SITE_EVENT_API = 'https://hg-event-api-prod.sporty-tech.net/api';
const APP_VERSION = '35210';

async function login(siteUser, sitePassword) {
  // Le site prefixe l'indicatif Haiti (+509) devant le numero local saisi par l'utilisateur.
  const loginValue = siteUser.startsWith('+') ? siteUser : `+509${siteUser}`;
  const res = await fetch(SITE_AUTH_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ login: loginValue, password: sitePassword, rememberMe: false, withRefresh: false }),
  });
  if (!res.ok) throw new Error('Echec de connexion au site (HTTP ' + res.status + ')');
  const data = await res.json();
  if (!data.access_token) throw new Error('Token absent de la reponse de connexion.');
  return data.access_token;
}

function apiHeaders(token) {
  return {
    Authorization: 'Bearer ' + token,
    Accept: 'application/json, text/plain, */*',
    'Accept-Language': 'fr',
    'App-Version': APP_VERSION,
    Referer: 'https://www.paryajlakay.com/',
  };
}

async function fetchTree(token, sportId) {
  const res = await fetch(`${SITE_EVENT_API}/eventcategories/${sportId}?fr`, { headers: apiHeaders(token) });
  if (!res.ok) throw new Error('Tree HTTP ' + res.status + ' pour sport ' + sportId);
  return res.json();
}

async function fetchEventsForCategory(token, categoryId) {
  const url = `${SITE_EVENT_API}/events?eventCategoryIds=${categoryId}&offset=0&length=60&fetchEventBetTypesMode=2&l=fr`;
  const res = await fetch(url, { headers: apiHeaders(token) });
  if (!res.ok) return [];
  return res.json();
}

function summarizeEvent(evt, countryName, leagueName) {
  return {
    id: evt.id,
    homeTeam: evt.homeTeamName,
    awayTeam: evt.awayTeamName,
    match: `${evt.homeTeamName} - ${evt.awayTeamName}`,
    expectedStart: evt.expectedStart,
    country: countryName,
    league: leagueName,
    markets: evt.eventBetTypes.map((bt) => ({
      eventBetTypeId: bt.id,
      name: bt.name,
      betTypeId: bt.betTypeId,
      items: bt.eventBetTypeItems.map((i) => ({
        id: i.id,
        betTypeItemId: i.betTypeItemId,
        label: i.shortName,
        odds: i.odds,
      })),
    })),
  };
}

async function fetchFootballEvents(token) {
  const tree = await fetchTree(token, '101');
  const countries = Object.values(tree);
  const leaves = [];
  for (const country of countries) {
    (function walk(node, countryName) {
      if (!node.subCategories || node.subCategories.length === 0) {
        if (node.eventsCount > 0) leaves.push({ id: node.id, name: node.name, country: countryName });
      } else {
        for (const sub of node.subCategories) walk(sub, countryName);
      }
    })(country, country.name);
  }

  const allEvents = [];
  const concurrency = 12;
  for (let i = 0; i < leaves.length; i += concurrency) {
    const batch = leaves.slice(i, i + concurrency);
    const results = await Promise.all(
      batch.map(async (leaf) => {
        try {
          const events = await fetchEventsForCategory(token, leaf.id);
          return events.map((e) => summarizeEvent(e, leaf.country, leaf.name));
        } catch (e) {
          return [];
        }
      })
    );
    for (const r of results) allEvents.push(...r);
  }
  const byId = new Map();
  for (const e of allEvents) byId.set(e.id, e);
  return [...byId.values()];
}

// Fenetre de temps : matchs entre `now` et `now + windowHours`.
function withinWindow(expectedStart, windowHours) {
  const start = new Date(expectedStart).getTime();
  const now = Date.now();
  return start > now && start <= now + windowHours * 3600 * 1000;
}

function slugify(name) {
  return name.toLowerCase().replace(/\s+/g, '-');
}

function eventSlug(m) {
  return `${slugify(m.homeTeam)}-${slugify(m.awayTeam)}-m${m.id}`;
}

module.exports = { login, fetchFootballEvents, withinWindow, eventSlug };
