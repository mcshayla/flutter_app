import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as V from '../../web/js/plan-view.js';

const now = new Date(2026, 9, 27);
const text = html => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

test('esc escapes HTML in anything a person typed', () => {
  assert.equal(V.esc('<img src=x onerror="a">&\''), '&lt;img src=x onerror=&quot;a&quot;&gt;&amp;&#39;');
  assert.equal(V.esc(null), '');
});

test('countdown shows days to go and the long date', () => {
  const html = V.renderCountdown({ wedding_date: '2027-06-12' }, now);
  assert.match(text(html), /Saturday, June 12, 2027 228 days to go/);
  assert.match(html, /data-action="edit-date"/);
});

test('countdown asks for a date when there is none', () => {
  assert.match(text(V.renderCountdown({}, now)), /Your wedding Set your wedding date/);
});

test('empty checklist offers to generate one', () => {
  const html = V.renderChecklist({ items: [], view: 'timeline', collapsed: new Set(), now });
  assert.match(text(html), /Every task, in the right order/);
  assert.match(html, /data-action="generate"/);
  assert.match(html, /data-action="add-task"/);
});

test('checklist shows progress, groups, past due and done state', () => {
  const items = [
    { id: 'a', title: 'Book <venue>', category: 'Venue', due_date: '2026-10-01' },
    { id: 'b', title: 'Pick DJ', category: 'DJ', due_date: '2027-03-01', is_completed: true },
  ];
  const html = V.renderChecklist({ items, view: 'timeline', collapsed: new Set(), now });
  const t = text(html);
  assert.match(t, /1 of 2 tasks done/);
  assert.match(t, /Past due 0\/1/);
  assert.match(html, /Book &lt;venue&gt;/);
  assert.match(t, /Venue · Due Oct 1, 2026/);
  assert.match(html, /class="tag tag-late"/);
  assert.match(html, /data-action="toggle-task" data-id="b" aria-pressed="true"/);
  assert.match(html, /data-action="view" data-view="category" aria-pressed="false"/);
});

test('collapsed checklist groups hide their tasks', () => {
  const items = [{ id: 'b', title: 'Pick DJ', is_completed: true }];
  const html = V.renderChecklist({ items, view: 'timeline', collapsed: new Set(['Done']), now });
  assert.doesNotMatch(html, /Pick DJ/);
  assert.match(html, /data-action="toggle-group" data-group="Done" aria-expanded="false"/);
});

test('category view drops the category from each row', () => {
  const items = [{ id: 'a', title: 'Book venue', category: 'Venue', due_date: '2027-01-01' }];
  const t = text(V.renderChecklist({ items, view: 'category', collapsed: new Set(), now }));
  assert.match(t, /Venue 0\/1 Book venue Due Jan 1, 2027/);
});

test('guest list shows stats, rows and filters', () => {
  const guests = [
    { id: 'g1', first_name: 'Ana', last_name: 'Lee', rsvp_status: 'accepted', plus_one_count: 1, group_name: 'Bride', dietary_restrictions: 'Vegan' },
    { id: 'g2', first_name: 'Ben', group_name: 'Groom' },
  ];
  const html = V.renderGuests({ guests, query: '', status: '', group: '' });
  const t = text(html);
  assert.match(t, /3 Guests 2 Attending 0 Declined 0 Waiting/);
  assert.match(t, /Ana Lee \+1 Bride · Vegan Attending/);
  assert.match(html, /<option value="Groom">Groom<\/option>/);
  assert.match(html, /data-action="open-guest" data-id="g2"/);
});

test('guest list empty and no-match states', () => {
  assert.match(text(V.renderGuests({ guests: [], query: '', status: '', group: '' })), /Your guest list starts here/);
  const t = text(V.renderGuests({ guests: [{ id: 1, first_name: 'Ana' }], query: 'zed', status: '', group: '' }));
  assert.match(t, /No matches/);
});

test('budget shows total, bar, stats and YES vendors', () => {
  const html = V.renderBudget({
    total: 20000,
    items: [
      { id: 'b1', item_name: 'Barn', category: 'Venue', estimated_cost: 9000, actual_cost: 8000, is_paid: true, vendor_id: 'v1' },
      { id: 'b2', item_name: 'Cake', category: 'Cake', estimated_cost: 600 },
    ],
    yesByCategory: { Venue: 'v1' },
  });
  const t = text(html);
  assert.match(t, /\$20,000/);
  assert.match(t, /\$9,600 Planned \$8,000 Spent \$12,000 Remaining/);
  assert.match(t, /Barn Your YES · Paid \$8,000/);
  assert.match(t, /Venue \$8,000 of \$9,000/);
  assert.match(html, /style="width:48%"/); // planned 9,600 / 20,000
  assert.match(html, /style="width:40%"/); // spent
  assert.doesNotMatch(t, /Over budget/);
});

test('budget warns when over and asks for a total when unset', () => {
  const over = text(V.renderBudget({ total: 100, items: [{ id: 'x', item_name: 'X', actual_cost: 200 }], yesByCategory: {} }));
  assert.match(over, /Over budget/);
  const unset = V.renderBudget({ total: 0, items: [], yesByCategory: {} });
  assert.match(unset, /data-action="set-budget"[^>]*>Set your budget/);
  assert.match(text(unset), /Nothing added yet/);
});

test('save banner only for visitors who are not logged in', () => {
  assert.match(text(V.renderSaveBanner(null)), /saved in this browser only/);
  assert.equal(V.renderSaveBanner({ email: 'a@b.co' }), '');
});
