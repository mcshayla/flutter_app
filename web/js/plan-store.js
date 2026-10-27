// Where the Plan page keeps a couple's checklist, guests and budget.
//
// Two stores with the same methods:
//   createLocalStore  – not logged in: kept in this browser (localStorage).
//   createRemoteStore – logged in: the same Supabase tables the Flutter app
//                       uses, so the website and the phone app stay in sync.
// moveLocalToAccount copies a browser plan into an account after logging in.

const KEY = 'easiyest.plan.v1';
const empty = () => ({ profile: {}, checklist: [], guests: [], totalBudget: 0, budgetItems: [] });
const localId = () => `local-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;

export function createLocalStore(storage) {
  let memory = null; // used when storage is blocked (private mode, etc.)

  function read() {
    if (memory) return memory;
    try {
      const raw = storage.getItem(KEY);
      if (raw) return { ...empty(), ...JSON.parse(raw) };
    } catch { /* corrupt or blocked: start fresh */ }
    return empty();
  }

  function write(plan) {
    try {
      storage.setItem(KEY, JSON.stringify(plan));
      memory = null;
    } catch {
      memory = plan;
    }
  }

  function change(fn) {
    const plan = read();
    const result = fn(plan);
    write(plan);
    return Promise.resolve(result);
  }

  const patchIn = (list, id, patch) => list.map(r => (r.id === id ? { ...r, ...patch } : r));

  return {
    kind: 'local',
    load: () => Promise.resolve({ ...read(), yesByCategory: {} }),
    hasData() {
      const p = read();
      return Boolean(p.checklist.length || p.guests.length || p.budgetItems.length || p.totalBudget || Object.keys(p.profile).length);
    },
    clear() {
      memory = null;
      try { storage.removeItem(KEY); } catch { /* nothing to clear */ }
    },
    saveProfile: patch => change(p => (p.profile = { ...p.profile, ...patch })),
    addTasks: rows => change(p => {
      const added = rows.map(r => ({ is_completed: false, ...r, id: localId() }));
      p.checklist.push(...added);
      return added;
    }),
    updateTask: (id, patch) => change(p => { p.checklist = patchIn(p.checklist, id, patch); }),
    deleteTask: id => change(p => { p.checklist = p.checklist.filter(t => t.id !== id); }),
    deleteAllTasks: () => change(p => { p.checklist = []; }),
    addGuest: row => change(p => {
      const g = { ...row, id: localId(), created_at: new Date().toISOString() };
      p.guests.push(g);
      return g;
    }),
    updateGuest: (id, patch) => change(p => { p.guests = patchIn(p.guests, id, patch); }),
    deleteGuest: id => change(p => { p.guests = p.guests.filter(g => g.id !== id); }),
    setTotalBudget: amount => change(p => { p.totalBudget = amount; }),
    addBudgetItem: row => change(p => {
      const i = { is_paid: false, ...row, id: localId(), created_at: new Date().toISOString() };
      p.budgetItems.push(i);
      return i;
    }),
    updateBudgetItem: (id, patch) => change(p => { p.budgetItems = patchIn(p.budgetItems, id, patch); }),
    deleteBudgetItem: id => change(p => { p.budgetItems = p.budgetItems.filter(i => i.id !== id); }),
  };
}

export function createRemoteStore(client, userId) {
  async function run(query) {
    const { data, error } = await query;
    if (error) throw new Error(error.message || 'Could not save to your account');
    return data;
  }
  // Never send a browser id or someone else's user id to the database.
  const clean = row => {
    const { id, user_id, created_at, ...rest } = row;
    return { ...rest, user_id: userId };
  };
  const mine = (table, op) => op(client.from(table)).eq('user_id', userId);

  return {
    kind: 'remote',
    async load() {
      const [profile, checklist, guests, budget, budgetItems, diamonds] = await Promise.all([
        run(client.from('wedding_profiles').select('*').eq('user_id', userId).maybeSingle()),
        run(client.from('user_checklist_items').select('*').eq('user_id', userId).order('display_order', { ascending: true })),
        run(client.from('guests').select('*').eq('user_id', userId).order('created_at', { ascending: true })),
        run(client.from('user_budgets').select('*').eq('user_id', userId).maybeSingle()),
        run(client.from('budget_items').select('*').eq('user_id', userId).order('created_at', { ascending: true })),
        run(client.from('user_diamonds').select('vendor_id, category').eq('user_id', userId)),
      ]);
      const yesByCategory = {};
      for (const d of diamonds ?? []) if (d.category && d.vendor_id) yesByCategory[d.category] = d.vendor_id;
      return {
        profile: profile ?? {},
        checklist: checklist ?? [],
        guests: guests ?? [],
        totalBudget: Number(budget?.total_budget) || 0,
        budgetItems: budgetItems ?? [],
        yesByCategory,
      };
    },
    hasData: () => true,
    async saveProfile(patch) {
      const existing = await run(client.from('wedding_profiles').select('*').eq('user_id', userId).maybeSingle());
      const row = { ...(existing ?? {}), ...patch, user_id: userId };
      await run(client.from('wedding_profiles').upsert(row, { onConflict: 'user_id' }));
      return row;
    },
    addTasks: async rows => (rows.length ? run(client.from('user_checklist_items').insert(rows.map(clean)).select()) : []),
    updateTask: (id, patch) => run(mine('user_checklist_items', t => t.update(patch).eq('id', id))),
    deleteTask: id => run(mine('user_checklist_items', t => t.delete().eq('id', id))),
    deleteAllTasks: () => run(mine('user_checklist_items', t => t.delete())),
    addGuest: async row => (await run(client.from('guests').insert(clean(row)).select()))[0],
    updateGuest: (id, patch) => run(mine('guests', t => t.update(patch).eq('id', id))),
    deleteGuest: id => run(mine('guests', t => t.delete().eq('id', id))),
    setTotalBudget: amount => run(client.from('user_budgets').upsert({ user_id: userId, total_budget: amount }, { onConflict: 'user_id' })),
    addBudgetItem: async row => (await run(client.from('budget_items').insert(clean(row)).select()))[0],
    updateBudgetItem: (id, patch) => run(mine('budget_items', t => t.update(patch).eq('id', id))),
    deleteBudgetItem: id => run(mine('budget_items', t => t.delete().eq('id', id))),
  };
}

/**
 * Copies a plan made before logging in into the account. Anything the
 * account already has wins: its wedding date, its total budget, and tasks
 * or guests with the same name are not duplicated. The browser copy is
 * cleared only after everything saved.
 */
export async function moveLocalToAccount(local, remote) {
  const from = await local.load();
  const to = await remote.load();
  const lower = s => String(s ?? '').trim().toLowerCase();

  const profilePatch = {};
  for (const [k, v] of Object.entries(from.profile)) if (v && !to.profile[k]) profilePatch[k] = v;
  if (Object.keys(profilePatch).length) await remote.saveProfile(profilePatch);

  const haveTasks = new Set(to.checklist.map(t => lower(t.title)));
  let order = to.checklist.reduce((max, t) => Math.max(max, (t.display_order ?? 0) + 1), 0);
  const tasks = from.checklist.filter(t => !haveTasks.has(lower(t.title))).map(t => ({ ...t, display_order: order++ }));
  await remote.addTasks(tasks);

  const haveGuests = new Set(to.guests.map(g => `${lower(g.first_name)}|${lower(g.last_name)}`));
  const guests = from.guests.filter(g => !haveGuests.has(`${lower(g.first_name)}|${lower(g.last_name)}`));
  for (const g of guests) await remote.addGuest(g);

  if (from.totalBudget && !to.totalBudget) await remote.setTotalBudget(from.totalBudget);
  for (const i of from.budgetItems) await remote.addBudgetItem(i);

  local.clear();
  return { tasks: tasks.length, guests: guests.length, budgetItems: from.budgetItems.length };
}
