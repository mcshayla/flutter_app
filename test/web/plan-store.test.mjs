import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createLocalStore, createRemoteStore, moveLocalToAccount } from '../../web/js/plan-store.js';
import { fakeSupabase } from './fake-supabase.mjs';

function memoryStorage() {
  const m = new Map();
  return {
    getItem: k => (m.has(k) ? m.get(k) : null),
    setItem: (k, v) => m.set(k, String(v)),
    removeItem: k => m.delete(k),
  };
}

test('local store starts empty', async () => {
  const s = createLocalStore(memoryStorage());
  const p = await s.load();
  assert.deepEqual(p, { profile: {}, checklist: [], guests: [], totalBudget: 0, budgetItems: [], yesByCategory: {} });
  assert.equal(s.hasData(), false);
});

test('local store saves everything across reloads', async () => {
  const storage = memoryStorage();
  const s = createLocalStore(storage);
  await s.saveProfile({ wedding_date: '2027-06-12' });
  const [t] = await s.addTasks([{ title: 'Book venue', category: 'Venue' }]);
  assert.ok(t.id);
  await s.updateTask(t.id, { is_completed: true });
  const g = await s.addGuest({ first_name: 'Ana' });
  await s.updateGuest(g.id, { rsvp_status: 'accepted' });
  await s.setTotalBudget(20000);
  const b = await s.addBudgetItem({ item_name: 'Venue', estimated_cost: 8000 });
  await s.updateBudgetItem(b.id, { actual_cost: 7500 });

  const again = await createLocalStore(storage).load();
  assert.equal(again.profile.wedding_date, '2027-06-12');
  assert.equal(again.checklist[0].is_completed, true);
  assert.equal(again.guests[0].rsvp_status, 'accepted');
  assert.equal(again.totalBudget, 20000);
  assert.equal(again.budgetItems[0].actual_cost, 7500);
  assert.equal(createLocalStore(storage).hasData(), true);
});

test('local store deletes', async () => {
  const s = createLocalStore(memoryStorage());
  const [a, b] = await s.addTasks([{ title: 'A' }, { title: 'B' }]);
  await s.deleteTask(a.id);
  assert.deepEqual((await s.load()).checklist.map(t => t.title), ['B']);
  await s.deleteAllTasks();
  assert.equal((await s.load()).checklist.length, 0);
  const g = await s.addGuest({ first_name: 'Ana' });
  await s.deleteGuest(g.id);
  const i = await s.addBudgetItem({ item_name: 'X' });
  await s.deleteBudgetItem(i.id);
  const p = await s.load();
  assert.equal(p.guests.length + p.budgetItems.length + b.title.length, 1);
});

test('local store survives corrupt or blocked storage', async () => {
  const bad = memoryStorage();
  bad.setItem('easiyest.plan.v1', '{not json');
  assert.equal((await createLocalStore(bad).load()).checklist.length, 0);
  const blocked = { getItem() { throw new Error('blocked'); }, setItem() { throw new Error('blocked'); }, removeItem() {} };
  const s = createLocalStore(blocked);
  await s.addGuest({ first_name: 'Ana' });
  assert.equal((await s.load()).guests.length, 1); // kept in memory for this visit
});

test('remote store reads only the signed-in couple\'s rows', async () => {
  const db = fakeSupabase({
    wedding_profiles: [{ user_id: 'u1', wedding_date: '2027-06-12' }, { user_id: 'u2', wedding_date: '2028-01-01' }],
    user_checklist_items: [
      { id: 't2', user_id: 'u1', title: 'Second', display_order: 2 },
      { id: 't1', user_id: 'u1', title: 'First', display_order: 1 },
      { id: 'tx', user_id: 'u2', title: 'Not mine', display_order: 0 },
    ],
    guests: [{ id: 'g1', user_id: 'u1', first_name: 'Ana', created_at: '1' }],
    user_budgets: [{ user_id: 'u1', total_budget: 30000 }],
    budget_items: [{ id: 'b1', user_id: 'u1', item_name: 'Venue', created_at: '1' }],
    user_diamonds: [{ user_id: 'u1', vendor_id: 'v9', category: 'Venue' }, { user_id: 'u2', vendor_id: 'v8', category: 'DJ' }],
  });
  const p = await createRemoteStore(db, 'u1').load();
  assert.equal(p.profile.wedding_date, '2027-06-12');
  assert.deepEqual(p.checklist.map(t => t.title), ['First', 'Second']);
  assert.equal(p.guests.length, 1);
  assert.equal(p.totalBudget, 30000);
  assert.equal(p.budgetItems.length, 1);
  assert.deepEqual(p.yesByCategory, { Venue: 'v9' });
});

