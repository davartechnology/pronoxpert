// Recherche IA (OpenAI) pour choisir un marche par match, parmi un menu d'options a cote
// deja connue (calculees a partir des donnees reelles du site, jamais inventees par le modele).
// NOTE : verifie le nom du modele et le nom exact de l'outil de recherche web dans la doc
// OpenAI actuelle (console.openai.com/docs) si cette fonction renvoie une erreur 400/404 —
// l'API Responses et ses outils heberges evoluent.

const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4.1';
const BATCH_SIZE = 5;

// Construit, pour un match, le menu d'options autorisees (CLAUDE.md) avec leurs cotes reelles.
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

function buildPrompt(batch) {
  const lines = batch.map((m, idx) => {
    const opts = Object.entries(m.optionMenu)
      .map(([key, o]) => `   - ${key}: ${o.desc} (cote ${o.odds})`)
      .join('\n');
    return `Match ${idx}: ${m.homeTeam} - ${m.awayTeam} (${m.league}, ${m.country}), coup d'envoi ${m.expectedStart}\nOptions disponibles:\n${opts}`;
  }).join('\n\n');

  return `Tu choisis un pronostic pour chacun des matchs suivants, en te basant sur une recherche reelle (5 derniers matchs de chaque equipe, confrontations directes, blessures/absences). Pour CHAQUE match, choisis UNE SEULE option parmi celles listees (jamais une option hors de cette liste, jamais une cote inventee).

${lines}

Reponds UNIQUEMENT avec un tableau JSON strict, un objet par match, dans cet ordre exact :
[{"matchIndex": 0, "chosenKey": "DC_1X", "justification": "une phrase courte basee sur des faits verifiables", "confidence": "high|medium|low"}, ...]

Si aucune option ne te semble raisonnable pour un match (donnees insuffisantes), choisis quand meme celle qui a la marge de securite la plus large (ex: double chance sur le favori) et mets confidence a "low".`;
}

async function researchBatch(batch, apiKey) {
  const prompt = buildPrompt(batch);

  const res = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      tools: [{ type: 'web_search_preview' }],
      input: prompt,
    }),
  });

  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`OpenAI HTTP ${res.status}: ${errText.slice(0, 300)}`);
  }
  const data = await res.json();
  const text = data.output_text || extractTextFromResponses(data);
  const jsonMatch = text.match(/\[[\s\S]*\]/);
  if (!jsonMatch) throw new Error('Reponse OpenAI sans JSON exploitable: ' + text.slice(0, 300));
  return JSON.parse(jsonMatch[0]);
}

function extractTextFromResponses(data) {
  try {
    return (data.output || [])
      .flatMap((item) => (item.content || []).map((c) => c.text || ''))
      .join('\n');
  } catch (e) {
    return '';
  }
}

// Recherche tous les matchs par lots de BATCH_SIZE, en parallele, et renvoie
// { matchId, chosenOption, justification, confidence } pour chaque match resolu.
async function researchAllMatches(matches, apiKey) {
  const withMenus = matches
    .map((m) => ({ ...m, optionMenu: buildOptionMenu(m) }))
    .filter((m) => Object.keys(m.optionMenu).length > 0);

  const batches = [];
  for (let i = 0; i < withMenus.length; i += BATCH_SIZE) batches.push(withMenus.slice(i, i + BATCH_SIZE));

  const results = [];
  const batchResults = await Promise.all(
    batches.map(async (batch) => {
      try {
        return { batch, picks: await researchBatch(batch, apiKey) };
      } catch (e) {
        console.error('Batch de recherche echoue:', e.message);
        return { batch, picks: [] };
      }
    })
  );

  for (const { batch, picks } of batchResults) {
    for (const pick of picks) {
      const match = batch[pick.matchIndex];
      const option = match && match.optionMenu[pick.chosenKey];
      if (!match || !option) continue;
      results.push({
        matchId: match.id,
        homeTeam: match.homeTeam,
        awayTeam: match.awayTeam,
        league: match.league,
        country: match.country,
        expectedStart: match.expectedStart,
        betTypeId: option.betTypeId,
        label: option.label,
        odds: option.odds,
        optionDesc: option.desc,
        justification: pick.justification,
        confidence: pick.confidence,
      });
    }
  }
  return results;
}

module.exports = { researchAllMatches, buildOptionMenu };
