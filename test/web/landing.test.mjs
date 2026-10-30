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

test('shared links show a wedding photo, not the app icon', () => {
  for (const key of ['og:image', 'twitter:image']) {
    assert.equal(meta(key), 'https://www.easiyest.com/images/hero-memorial-house-garden.jpg', key);
  }
});