test('remote store writes with the couple\'s user id', async () => {
  const db = fakeSupabase({});
  const s = createRemoteStore(db, 'u1');
  await s.saveProfile({ wedding_date: '2027-06-12' });
  await s.saveProfile({ partner_name_1: 'Ana' });
  const [t] = await s.addTasks([{ id: 'local-1', user_id: 'someone', title: 'Book venue' }]);
  assert.notEqual(t.id, 'local-1');
  await s.updateTask(t.id, { is_completed: true });
  const g = await s.addGuest({ first_name: 'Ana' });
  await s.updateGuest(g.id, { rsvp_status: 'invited' });
  await s.setTotalBudget(100);
  await s.setTotalBudget(200);
  const b = await s.addBudgetItem({ item_name: 'Cake', estimated_cost: 500 });
  await s.deleteBudgetItem(b.id);

  assert.deepEqual(db.tables.wedding_profiles, [{ user_id: 'u1', wedding_date: '2027-06-12', partner_name_1: 'Ana' }]);
  assert.equal(db.tables.user_checklist_items[0].user_id, 'u1');
  assert.equal(db.tables.user_checklist_items[0].is_completed, true);
  assert.equal(db.tables.guests[0].rsvp_status, 'invited');
  assert.deepEqual(db.tables.user_budgets, [{ user_id: 'u1', total_budget: 200 }]);
  assert.equal(db.tables.budget_items.length, 0);
});

test('remote store throws Supabase errors so the page can show them', async () => {
  const db = fakeSupabase({}, { failOn: 'guests' });
  await assert.rejects(createRemoteStore(db, 'u1').addGuest({ first_name: 'Ana' }), /guests failed/);
});

test('moving a browser plan into a new account copies everything and clears the browser', async () => {
  const storage = memoryStorage();
  const local = createLocalStore(storage);
  await local.saveProfile({ wedding_date: '2027-06-12', partner_name_1: 'Ana' });
  await local.addTasks([{ title: 'Book venue', display_order: 0 }, { title: 'Pick DJ', display_order: 1 }]);
  await local.addGuest({ first_name: 'Ben', last_name: 'Ortiz' });
  await local.setTotalBudget(25000);
  await local.addBudgetItem({ item_name: 'Venue', estimated_cost: 9000 });

  const db = fakeSupabase({});
  const moved = await moveLocalToAccount(local, createRemoteStore(db, 'u1'));
  assert.deepEqual(moved, { tasks: 2, guests: 1, budgetItems: 1 });
  assert.equal(db.tables.wedding_profiles[0].wedding_date, '2027-06-12');
  assert.equal(db.tables.user_budgets[0].total_budget, 25000);
  assert.ok(db.tables.user_checklist_items.every(t => t.user_id === 'u1' && !t.id.startsWith('local-')));
  assert.equal(local.hasData(), false);
});

test('moving into an account that already has a plan keeps the account\'s data and skips duplicates', async () => {
  const local = createLocalStore(memoryStorage());
  await local.saveProfile({ wedding_date: '2027-06-12', partner_name_2: 'Ben' });
  await local.addTasks([{ title: 'book venue' }, { title: 'Order cake' }]);
  await local.addGuest({ first_name: 'Ana', last_name: 'Lee' });
  await local.addGuest({ first_name: 'Cy' });
  await local.setTotalBudget(10);

  const db = fakeSupabase({
    wedding_profiles: [{ user_id: 'u1', wedding_date: '2028-01-01' }],
    user_checklist_items: [{ id: 't1', user_id: 'u1', title: 'Book venue', display_order: 5 }],
    guests: [{ id: 'g1', user_id: 'u1', first_name: 'ana', last_name: 'lee' }],
    user_budgets: [{ user_id: 'u1', total_budget: 40000 }],
  });
  const moved = await moveLocalToAccount(local, createRemoteStore(db, 'u1'));
  assert.deepEqual(moved, { tasks: 1, guests: 1, budgetItems: 0 });
  assert.equal(db.tables.wedding_profiles[0].wedding_date, '2028-01-01');
  assert.equal(db.tables.wedding_profiles[0].partner_name_2, 'Ben');
  assert.equal(db.tables.user_budgets[0].total_budget, 40000);
  const cake = db.tables.user_checklist_items.find(t => t.title === 'Order cake');
  assert.equal(cake.display_order, 6);
});

test('moving keeps the browser copy if saving fails', async () => {
  const local = createLocalStore(memoryStorage());
  await local.addGuest({ first_name: 'Ana' });
  const db = fakeSupabase({}, { failOn: 'guests' });
  await assert.rejects(moveLocalToAccount(local, createRemoteStore(db, 'u1')));
  assert.equal(local.hasData(), true);
});
