// Run with: npm test   (node's built-in test runner, no dependencies)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as L from '../../web/js/plan-logic.js';

const now = new Date(2026, 9, 27); // Oct 27, 2026 (local)

test('daysBetween ignores time of day', () => {
  assert.equal(L.daysBetween(new Date(2026, 9, 27, 23, 59), new Date(2026, 9, 28, 0, 1)), 1);
  assert.equal(L.daysBetween(now, new Date(2027, 5, 12)), 228);
});

test('countdownLabel', () => {
  assert.equal(L.countdownLabel(null), 'Set your wedding date');
  assert.equal(L.countdownLabel(-3), 'Just married');
  assert.equal(L.countdownLabel(0), 'Today is the day');
  assert.equal(L.countdownLabel(1), '1 day to go');
  assert.equal(L.countdownLabel(229), '229 days to go');
});

test('dates parse YYYY-MM-DD as a local calendar day', () => {
  const d = L.parseDate('2027-06-12');
  assert.equal(d.getFullYear(), 2027);
  assert.equal(d.getMonth(), 5);
  assert.equal(d.getDate(), 12);
  assert.equal(L.parseDate(''), null);
  assert.equal(L.parseDate(null), null);
  assert.equal(L.longDate(d), 'Saturday, June 12, 2027');
  assert.equal(L.shortDate(d), 'Jun 12, 2027');
  assert.equal(L.isoDate(d), '2027-06-12');
});

test('formatMoney uses whole dollars with commas', () => {
  assert.equal(L.formatMoney(25000), '$25,000');
  assert.equal(L.formatMoney(999.6), '$1,000');
  assert.equal(L.formatMoney(0), '$0');
  assert.equal(L.formatMoney(-1234), '-$1,234');
  assert.equal(L.formatMoney(1234567), '$1,234,567');
});

test('isPastDue only for open tasks before today', () => {
  assert.equal(L.isPastDue({ due_date: '2026-10-26' }, now), true);
  assert.equal(L.isPastDue({ due_date: '2026-10-27' }, now), false);
  assert.equal(L.isPastDue({ due_date: '2026-10-26', is_completed: true }, now), false);
  assert.equal(L.isPastDue({}, now), false);
});

test('groupChecklist timeline order: past due, months, no date, done', () => {
  const items = [
    { id: 'a', due_date: '2027-08-01' },
    { id: 'b', due_date: '2026-10-01' },
    { id: 'c', due_date: '2026-10-30' },
    { id: 'd' },
    { id: 'e', due_date: '2026-11-15', is_completed: true },
    { id: 'f', due_date: '2026-11-15' },
    { id: 'g', due_date: '2027-01-02' },
    { id: 'h', due_date: '2027-03-02' },
    { id: 'i', due_date: '2027-11-02' },
  ];
  const groups = L.groupChecklist(items, 'timeline', now);
  assert.deepEqual(groups.map(g => g.label), [
    'Past due', 'This month', 'Next month', 'In 2–3 months', 'In 4–6 months', 'In 7–12 months', 'A year or more', 'No due date', 'Done',
  ]);
  assert.deepEqual(groups.map(g => g.items.map(i => i.id).join('')), ['b', 'c', 'f', 'g', 'h', 'a', 'i', 'd', 'e']);
});

test('groupChecklist category view is alphabetical with Other last, sorted by due date', () => {
  const items = [
    { id: '1', category: 'Venue', due_date: '2027-02-01' },
    { id: '2', category: '', due_date: '2027-01-01' },
    { id: '3', category: 'attire' },
    { id: '4', category: 'Venue', due_date: '2027-01-01' },
  ];
  const groups = L.groupChecklist(items, 'category', now);
  assert.deepEqual(groups.map(g => g.label), ['attire', 'Venue', 'Other']);
  assert.deepEqual(groups[1].items.map(i => i.id), ['4', '1']);
  assert.equal(groups[1].doneCount, 0);
});

test('buildChecklist counts back from the wedding and trims category names', () => {
  const templates = [
    { id: 't1', title: 'Book venue', category: 'Venue', months_before: 12, display_order: 1, description: 'Tour three' },
    { id: 't2', title: 'Order invites', category: 'Invitations', months_before: 4, display_order: 2 },
    { id: 't3', title: 'Pick DJ', category: 'DJ', months_before: 6, display_order: 3 },
    { id: 't4', title: 'Final payments', category: 'Wedding Planning', months_before: 0, display_order: 4 },
  ];
  const wedding = new Date(2027, 5, 12);
  const items = L.buildChecklist(templates, wedding, ['Venue', 'Invitations ', 'Wedding Planning'], now);
  assert.deepEqual(items.map(i => i.title), ['Book venue', 'Order invites', 'Final payments']);
  // 12 months * 30 days before Jun 12 2027 is Jun 17 2026, already passed, so it is due today.
  assert.equal(items[0].due_date, '2026-10-27');
  assert.equal(items[1].due_date, '2027-02-12'); // 120 days before
  assert.equal(items[2].due_date, '2027-06-12');
  assert.equal(items[0].template_id, 't1');
  assert.equal(items[0].description, 'Tour three');
  assert.equal(items[1].description, '');
  assert.equal(items[0].is_completed, false);
  assert.deepEqual(items.map(i => i.display_order), [0, 1, 2]);
});

