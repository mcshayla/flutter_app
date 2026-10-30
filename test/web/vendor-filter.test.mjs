import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as F from '../../web/js/vendor-filter.js';

const barn = { id: 'a', state: ['Utah'], county: ['Utah County'], f: { venue_type: ['barn'], venue_amenities: ['parking', 'bridal_suite'] }, price: 3200, cmin: 50, cmax: 250 };
const garden = { id: 'b', state: ['Utah'], county: ['Salt Lake County', 'Davis County'], f: { venue_type: ['garden'] }, price: 8000, cmin: null, cmax: 120 };
const anywhere = { id: 'c', state: ['Any'], county: ['Any'], f: {}, price: null, cmin: null, cmax: null };
const all = [barn, garden, anywhere];
const ids = list => list.map(v => v.id);

test('no filters: everyone shows', () => {
  assert.deepEqual(ids(F.filterVendors(all, F.emptySelection())), ['a', 'b', 'c']);
  assert.equal(F.isEmpty(F.emptySelection()), true);
});

test('area: a county matches vendors who serve it, and "Any" serves everywhere', () => {
  assert.deepEqual(ids(F.filterVendors(all, { ...F.emptySelection(), county: 'Davis County' })), ['b', 'c']);
  assert.deepEqual(ids(F.filterVendors(all, { ...F.emptySelection(), state: 'Utah' })), ['a', 'b', 'c']);
});

// Roughly Utah County, and pins inside and outside it.
const utahCounty = { south: 39.8, west: -112.2, north: 40.5, east: -111.4 };
const provo = { id: 'p', lat: 40.23, lng: -111.66, f: {} };
const logan = { id: 'l', lat: 41.73, lng: -111.83, f: {} };
const unpinned = { id: 'u', lat: null, lng: null, f: {} };

test('map area: only vendors pinned inside the map show', () => {
  assert.equal(F.matchesMapArea(provo, utahCounty), true);
  assert.equal(F.matchesMapArea(logan, utahCounty), false);
  assert.equal(F.matchesMapArea(unpinned, utahCounty), false);
  assert.equal(F.matchesMapArea(unpinned, null), true, 'no map open: no limit');
  assert.deepEqual(ids(F.filterVendors([provo, logan, unpinned], { ...F.emptySelection(), mapArea: utahCounty })), ['p']);
});

test('map area combines with the other filters but is not counted as one', () => {
  const cheap = { ...provo, id: 'c', price: 1000 };
  const pricey = { ...provo, id: 'x', price: 9000 };
  const sel = { ...F.emptySelection(), price: { min: 0, max: 5000 }, mapArea: utahCounty };
  assert.deepEqual(ids(F.filterVendors([cheap, pricey, logan], sel)), ['c']);
  assert.equal(F.activeCount(sel), 1);
});

test('map pins: vendors with both coordinates', () => {
  assert.deepEqual(ids(F.mapPins([provo, logan, unpinned, { id: 'h', lat: 40.1, lng: null }])), ['p', 'l']);
});

test('map pins: vendors in the same spot share one pin', () => {
  const orem = { lat: 40.29816, lng: -111.69443, f: {} };
  const spots = F.pinSpots([{ ...orem, id: 'a' }, provo, { ...orem, id: 'b' }]);
  assert.deepEqual(spots.map(s => [s.lat, s.lng, s.ids]), [[40.29816, -111.69443, ['a', 'b']], [40.23, -111.66, ['p']]]);
});

test('area: a vendor with no area listed is left out once an area is chosen', () => {
  const blank = { id: 'd', state: null, county: null, f: {} };
  assert.deepEqual(ids(F.filterVendors([blank], { ...F.emptySelection(), county: 'Utah County' })), []);
});

test('area choices: sorted, without "Any", counties narrowed by state', () => {
  const nevada = { id: 'e', state: ['Nevada'], county: ['Clark County'], f: {} };
  assert.deepEqual(F.availableStates([...all, nevada]), ['Nevada', 'Utah']);
  assert.deepEqual(F.availableCounties([...all, nevada], null), ['Clark County', 'Davis County', 'Salt Lake County', 'Utah County']);
  assert.deepEqual(F.availableCounties([...all, nevada], 'Utah'), ['Davis County', 'Salt Lake County', 'Utah County']);
});

test('questions: any of the picks within one question, every question must match', () => {
  const s = q => ({ ...F.emptySelection(), tags: q });
  assert.deepEqual(ids(F.filterVendors(all, s({ venue_type: ['barn', 'garden'] }))), ['a', 'b']);
  assert.deepEqual(ids(F.filterVendors(all, s({ venue_type: ['barn', 'garden'], venue_amenities: ['parking'] }))), ['a']);
});

test('questions: vendors who have not answered are left out, not guessed', () => {
  assert.deepEqual(ids(F.filterVendors(all, { ...F.emptySelection(), tags: { venue_amenities: ['parking'] } })), ['a']);
});

