// Construit 4 tickets par paliers de cote croissants (>=5, >=10, >=25, >=100), en ajoutant
// des matchs un par un (option la plus sure d'abord) jusqu'a depasser le seuil, plutot que de
// prendre une ou deux grosses cotes risquees. Un match deja utilise dans un ticket precedent
// peut etre reutilise avec une AUTRE option (marche different) plutot que repete a l'identique.

const TIER_TARGETS = [5, 10, 25, 100];

function optionEntries(pick) {
  // Trie les options du menu par cote croissante (la plus sure d'abord).
  return Object.entries(pick.optionMenu)
    .map(([key, o]) => ({ key, ...o }))
    .sort((a, b) => a.odds - b.odds);
}

function buildTickets(picks) {
  if (picks.length === 0) return [];

  // usedKeys[matchId] = Set des options deja utilisees pour ce match (tous tickets confondus)
  const usedKeys = new Map();
  const tickets = [];

  for (const target of TIER_TARGETS) {
    const selections = [];
    let product = 1;

    // Ordre : matchs les moins souvent reutilises d'abord (pour repartir sur des matchs frais
    // avant de recycler ceux deja presents dans un ticket precedent).
    const order = [...picks].sort((a, b) => {
      const usedA = (usedKeys.get(a.matchId) || new Set()).size;
      const usedB = (usedKeys.get(b.matchId) || new Set()).size;
      return usedA - usedB;
    });

    for (const pick of order) {
      if (product >= target) break;

      const already = usedKeys.get(pick.matchId) || new Set();
      const entries = optionEntries(pick);
      const nextOption = entries.find((e) => !already.has(e.key));
      if (!nextOption) continue; // toutes les options de ce match deja utilisees

      const isFirstUseOfMatch = already.size === 0;
      selections.push({
        matchId: pick.matchId,
        homeTeam: pick.homeTeam,
        awayTeam: pick.awayTeam,
        league: pick.league,
        country: pick.country,
        expectedStart: pick.expectedStart,
        betTypeId: nextOption.betTypeId,
        label: nextOption.label,
        odds: nextOption.odds,
        optionDesc: nextOption.desc,
        // La justification IA d'origine ne s'applique qu'a l'option choisie par la recherche ;
        // pour une option de secours (reutilisation), on reste honnete plutot que d'inventer un motif.
        justification: nextOption.key === pick.chosenKey
          ? pick.justification
          : `Selection alternative sur ce match (${nextOption.desc}), marche differencie pour eviter un doublon exact avec un autre ticket.`,
      });
      product *= nextOption.odds;

      const updated = new Set(already);
      updated.add(nextOption.key);
      usedKeys.set(pick.matchId, updated);
    }

    if (selections.length > 0) {
      tickets.push({ selections, totalOdds: product });
    }
  }

  return tickets;
}

module.exports = { buildTickets };
