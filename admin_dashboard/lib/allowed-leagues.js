// Competitions autorisees (reprises des regles du projet de paris) : [pays, ligue] normalises
// (minuscules, sans accents, sans espaces doubles).
function norm(s) {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim();
}

const ALLOWED = [
  ['angleterre', 'premier league'], ['angleterre', 'championship'], ['angleterre', 'league one'], ['angleterre', 'league two'], ['angleterre', 'fa cup'],
  ['espagne', 'laliga'], ['espagne', 'laliga 2'], ['espagne', 'copa del rey'], ['espagne', 'supercopa de espana'],
  ['allemagne', 'bundesliga'], ['allemagne', '2. bundesliga'], ['allemagne', 'dfl-supercup'],
  ['italie', 'serie a'], ['italie', 'serie b'], ['italie', 'coppa italia'], ['italie', 'supercoppa italiana'],
  ['france', 'ligue 1'], ['france', 'ligue 2'], ['france', 'coupe de france'],
  ['bresil', 'brasileirao serie a'], ['bresil', 'serie b'],
  ['etats-unis', 'mls'], ['canada', 'mls'],
  ['mexique', 'liga mx'], ['mexique', 'liga de expansion mx'],
  ['portugal', 'primeira liga'],
  ['pays-bas', 'eredivisie'], ['pays-bas', 'eerste divisie'], ['pays-bas', 'tweede divisie'],
  ['arabie saoudite', 'saudi pro league'], ['arabie saoudite', 'saudi first division'],
  ['argentine', 'liga profesional'],
  ['turquie', 'super lig'],
  ['belgique', 'belgian pro league'], ['belgique', 'challenger pro league'],
  ['japon', 'j1 league'],
  ['colombie', 'primera a'],
  ['chili', 'primera division'],
  ['uruguay', 'primera division'],
  ['egypte', 'egyptian premier league'],
  ['afrique du sud', 'betway premiership'],
];

const ALLOWED_SET = new Set(ALLOWED.map(([c, l]) => norm(c) + '|' + norm(l)));

function isAllowed(country, league) {
  return ALLOWED_SET.has(norm(country) + '|' + norm(league));
}

module.exports = { isAllowed };
