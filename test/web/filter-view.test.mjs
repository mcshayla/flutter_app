import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as V from '../../web/js/filter-view.js';
import { emptySelection } from '../../web/js/vendor-filter.js';

const text = html => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
const fs = {
  questions: [{ key: 'venue_type', label: 'Venue Type', sections: [{ title: 'Outdoor', options: [{ value: 'garden', label: 'Gardens & "Parks"' }] }, { title: null, options: [{ value: 'barn', label: 'Barns' }] }] }],
  price: { label: 'Starting price', min: 0, max: 5000, step: 1000 },
  guests: true,
};

test('panel: area, price, guests and each question, with current picks checked', () => {
  const sel = { ...emptySelection(), county: 'Utah County', tags: { venue_type: ['barn'] }, price: { min: 0, max: 3000 }, guests: 120 };
  const html = V.renderPanel(fs, sel, { states: ['Utah'], counties: ['Davis County', 'Utah County'] });
  const t = text(html);
  assert.match(t, /Area/);
  assert.match(html, /<option value="Utah County" selected>/);
  assert.doesNotMatch(html, /name="state"/, 'one state only: no state picker');
  assert.match(html, /name="pmax"[^]*<option value="3000" selected>/);
  assert.match(html, /name="guests"[^>]*value="120"/);
  assert.match(t, /Venue Type/);
  assert.match(t, /Outdoor/);
  assert.match(html, /value="barn" checked/);
  assert.doesNotMatch(html, /value="garden" checked/);
  assert.match(html, /Gardens &amp; &quot;Parks&quot;/);
});

test('panel: state picker when vendors serve more than one state; no area when nobody lists one', () => {
  assert.match(V.renderPanel(fs, emptySelection(), { states: ['Idaho', 'Utah'], counties: [] }), /name="state"/);
  const none = V.renderPanel({ questions: [], price: null, guests: false }, emptySelection(), { states: [], counties: [] });
  assert.doesNotMatch(text(none), /Area|Starting price|Guests/);
});

test('panel: says plainly that only vendors who answered show for a question', () => {
  assert.match(text(V.renderPanel(fs, emptySelection(), { states: [], counties: [] })), /only vendors who answered/i);
});

test('toolbar: how many show, and how many filters are on', () => {
  const t = text(V.renderToolbar({ shown: 1, total: 4, active: 2, noun: ['venue', 'venues'] }));
  assert.match(t, /Showing 1 of 4 venues/);
  assert.match(t, /Filters 2/);
  assert.match(t, /Clear all/);
  const plain = text(V.renderToolbar({ shown: 4, total: 4, active: 0, noun: ['venue', 'venues'] }));
  assert.match(plain, /4 venues/);
  assert.doesNotMatch(plain, /Clear all/);
});

test('toolbar: a Map button when vendors have pins, pressed while the map is open', () => {
  const noun = ['venue', 'venues'];
  assert.doesNotMatch(V.renderToolbar({ shown: 4, total: 4, active: 0, noun }), /data-vf="map"/);
  assert.match(V.renderToolbar({ shown: 4, total: 4, active: 0, noun, hasMap: true }), /<button type="button" class="btn btn-line btn-sm vf-map" data-vf="map" aria-pressed="false">/);
  const open = V.renderToolbar({ shown: 2, total: 4, active: 0, noun, hasMap: true, mapOpen: true });
  assert.match(open, /aria-pressed="true"/);
  assert.match(text(open), /Showing 2 of 4 venues in the map area/);
});

test('map pin popup: name, place and a link to the vendor, escaped', () => {
  const html = V.renderPinPopup({ name: 'Barn & <Orchard>', url: '/vendors/venues/barn/', location: 'Santaquin', image: 'https://x/a.jpg' });
  assert.match(html, /<a class="pin-card" href="\/vendors\/venues\/barn\/">/);
  assert.match(html, /<img src="https:\/\/x\/a\.jpg" alt="">/);
  assert.match(html, /<b>Barn &amp; &lt;Orchard&gt;<\/b>/);
  assert.match(text(html), /Santaquin/);
  assert.doesNotMatch(V.renderPinPopup({ name: 'Quiet', url: '/q/', location: '', image: null }), /<img|<small>/);
});

test('a shared pin lists every vendor there', () => {
  const html = V.renderPinPopup([{ name: 'One', url: '/1/', location: 'Orem', image: null }, { name: 'Two', url: '/2/', location: 'Orem', image: null }]);
  assert.equal((html.match(/class="pin-card"/g) || []).length, 2);
  assert.match(html, /^<div class="pin-list">/);
});

test('nothing matches: say so and offer to clear', () => {
  assert.match(text(V.renderNone(['venue', 'venues'])), /No venues match these filters\. Clear filters/);
});

test('reading the form back into a selection', () => {
  const fd = new URLSearchParams('state=&county=Utah+County&pmin=&pmax=3000&guests=120&q:venue_type=barn&q:venue_type=garden');
  assert.deepEqual(V.readPanel(fd, fs), { state: null, county: 'Utah County', price: { min: 0, max: 3000 }, guests: 120, tags: { venue_type: ['barn', 'garden'] } });
  assert.deepEqual(V.readPanel(new URLSearchParams(''), fs), emptySelection());
});
