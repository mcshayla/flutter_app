import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createLocalPicks, createRemotePicks, movePicksToAccount } from '../../web/js/picks.js';
import { budgetCategoryFor } from '../../web/js/plan-logic.js';
import { fakeSupabase } from './fake-supabase.mjs';

function memoryStorage() {
  const m = new Map();
  return { getItem: k => (m.has(k) ? m.get(k) : null), setItem: (k, v) => m.set(k, String(v)), removeItem: k => m.delete(k) };
}

test('local picks: love, unlove, one YES per category, kept across reloads', async () => {
  const storage = memoryStorage();
  const p = createLocalPicks(storage);
  await p.setLove('v1', true);
  await p.setLove('v2', true);
  await p.setLove('v1', false);
  await p.setYes('v3', 'Venue', true);
  await p.setYes('v4', 'Venue', true); // replaces v3
  await p.setYes('v5', 'DJ', true);
  await p.setYes('v5', 'DJ', false);
  const again = await createLocalPicks(storage).load();
  assert.deepEqual([...again.loved], ['v2']);
  assert.deepEqual(again.yes, { Venue: 'v4' });
  assert.equal(createLocalPicks(storage).hasData(), true);
});

test('remote picks read and write the app tables', async () => {
  const db = fakeSupabase({
    users_loved: [
      { loved_user_id: 'u1', loved_vendor_id: 'v1', hearted: true },
      { loved_user_id: 'u1', loved_vendor_id: 'v2', hearted: false },
      { loved_user_id: 'u2', loved_vendor_id: 'v9', hearted: true },
    ],
    user_diamonds: [{ user_id: 'u1', vendor_id: 'v7', category: 'Venue' }],
  });
  const p = createRemotePicks(db, 'u1');
  const start = await p.load();
  assert.deepEqual([...start.loved], ['v1']);
  assert.deepEqual(start.yes, { Venue: 'v7' });

  await p.setLove('v2', true);
  await p.setLove('v1', false);
  await p.setYes('v8', 'Venue', true);
  await p.setYes('v5', 'DJ', true);
  await p.setYes('v5', 'DJ', false);
  const now = await p.load();
  assert.deepEqual([...now.loved], ['v2']);
  assert.deepEqual(now.yes, { Venue: 'v8' });
  assert.equal(db.tables.user_diamonds.filter(d => d.user_id === 'u1').length, 1);
});

test('moving browser picks into an account keeps the account YES', async () => {
  const local = createLocalPicks(memoryStorage());
  await local.setLove('v1', true);
  await local.setYes('v2', 'Venue', true);
  await local.setYes('v3', 'DJ', true);
  const db = fakeSupabase({ user_diamonds: [{ user_id: 'u1', vendor_id: 'v9', category: 'Venue' }] });
  const remote = createRemotePicks(db, 'u1');
  const moved = await movePicksToAccount(local, remote);
  assert.deepEqual(moved, { loved: 1, yes: 1 });
  const after = await remote.load();
  assert.deepEqual([...after.loved], ['v1']);
  assert.deepEqual(after.yes, { Venue: 'v9', DJ: 'v3' });
  assert.equal(local.hasData(), false);
});

test('budget category for a vendor type matches the app budget list', () => {
  assert.equal(budgetCategoryFor('Venue'), 'Venue');
  assert.equal(budgetCategoryFor('Photographer'), 'Photography');
  assert.equal(budgetCategoryFor('Florist'), 'Flowers');
  assert.equal(budgetCategoryFor('DJ'), 'Music');
  assert.equal(budgetCategoryFor('Beauty'), 'Hair & Makeup');
  assert.equal(budgetCategoryFor('Invitations '), 'Invitations');
  assert.equal(budgetCategoryFor('Guest Experience'), 'Other');
});

test('booked: local keeps it, and unYES clears it', async () => {
  const storage = memoryStorage();
  const p = createLocalPicks(storage);
  await p.setYes('v1', 'Venue', true);
  await p.setBooked('v1', true);
  assert.deepEqual([...(await createLocalPicks(storage).load()).booked], ['v1']);
  await p.setYes('v1', 'Venue', false);
  assert.deepEqual([...(await p.load()).booked], []);
});

test('booked: remote updates the YES row and the vendor booking count like the app', async () => {
  const db = fakeSupabase({ user_diamonds: [{ user_id: 'u1', vendor_id: 'v1', category: 'Venue', is_booked: false }] });
  const p = createRemotePicks(db, 'u1');
  await p.setBooked('v1', true);
  assert.equal(db.tables.user_diamonds[0].is_booked, true);
  assert.deepEqual([...(await p.load()).booked], ['v1']);
  assert.deepEqual(db.rpcCalls, [['toggle_vendor_booking', { vendor_uuid: 'v1', increment: true }]]);
  await p.setBooked('v1', false);
  assert.deepEqual(db.rpcCalls[1], ['toggle_vendor_booking', { vendor_uuid: 'v1', increment: false }]);
});

test('moving picks carries booked YES vendors', async () => {
  const local = createLocalPicks(memoryStorage());
  await local.setYes('v2', 'DJ', true);
  await local.setBooked('v2', true);
  const db = fakeSupabase({});
  await movePicksToAccount(local, createRemotePicks(db, 'u1'));
  assert.equal(db.tables.user_diamonds[0].is_booked, true);
});
