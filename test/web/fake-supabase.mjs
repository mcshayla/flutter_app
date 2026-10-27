// A tiny in-memory stand-in for the supabase-js query builder: just the calls
// plan-store.js makes (select/insert/update/upsert/delete, eq, order,
// maybeSingle). Results resolve as { data, error } like the real client.

let nextId = 1;

export function fakeSupabase(seed, { failOn } = {}) {
  const tables = {};
  for (const [name, rows] of Object.entries(seed)) tables[name] = rows.map(r => ({ ...r }));

  function from(table) {
    tables[table] ??= [];
    const q = { op: 'select', filters: [], orderBy: null, single: false, payload: null, conflict: null, returning: false };
    const rowsMatching = () => tables[table].filter(r => q.filters.every(([c, v]) => r[c] === v));

    function run() {
      if (failOn === table) return { data: null, error: { message: `${table} failed` } };
      let data = null;
      if (q.op === 'select') {
        data = rowsMatching().map(r => ({ ...r }));
        if (q.orderBy) {
          const [col, asc] = q.orderBy;
          data.sort((a, b) => (a[col] > b[col] ? 1 : a[col] < b[col] ? -1 : 0) * (asc ? 1 : -1));
        }
        if (q.single) data = data[0] ?? null;
      } else if (q.op === 'insert') {
        const rows = (Array.isArray(q.payload) ? q.payload : [q.payload]).map(r => ({ id: `db-${nextId++}`, ...r }));
        tables[table].push(...rows);
        data = q.returning ? rows.map(r => ({ ...r })) : null;
      } else if (q.op === 'update') {
        const hit = rowsMatching();
        hit.forEach(r => Object.assign(r, q.payload));
        data = q.returning ? hit.map(r => ({ ...r })) : null;
      } else if (q.op === 'upsert') {
        const keys = String(q.conflict).split(',');
        const existing = tables[table].find(r => keys.every(k => r[k] === q.payload[k]));
        if (existing) Object.assign(existing, q.payload);
        else tables[table].push({ ...q.payload });
      } else if (q.op === 'delete') {
        tables[table] = tables[table].filter(r => !q.filters.every(([c, v]) => r[c] === v));
      }
      return { data, error: null };
    }

    const builder = {
      select() { if (q.op === 'select') q.op = 'select'; else q.returning = true; return builder; },
      insert(p) { q.op = 'insert'; q.payload = p; return builder; },
      update(p) { q.op = 'update'; q.payload = p; return builder; },
      upsert(p, opts) { q.op = 'upsert'; q.payload = p; q.conflict = opts?.onConflict; return builder; },
      delete() { q.op = 'delete'; return builder; },
      eq(c, v) { q.filters.push([c, v]); return builder; },
      order(c, opts) { q.orderBy = [c, opts?.ascending !== false]; return builder; },
      maybeSingle() { q.single = true; return builder; },
      then(resolve, reject) { return Promise.resolve(run()).then(resolve, reject); },
    };
    return builder;
  }

  return { from, tables };
}
