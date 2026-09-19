// Construit, pour un match, le menu d'options autorisees (CLAUDE.md) avec leurs cotes reelles
// (aucun appel IA ici — juste de la lecture de donnees deja recuperees du site).
function buildOptionMenu(match) {
  const options = {};
  const dc = match.markets.find((m) => m.name === 'Double chance');
  if (dc) {
    for (const item of dc.items) {
      if (['1X', 'X2', '12'].includes(item.label)) {
        options[`DC_${item.label}`] = { betTypeId: 10008, label: item.label, odds: item.odds, desc: `Double chance ${item.label}` };
      }
    }
  }
  const total = match.markets.find((m) => m.name === 'Nombre de buts' && m.betTypeId === 10003 && m.items.some((i) => i.label === '> 2.5'));
  if (total) {
    for (const item of total.items) {
      if (item.label === '> 2.5') options.TOTAL_OVER25 = { betTypeId: 10003, label: '> 2.5', odds: item.odds, desc: 'Total buts +2.5' };
      if (item.label === '< 2.5') options.TOTAL_UNDER25 = { betTypeId: 10003, label: '< 2.5', odds: item.odds, desc: 'Total buts -2.5' };
    }
  }
  const victory = match.markets.find((m) => m.name === 'Résultat du match');
  if (victory) {
    for (const item of victory.items) {
      if (item.label === '1') options.VICTORY_HOME = { betTypeId: 10001, label: '1', odds: item.odds, desc: `Victoire ${match.homeTeam}` };
      if (item.label === '2') options.VICTORY_AWAY = { betTypeId: 10001, label: '2', odds: item.odds, desc: `Victoire ${match.awayTeam}` };
    }
  }
  return options;
}

module.exports = { buildOptionMenu };
