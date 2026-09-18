// Ecriture dans Supabase via la cle service_role (contourne RLS, usage serveur uniquement,
// ne jamais exposer cette cle cote client).

async function supabaseRequest(supabaseUrl, serviceRoleKey, path, options = {}) {
  const res = await fetch(`${supabaseUrl}/rest/v1/${path}`, {
    ...options,
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
      'Content-Type': 'application/json',
      Prefer: options.prefer || 'return=representation',
      ...options.headers,
    },
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`Supabase ${options.method || 'GET'} ${path} -> HTTP ${res.status}: ${text.slice(0, 300)}`);
  }
  const text = await res.text();
  return text ? JSON.parse(text) : null;
}

async function getCategories(supabaseUrl, serviceRoleKey) {
  return supabaseRequest(supabaseUrl, serviceRoleKey, 'categories?select=*&order=order_index.asc');
}

// Supprime les picks encore "pending" et pas encore joues (ils vont etre remplaces par le
// nouveau lot). Les matchs deja resolus (won/lost) sont conserves pour l'historique/stats.
async function clearUpcomingPendingMatches(supabaseUrl, serviceRoleKey) {
  const nowIso = new Date().toISOString();
  await supabaseRequest(
    supabaseUrl,
    serviceRoleKey,
    `matches?result=eq.pending&match_time=gt.${encodeURIComponent(nowIso)}`,
    { method: 'DELETE', prefer: 'return=minimal' }
  );
}

async function insertMatches(supabaseUrl, serviceRoleKey, rows) {
  if (rows.length === 0) return;
  await supabaseRequest(supabaseUrl, serviceRoleKey, 'matches', {
    method: 'POST',
    body: JSON.stringify(rows),
  });
}

async function updateCategoryOdds(supabaseUrl, serviceRoleKey, categoryId, odds) {
  await supabaseRequest(supabaseUrl, serviceRoleKey, `categories?id=eq.${categoryId}`, {
    method: 'PATCH',
    prefer: 'return=minimal',
    body: JSON.stringify({ odds }),
  });
}

module.exports = { getCategories, clearUpcomingPendingMatches, insertMatches, updateCategoryOdds };
