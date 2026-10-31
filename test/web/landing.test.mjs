import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const html = await readFile(new URL('../../web/landing.html', import.meta.url), 'utf8');
const head = /<head>([\s\S]*?)<\/head>/.exec(html)[1];
const meta = attr => new RegExp(`<meta (?:property|name)="${attr}" content="([^"]*)"`).exec(head)?.[1];

test('Begin Planning takes couples to Find Vendors', () => {
  const button = /<a class="btn btn-solid" href="([^"]+)">Begin Planning/.exec(html);
  assert.ok(button, 'Begin Planning button is on the page');
  assert.equal(button[1], '/vendors/');
});

test('shared links preview easiYESt, not other wedding sites', () => {
  assert.doesNotMatch(head, /The Knot|Zola|WeddingWire/);
  assert.equal(/<title>(.*?)<\/title>/.exec(head)[1], 'easiYESt – Utah Wedding Vendors &amp; Free Planning');
  for (const key of ['og:title', 'twitter:title']) {
    assert.equal(meta(key), 'easiYESt – Utah Wedding Vendors &amp; Free Planning', key);
  }
  for (const key of ['og:description', 'twitter:description']) {
    assert.equal(meta(key), 'Find loved, local Utah wedding vendors, and plan for free with a checklist, budget and guest list.', key);
  }
});

test('shared links show the collage, not one vendor\'s photo', () => {
  for (const key of ['og:image', 'twitter:image']) {
    assert.equal(meta(key), 'https://www.easiyest.com/images/share-collage.jpg', key);
  }
  assert.equal(meta('og:image:width'), '1200');
  assert.equal(meta('og:image:height'), '630');
});

/** Width and height from a JPEG's start-of-frame marker. */
function jpegSize(buf) {
  for (let i = 2; i < buf.length;) {
    const marker = buf[i + 1];
    const len = buf.readUInt16BE(i + 2);
    if (marker >= 0xC0 && marker <= 0xC2) return { height: buf.readUInt16BE(i + 5), width: buf.readUInt16BE(i + 7) };
    i += 2 + len;
  }
  return null;
}

test('the collage is the size link previews expect, and small enough to load fast', async () => {
  const buf = await readFile(new URL('../../web/images/share-collage.jpg', import.meta.url));
  assert.deepEqual(jpegSize(buf), { width: 1200, height: 630 });
  assert.ok(buf.length < 300_000, `${buf.length} bytes`);
});
