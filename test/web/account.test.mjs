import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as A from '../../web/js/account-view.js';

const index = {
  categories: [{ name: 'Venue', plural: 'Venues', slug: 'venues' }, { name: 'Photographer', plural: 'Photographers', slug: 'photographers' }, { name: 'DJ', plural: 'DJs', slug: 'djs' }],
  vendors: {
    v1: { id: 'v1', name: 'Memorial House', category: 'Venue', url: '/vendors/venues/memorial-house/', image: 'https://x/a.jpg', location: 'Salt Lake City', price: '$1,500', amount: 1500, keywords: ['Elegant'], email: 'a@b.co', phone: '801', rating: 5, reviews: 1 },
    v2: { id: 'v2', name: 'Grove <Station>', category: 'Venue', url: '/vendors/venues/grove-station/', image: null, location: 'Lehi', price: null, keywords: [] },
    v3: { id: 'v3', name: 'Bay and Bre', category: 'Photographer', url: '/vendors/photographers/bay-and-bre-photo/', image: 'https://x/c.jpg', location: 'Orem', price: '$3,000', amount: 3000, keywords: [] },
  },
};
const text = html => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

test('lovedGroups: by vendor type in site order, unknown ids dropped', () => {
  const groups = A.lovedGroups(new Set(['v3', 'v1', 'gone', 'v2']), index);
  assert.deepEqual(groups.map(g => [g.category.plural, g.vendors.map(v => v.id)]), [['Venues', ['v1', 'v2']], ['Photographers', ['v3']]]);
});

test('yesSummary: chosen vendors with booked state, and the types still open', () => {
  const s = A.yesSummary({ Venue: 'v1', DJ: 'missing' }, new Set(['v1']), index);
  assert.deepEqual(s.chosen.map(c => [c.category.name, c.vendor.id, c.booked]), [['Venue', 'v1', true]]);
  assert.deepEqual(s.open.map(c => c.name), ['Photographer', 'DJ']);
  assert.equal(s.bookedCount, 1);
});

test('compareRows: one row per detail, dashes for blanks', () => {
  const rows = A.compareRows([index.vendors.v1, index.vendors.v2]);
  assert.deepEqual(rows.map(r => r.label), ['Location', 'Starting price', 'Style', 'Rating', 'Email', 'Phone']);
  assert.deepEqual(rows[1].values, ['$1,500', '–']);
  assert.deepEqual(rows[3].values, ['5 (1 review)', '–']);
});

test('coupleTitle', () => {
  assert.equal(A.coupleTitle({ partner_name_1: 'Ana', partner_name_2: 'Ben' }), 'Ana & Ben');
  assert.equal(A.coupleTitle({ partner_name_1: 'Ana' }), 'Ana');
  assert.equal(A.coupleTitle({}), null);
});

test('renderLoved: groups, cards linking to vendor pages, compare for 2+, escaping', () => {
  const html = A.renderLoved({ loved: new Set(['v1', 'v2', 'v3']), yes: { Venue: 'v1' } }, index, null);
  const t = text(html);
  assert.match(t, /Venues 2 loved/);
  assert.match(html, /href="\/vendors\/venues\/memorial-house\/"/);
  assert.match(html, /Grove &lt;Station&gt;/);
  assert.match(html, /data-action="compare" data-category="Venue"/);
  assert.doesNotMatch(html, /data-action="compare" data-category="Photographer"/);
  assert.match(html, /data-pick="yes" data-vendor-id="v1" data-category="Venue" aria-pressed="true"/);
  assert.match(html, /data-pick="love" data-vendor-id="v3" data-category="Photographer" aria-pressed="true"/);
});

test('renderLoved: compare mode shows checkboxes and the table for picked vendors', () => {
  const html = A.renderLoved({ loved: new Set(['v1', 'v2']), yes: {} }, index, { category: 'Venue', picked: ['v1', 'v2'] });
  assert.match(html, /<input type="checkbox" data-compare-pick="v1" checked/);
  assert.match(html, /<table class="compare-table">/);
  assert.match(text(html), /Starting price \$1,500 –/);
});

test('renderLoved: empty state points to the vendors', () => {
  const html = A.renderLoved({ loved: new Set(), yes: {} }, index, null);
  assert.match(text(html), /Heart vendors to save them here/);
  assert.match(html, /href="\/vendors\/"/);
});

test('renderYes: couple header, chosen vendors with booked and budget actions, open types', () => {
  const html = A.renderYes({ loved: new Set(), yes: { Venue: 'v1' }, booked: new Set() }, index, { partner_name_1: 'Ana', partner_name_2: 'Ben', wedding_date: '2027-06-12' }, new Date(2026, 9, 27));
  const t = text(html);
  assert.match(t, /Ana &amp; Ben/);
  assert.match(t, /Saturday, June 12, 2027 · 228 days to go/);
  assert.match(t, /1 of 3 chosen · 0 booked/);
  assert.match(html, /data-action="booked" data-vendor-id="v1" aria-pressed="false"/);
  assert.match(html, /data-add-budget data-budget-name="Memorial House" data-budget-amount="1500" data-vendor-id="v1" data-category="Venue"/);
  assert.match(html, /href="\/vendors\/photographers\/"/);
});

test('renderYes: no profile asks for wedding details', () => {
  const t = text(A.renderYes({ loved: new Set(), yes: {}, booked: new Set() }, index, {}, new Date(2026, 9, 27)));
  assert.match(t, /Your YES list/);
  assert.match(t, /Add your wedding details/);
  assert.match(t, /0 of 3 chosen/);
});