test('questions: a single answer saved as text still counts', () => {
  const v = { id: 'x', f: { catering: 'In-house only' } };
  assert.deepEqual(ids(F.filterVendors([v], { ...F.emptySelection(), tags: { catering: ['In-house only'] } })), ['x']);
});

test('price: starting price inside the band; no price listed is left out', () => {
  assert.deepEqual(ids(F.filterVendors(all, { ...F.emptySelection(), price: { min: 0, max: 5000 } })), ['a']);
  assert.deepEqual(ids(F.filterVendors(all, { ...F.emptySelection(), price: { min: 5000, max: 20000 } })), ['b']);
});

test('guests: the venue holds that many (open ended when one side is blank)', () => {
  assert.deepEqual(ids(F.filterVendors(all, { ...F.emptySelection(), guests: 200 })), ['a']);
  assert.deepEqual(ids(F.filterVendors(all, { ...F.emptySelection(), guests: 100 })), ['a', 'b']);
  assert.deepEqual(ids(F.filterVendors(all, { ...F.emptySelection(), guests: 20 })), ['b']);
});

test('filter questions for a type: chips with their options and sections, range filters kept apart', () => {
  const defs = [
    { category_name: 'Venue', filter_key: 'venue_type', filter_label: 'Venue Type', filter_type: 'chips', display_order: 1 },
    { category_name: 'Venue', filter_key: 'catering', filter_label: 'Catering', filter_type: 'chips', options: ['In-house only', 'BYO caterer'], display_order: 2 },
    { category_name: 'Venue', filter_key: 'starting_price', filter_label: 'Price', filter_type: 'range', range_min: 0, range_max: 20000, range_step: 500, range_unit: '$', display_order: 3 },
    { category_name: 'Venue', filter_key: 'guest_capacity_range', filter_label: 'Guests', filter_type: 'range', range_min: 0, range_max: 1000, range_unit: 'guests', display_order: 4 },
    { category_name: 'DJ', filter_key: 'dj_services', filter_label: 'Services', filter_type: 'chips', display_order: 1 },
  ];
  const options = [
    { filter_key: 'venue_type', option_value: 'barn', option_label: 'Barns & Farms', option_group: 'Rustic', display_order: 2 },
    { filter_key: 'venue_type', option_value: 'garden', option_label: 'Gardens', option_group: 'Outdoor', display_order: 1 },
    { filter_key: 'dj_services', option_value: 'mc', option_label: 'MC services', display_order: 1 },
  ];
  const q = F.filtersFor('Venue', defs, options);
  assert.deepEqual(q.questions.map(x => x.key), ['venue_type', 'catering']);
  assert.deepEqual(q.questions[0].sections, [
    { title: 'Outdoor', options: [{ value: 'garden', label: 'Gardens' }] },
    { title: 'Rustic', options: [{ value: 'barn', label: 'Barns & Farms' }] },
  ]);
  assert.deepEqual(q.questions[1].sections, [{ title: null, options: [{ value: 'In-house only', label: 'In-house only' }, { value: 'BYO caterer', label: 'BYO caterer' }] }]);
  assert.deepEqual(q.price, { label: 'Price', min: 0, max: 20000, step: 500 });
  assert.equal(q.guests, true);
  const dj = F.filtersFor('DJ ', defs, options);
  assert.deepEqual(dj.questions.map(x => x.key), ['dj_services']);
  assert.equal(dj.price, null);
  assert.equal(dj.guests, false);
});

test('questions with no options are not shown', () => {
  const q = F.filtersFor('Venue', [{ category_name: 'Venue', filter_key: 'empty', filter_type: 'chips' }], []);
  assert.deepEqual(q.questions, []);
});

test('price steps for the dropdowns: from the low end to the high end, with a top "and up"', () => {
  assert.deepEqual(F.priceSteps({ min: 0, max: 5000, step: 1000 }), [0, 1000, 2000, 3000, 4000, 5000]);
  assert.equal(F.priceSteps({ min: 0, max: 20000, step: 50 }).length <= 12, true);
});

test('the selection lives in the link so a filtered list can be shared', () => {
  const sel = { ...F.emptySelection(), county: 'Utah County', tags: { venue_type: ['barn', 'garden'] }, price: { min: 0, max: 5000 }, guests: 150 };
  const qs = F.toQuery(sel);
  assert.equal(qs, 'county=Utah+County&price=0-5000&guests=150&venue_type=barn%2Cgarden');
  assert.deepEqual(F.fromQuery(qs, ['venue_type']), sel);
  assert.deepEqual(F.fromQuery('nonsense=1&guests=abc', ['venue_type']), F.emptySelection());
});

test('active filter count for the Filters button', () => {
  assert.equal(F.activeCount({ ...F.emptySelection(), county: 'Utah County', tags: { a: ['1', '2'], b: [] }, guests: 10 }), 4);
});