test('budgetSummary', () => {
  const s = L.budgetSummary(10000, [
    { estimated_cost: 6000, actual_cost: 5000 },
    { estimated_cost: 3000, actual_cost: null },
    { estimated_cost: '2000', actual_cost: 6000 },
  ]);
  assert.equal(s.planned, 11000);
  assert.equal(s.spent, 11000);
  assert.equal(s.remaining, -1000);
  assert.equal(s.isOverBudget, true);
  assert.equal(s.spentFraction, 1);
  const empty = L.budgetSummary(0, []);
  assert.equal(empty.spentFraction, 0);
  assert.equal(empty.isOverBudget, false);
});

test('budget items group by category in first-seen order', () => {
  const groups = L.groupBudget([
    { id: 1, category: 'Venue' }, { id: 2, category: null }, { id: 3, category: 'Venue' },
  ]);
  assert.deepEqual(groups.map(g => [g.label, g.items.length]), [['Venue', 2], ['Other', 1]]);
});

test('isYesVendorItem', () => {
  const yes = { Venue: 'v1' };
  assert.equal(L.isYesVendorItem({ vendor_id: 'v1' }, yes), true);
  assert.equal(L.isYesVendorItem({ vendor_id: 'v2' }, yes), false);
  assert.equal(L.isYesVendorItem({ vendor_id: '' }, yes), false);
  assert.equal(L.isYesVendorItem({}, yes), false);
});

test('rsvpLabel', () => {
  assert.equal(L.rsvpLabel('accepted'), 'Attending');
  assert.equal(L.rsvpLabel('declined'), 'Not attending');
  assert.equal(L.rsvpLabel('invited'), 'Waiting');
  assert.equal(L.rsvpLabel('maybe'), 'Maybe');
  assert.equal(L.rsvpLabel(null), 'Not sent');
});

test('guest headcount and status counts include plus ones', () => {
  const guests = [
    { rsvp_status: 'accepted', plus_one_count: 1 },
    { rsvp_status: 'declined' },
    { plus_one_count: 2 },
  ];
  assert.equal(L.headcount(guests), 6);
  assert.deepEqual(L.statusCounts(guests), { not_sent: 3, invited: 0, accepted: 2, declined: 1, maybe: 0 });
});

test('filterGuests by name, status and group', () => {
  const guests = [
    { id: 1, first_name: 'Ana', last_name: 'Lee', rsvp_status: 'accepted', group_name: 'Bride' },
    { id: 2, first_name: 'Ben', last_name: 'Ortiz', group_name: 'Groom' },
    { id: 3, first_name: 'Cara', last_name: 'Leeds', rsvp_status: 'accepted', group_name: 'Groom' },
  ];
  assert.deepEqual(L.filterGuests(guests, { query: 'lee' }).map(g => g.id), [1, 3]);
  assert.deepEqual(L.filterGuests(guests, { status: 'not_sent' }).map(g => g.id), [2]);
  assert.deepEqual(L.filterGuests(guests, { status: 'accepted', group: 'Groom' }).map(g => g.id), [3]);
  assert.deepEqual(L.guestGroups(guests), ['Bride', 'Groom']);
});

test('guestsToCsv quotes fields and keeps the app export columns', () => {
  const csv = L.guestsToCsv([{ first_name: 'Ana', last_name: 'Lee, Jr.', notes: 'Says "hi"', plus_one_count: 1, rsvp_status: 'accepted' }]);
  const [head, row] = csv.trim().split('\r\n');
  assert.equal(head, 'First Name,Last Name,Email,Phone,Address,Group,RSVP,Meal Preference,Dietary Restrictions,Additional Guests,Notes');
  assert.equal(row, 'Ana,"Lee, Jr.",,,,,Attending,,,1,"Says ""hi"""');
});

test('guestsToCsv neutralizes spreadsheet formulas', () => {
  const csv = L.guestsToCsv([{ first_name: '=HYPERLINK("x")' }]);
  assert.match(csv.split('\r\n')[1], /^"'=HYPERLINK\(""x""\)"/);
});

test('mealInfo lists guests with meal or dietary notes', () => {
  const info = L.mealInfo([
    { first_name: 'Ana', meal_preference: 'Fish' },
    { first_name: 'Ben' },
    { first_name: 'Cy', dietary_restrictions: ' Vegan ' },
  ]);
  assert.deepEqual(info.map(i => [i.name, i.meal, i.diet]), [['Ana', 'Fish', ''], ['Cy', '', 'Vegan']]);
});

test('parseMoney accepts what people type', () => {
  assert.equal(L.parseMoney('$3,200'), 3200);
  assert.equal(L.parseMoney(' 1500.50 '), 1500.5);
  assert.equal(L.parseMoney(''), null);
  assert.equal(L.parseMoney('abc'), null);
});
