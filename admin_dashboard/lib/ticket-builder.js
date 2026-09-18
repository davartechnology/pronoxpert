// Regroupe les picks resolus (recherche IA) en 1 a 4 "tickets", classes par cote croissante.
// Les 2 tickets aux cotes les plus basses sont marques 'free', les 2 aux cotes les plus
// hautes 'reward_ad' (regle produit demandee). Pour moins de 4 tickets, on utilise simplement
// les categories dans l'ordre (order_index 1..N) : c'est une simplification assumee tant que
// le comportement exact pour 1-3 tickets n'a pas ete precise autrement.

const MIN_PICKS_PER_TICKET = 5;
const MAX_TICKETS = 4;

function buildTickets(picks) {
  if (picks.length === 0) return [];

  const ticketCount = Math.min(MAX_TICKETS, Math.max(1, Math.floor(picks.length / MIN_PICKS_PER_TICKET)));

  // Repartition round-robin pour melanger les championnats dans chaque ticket.
  const groups = Array.from({ length: ticketCount }, () => []);
  picks.forEach((pick, i) => groups[i % ticketCount].push(pick));

  const tickets = groups.map((selections) => ({
    selections,
    totalOdds: selections.reduce((prod, s) => prod * s.odds, 1),
  }));

  tickets.sort((a, b) => a.totalOdds - b.totalOdds);
  return tickets;
}

module.exports = { buildTickets };
