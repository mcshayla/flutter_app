// A couple's Love (hearts) and YES (one chosen vendor per type).
// Same two-store pattern as plan-store.js: in this browser when logged out,
// in the app's users_loved / user_diamonds tables when logged in, and
// movePicksToAccount carries browser picks over after logging in.

const KEY = 'easiyest.picks.v1';

export function createLocalPicks(storage) {
  let memory = null;
  const read = () => {
    if (memory) return memory;
    try {
      const raw = JSON.parse(storage.getItem(KEY) ?? 'null');
      if (raw) return { loved: raw.loved ?? [], yes: raw.yes ?? {} };
    } catch { /* corrupt or blocked */ }
    return { loved: [], yes: {} };
  };
  const write = p => {
    try { storage.setItem(KEY, JSON.stringify(p)); memory = null; } catch { memory = p; }
  };
  return {
    kind: 'local',
    async load() {
      const p = read();
      return { loved: new Set(p.loved), yes: { ...p.yes } };
    },
    hasData() {
      const p = read();
      return p.loved.length > 0 || Object.keys(p.yes).length > 0;
    },
    clear() {
      memory = null;
      try { storage.removeItem(KEY); } catch { /* nothing to clear */ }
    },
    async setLove(vendorId, on) {
      const p = read();
      p.loved = p.loved.filter(id => id !== vendorId);
      if (on) p.loved.unshift(vendorId);
      write(p);
    },
    async setYes(vendorId, category, on) {
      const p = read();
      if (on) p.yes[category] = vendorId;
      else if (p.yes[category] === vendorId) delete p.yes[category];
      write(p);
    },
  };
}

export function createRemotePicks(client, userId) {
  async function run(query) {
    const { data, error } = await query;
    if (error) throw new Error(error.message || 'Could not save to your account');
    return data;
  }
  return {
    kind: 'remote',
    async load() {
      const [loved, diamonds] = await Promise.all([
        run(client.from('users_loved').select('loved_vendor_id, hearted').eq('loved_user_id', userId)),
        run(client.from('user_diamonds').select('vendor_id, category').eq('user_id', userId)),
      ]);
      const yes = {};
      for (const d of diamonds ?? []) if (d.category && d.vendor_id) yes[d.category] = d.vendor_id;
      return { loved: new Set((loved ?? []).filter(l => l.hearted).map(l => l.loved_vendor_id)), yes };
    },
    hasData: () => true,
    setLove: (vendorId, on) => run(client.from('users_loved').upsert(
      { loved_user_id: userId, loved_vendor_id: vendorId, hearted: on }, { onConflict: 'loved_user_id,loved_vendor_id' })),
    setYes: (vendorId, category, on) => (on
      ? run(client.from('user_diamonds').upsert({ user_id: userId, vendor_id: vendorId, category }, { onConflict: 'user_id,category' }))
      : run(client.from('user_diamonds').delete().eq('user_id', userId).eq('category', category).eq('vendor_id', vendorId))),
  };
}

/** Browser picks into the account. The account's existing YES in a category wins. */
export async function movePicksToAccount(local, remote) {
  const from = await local.load();
  const to = await remote.load();
  let loved = 0, yes = 0;
  for (const id of from.loved) {
    if (!to.loved.has(id)) { await remote.setLove(id, true); loved++; }
  }
  for (const [category, id] of Object.entries(from.yes)) {
    if (!to.yes[category]) { await remote.setYes(id, category, true); yes++; }
  }
  local.clear();
  return { loved, yes };
}
