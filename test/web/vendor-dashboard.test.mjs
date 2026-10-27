import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as V from '../../web/js/vendor-logic.js';

const text = html => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

test('storage folder name matches the app (sanitizeStorageName)', () => {
  assert.equal(V.storageFolder("Sally's Scoop & Co."), 'Sally_s Scoop _ Co_');
  assert.equal(V.storageFolder('  Bay and Bre  '), 'Bay and Bre');
});

test('social links: split by kind for the form, and back to one list', () => {
  const byKind = V.linksByKind(['https://www.instagram.com/a/', 'https://facebook.com/b', 'https://www.tiktok.com/@c', 'https://example.com/x']);
  assert.equal(byKind.instagram, 'https://www.instagram.com/a/');
  assert.equal(byKind.facebook, 'https://facebook.com/b');
  assert.equal(byKind.tiktok, 'https://www.tiktok.com/@c');
  assert.equal(byKind.other, 'https://example.com/x');
  assert.deepEqual(V.collectLinks({ instagram: ' https://instagram.com/a ', facebook: '', other: 'https://x.co, https://y.co' }),
    ['https://instagram.com/a', 'https://x.co', 'https://y.co']);
});

test('vendor payload from the form, same rules as the app', () => {
  const p = V.vendorPayload({
    vendor_name: '  Bloom  ', vendor_category: 'Florist', vendor_description: 'Hi', vendor_location: 'Provo',
    address: '', vendor_price: '$900', guest_capacity: '', starting_price: '900', capacity_min: '', capacity_max: 'abc',
    contact_email: 'a@b.co', contact_phone: '', website_url: 'bloom.com', style_keywords: 'Boho, Garden',
    links: { instagram: 'https://instagram.com/bloom' },
    states: ['Idaho'], counties: ['Utah County'],
    filters: { style: ['boho'], service_type: [] },
  });
  assert.equal(p.vendor_name, 'Bloom');
  assert.equal(p.starting_price, 900);
  assert.equal(p.capacity_min, null);
  assert.equal(p.capacity_max, null);
  assert.equal(p.website_url, 'https://bloom.com');
  assert.deepEqual(p.social_media_links, ['https://instagram.com/bloom']);
  assert.deepEqual(p.vendor_state, ['Idaho']);
  assert.deepEqual(p.vendor_county, []); // counties only when serving Utah
  assert.deepEqual(p.filter_values, { style: ['boho'] });
  assert.equal('vendor_user_id' in p, false);
  const utah = V.vendorPayload({ vendor_name: 'X', states: ['Utah'], counties: ['Utah County'], filters: {} });
  assert.deepEqual(utah.vendor_county, ['Utah County']);
});

test('filter groups for a category: chips with options, ranges mapped to columns', () => {
  const groups = V.filterGroups('Venue', [
    { category_name: 'Venue', filter_key: 'venue_type', filter_label: 'Venue Type', filter_type: 'chips', multi_select: true, display_order: 1 },
    { category_name: 'Venue', filter_key: 'catering', filter_label: 'Catering', filter_type: 'chips', options: ['In-house', 'BYO'], display_order: 2 },
    { category_name: 'Venue', filter_key: 'starting_price', filter_label: 'Starting Price', filter_type: 'range', display_order: 3 },
    { category_name: 'DJ', filter_key: 'genre', filter_label: 'Genre', filter_type: 'chips', display_order: 1 },
  ], [
    { filter_key: 'venue_type', option_value: 'barn', option_label: 'Barns', display_order: 2 },
    { filter_key: 'venue_type', option_value: 'garden', option_label: 'Gardens', display_order: 1 },
  ]);
  assert.deepEqual(groups.map(g => g.key), ['venue_type', 'catering']);
  assert.deepEqual(groups[0].options, [{ value: 'garden', label: 'Gardens' }, { value: 'barn', label: 'Barns' }]);
  assert.deepEqual(groups[1].options, [{ value: 'In-house', label: 'In-house' }, { value: 'BYO', label: 'BYO' }]);
});

test('profile strength lists what is missing', () => {
  const s = V.profileStrength({ vendor_name: 'Bloom', vendor_description: 'x'.repeat(200), image_url: ['a', 'b'], vendor_price: '', starting_price: null, contact_email: 'a@b.co', website_url: '', style_keywords: 'Boho', filter_values: {} }, 2);
  assert.equal(s.done, 4);
  assert.equal(s.total, 8);
  assert.deepEqual(s.missing.map(m => m.label), ['Add at least 5 photos', 'Add a starting price', 'Add your website or Instagram', 'Answer your search filters']);
  const none = V.profileStrength({ vendor_name: 'X', image_url: [], filter_values: {} }, 0);
  assert.ok(!none.missing.some(m => m.label.includes('filters')));
});

test('listing status', () => {
  assert.deepEqual(V.listingStatus({ is_listed: true }), { live: true, label: 'Live on easiYESt' });
  assert.deepEqual(V.listingStatus({ is_listed: false }), { live: false, label: 'Waiting for review' });
});

test('dashboard renders stats, status, strength and actions', () => {
  const html = V.renderDashboard({
    vendor: { vendor_id: 'v1', vendor_name: 'Bloom & <Co>', vendor_category: 'Florist', is_listed: true, image_url: ['https://x/a.jpg'], filter_values: {} },
    stats: { views: 120, websiteClicks: 14, hearts: 9, yes: 3, booked: 1 },
    pageUrl: '/vendors/florists/bloom-and-co/',
    filterCount: 0,
  });
  const t = text(html);
  assert.match(html, /Bloom &amp; &lt;Co&gt;/);
  assert.match(t, /120 Profile views 14 Website clicks 9 Couples loved you 3 Said YES 1 Booked/);
  assert.match(t, /Live on easiYESt/);
  assert.match(html, /href="\/vendors\/florists\/bloom-and-co\/"/);
  assert.match(html, /data-action="edit"/);
  assert.match(t, /Profile strength/);
});

test('no-listing screen offers claim and create', () => {
  const html = V.renderStart();
  assert.match(html, /data-action="claim"/);
  assert.match(html, /data-action="create"/);
});

test('claim search results list unclaimed vendors safely', () => {
  const html = V.renderClaimResults([{ vendor_id: 'v9', vendor_name: '<b>Barn</b>', vendor_category: 'Venue', vendor_location: 'Lehi', contact_email: 'own@barn.com' }]);
  assert.match(html, /&lt;b&gt;Barn&lt;\/b&gt;/);
  assert.match(html, /data-action="claim-this" data-id="v9"/);
  assert.match(text(html), /We'll email a code to o\*\*@barn\.com/);
  assert.match(text(V.renderClaimResults([])), /No unclaimed listings match/);
  assert.match(V.renderClaimResults([{ vendor_id: 'v8', vendor_name: 'NoMail', contact_email: '' }]), /disabled/);
});

test('maskEmail', () => {
  assert.equal(V.maskEmail('owner@barn.com'), 'o****@barn.com');
  assert.equal(V.maskEmail('ab@x.co'), 'a*@x.co');
  assert.equal(V.maskEmail(''), '');
});
