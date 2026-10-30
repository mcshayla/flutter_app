import { test } from 'node:test';
import assert from 'node:assert/strict';
import { scrollTarget, atEnds } from '../../web/js/gallery.js';

// A strip 900px wide showing three 300px photos out of six (1800px in all).
const strip = scrollLeft => ({ scrollLeft, clientWidth: 900, scrollWidth: 1800, itemWidth: 300 });

test('next moves one photo along, back moves one photo back', () => {
  assert.equal(scrollTarget(strip(0), 1), 300);
  assert.equal(scrollTarget(strip(300), -1), 0);
});

test('a half-scrolled strip snaps to the next whole photo', () => {
  assert.equal(scrollTarget(strip(140), 1), 300);
  assert.equal(scrollTarget(strip(440), -1), 300);
});

test('never scrolls past either end', () => {
  assert.equal(scrollTarget(strip(900), 1), 900);
  assert.equal(scrollTarget(strip(0), -1), 0);
});

test('arrows know when the strip is at an end', () => {
  assert.deepEqual(atEnds(strip(0)), { start: true, end: false });
  assert.deepEqual(atEnds(strip(450)), { start: false, end: false });
  // Browsers report fractional scroll positions; a pixel short still counts.
  assert.deepEqual(atEnds(strip(899.4)), { start: false, end: true });
});
