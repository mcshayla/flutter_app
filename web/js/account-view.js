// HTML for the couple's account pages: Loved (with Compare) and the YES
// list. Pure: picks + /vendors/index.json + profile in, HTML out, tested in
// test/web/account.test.mjs. account-app.js puts it on the page.

import { esc } from './plan-view.js';
import { parseDate, daysBetween, countdownLabel, longDate } from './plan-logic.js';

const ICON = {
  love: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="M12 21s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 11c0 5.5-7 10-7 10z"/></svg>',
  yes: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="M6 3h12l3 6-9 12L3 9z"/><path d="M3 9h18"/></svg>',
  pin: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="M12 21s-6-5.5-6-11a6 6 0 0 1 12 0c0 5.5-6 11-6 11z"/><circle cx="12" cy="10" r="2.2"/></svg>',
  check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
  arrow: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M4 12h16M14 6l6 6-6 6"/></svg>',
};

// ---------------------------------------------------------------- data

const categoryOf = (index, name) => index.categories.find(c => c.name === name) ?? { name, plural: name, slug: '' };

/** Loved vendors grouped by vendor type, in the site's type order. */
export function lovedGroups(loved, index) {
  const groups = [];
  for (const cat of index.categories) {
    const vendors = [...loved].map(id => index.vendors[id]).filter(v => v && v.category === cat.name);
    if (vendors.length) groups.push({ category: cat, vendors });
  }
  return groups;
}

export function yesSummary(yes, booked, index) {
  const chosen = index.categories
    .filter(c => yes[c.name] && index.vendors[yes[c.name]])
    .map(c => ({ category: c, vendor: index.vendors[yes[c.name]], booked: booked.has(yes[c.name]) }));
  const taken = new Set(chosen.map(c => c.category.name));
  return { chosen, open: index.categories.filter(c => !taken.has(c.name)), bookedCount: chosen.filter(c => c.booked).length };
}

export function compareRows(vendors) {
  const dash = v => (v == null || v === '' ? '–' : String(v));
  return [
    { label: 'Location', values: vendors.map(v => dash(v.location)) },
    { label: 'Starting price', values: vendors.map(v => dash(v.price)) },
    { label: 'Style', values: vendors.map(v => dash((v.keywords ?? []).join(', '))) },
    { label: 'Rating', values: vendors.map(v => (v.rating ? `${v.rating} (${v.reviews} review${v.reviews === 1 ? '' : 's'})` : '–')) },
    { label: 'Email', values: vendors.map(v => dash(v.email)) },
    { label: 'Phone', values: vendors.map(v => dash(v.phone)) },
  ];
}

export function coupleTitle(profile) {
  const names = [profile?.partner_name_1, profile?.partner_name_2].map(n => String(n ?? '').trim()).filter(Boolean);
  return names.length ? names.join(' & ') : null;
}

// ---------------------------------------------------------------- pieces

const pickButton = (kind, v, on) =>
  `<button type="button" class="pick-icon" data-pick="${kind}" data-vendor-id="${esc(v.id)}" data-category="${esc(v.category)}" aria-pressed="${on}" aria-label="${kind === 'love' ? 'Love' : 'Say YES to'} ${esc(v.name)}">${ICON[kind]}</button>`;

const photo = v => (v.image
  ? `<img src="${esc(v.image)}" alt="" loading="lazy" decoding="async">`
  : `<div class="photo-placeholder" aria-hidden="true"><span>${esc(String(v.name).charAt(0).toUpperCase())}</span></div>`);

function card(v, { loved, yes }, compare) {
  const picked = compare?.picked.includes(v.id);
  return `<li class="vcard${picked ? ' is-picked' : ''}">
    <a class="vcard-link" href="${esc(v.url)}">
      <span class="vcard-photo">${photo(v)}</span>
      ${v.location ? `<span class="vcard-place">${ICON.pin}${esc(v.location)}</span>` : ''}
      <span class="vcard-name">${esc(v.name)}</span>
      ${v.price && v.price.length <= 24 ? `<span class="vcard-price">From ${esc(v.price)}</span>` : ''}
    </a>
    ${compare
      ? `<label class="compare-check"><input type="checkbox" data-compare-pick="${esc(v.id)}"${picked ? ' checked' : ''}${!picked && compare.picked.length >= 3 ? ' disabled' : ''}><span>Compare</span></label>`
      : `<div class="vcard-picks">${pickButton('love', v, loved.has(v.id))}${pickButton('yes', v, yes[v.category] === v.id)}</div>`}
  </li>`;
}

// ---------------------------------------------------------------- loved

export function renderLoved(picks, index, compare) {
  const groups = lovedGroups(picks.loved, index);
  const total = groups.reduce((n, g) => n + g.vendors.length, 0);
  const intro = `<section class="intro intro-tight"><div class="intro-inner">
    <span class="eyebrow">Your favorites</span>
    <h1>Loved <em>vendors</em></h1>
    ${total ? `<p class="note">${total} vendor${total === 1 ? '' : 's'} saved</p>` : ''}
  </div></section>`;

  if (!groups.length) {
    return `${intro}<section class="section"><div class="empty-state">
      <h2>Heart vendors to save them here</h2>
      <p>Tap the heart on any vendor and they'll wait for you here, ready to compare.</p>
      <a class="btn btn-plum" href="/vendors/">Find vendors ${ICON.arrow}</a>
    </div></section>`;
  }

  const sections = groups.map(({ category: cat, vendors }) => {
    const comparing = compare?.category === cat.name ? compare : null;
    const chosen = comparing ? vendors.filter(v => comparing.picked.includes(v.id)) : [];
    const table = chosen.length >= 2 ? `<div class="table-scroll"><table class="compare-table">
      <thead><tr><th scope="col"><span class="sr-only">Detail</span></th>${chosen.map(v => `<th scope="col"><a href="${esc(v.url)}">${esc(v.name)}</a></th>`).join('')}</tr></thead>
      <tbody>${compareRows(chosen).map(r => `<tr><th scope="row">${esc(r.label)}</th>${r.values.map(x => `<td>${esc(x)}</td>`).join('')}</tr>`).join('')}</tbody>
    </table></div>` : '';
    return `<section class="loved-group" aria-labelledby="g-${esc(cat.slug)}">
      <div class="loved-head">
        <h2 id="g-${esc(cat.slug)}">${esc(cat.plural)}</h2>
        <span class="loved-count">${vendors.length} loved</span>
        ${vendors.length >= 2 ? (comparing
          ? `<button type="button" class="btn btn-line btn-sm" data-action="compare-done">Done comparing</button>`
          : `<button type="button" class="btn btn-line btn-sm" data-action="compare" data-category="${esc(cat.name)}">Compare</button>`) : ''}
      </div>
      ${comparing ? `<p class="compare-hint">${chosen.length < 2 ? 'Pick two or three to compare side by side.' : `Comparing ${chosen.length}. You can pick up to three.`}</p>` : ''}
      ${table}
      <ul class="vlist">${vendors.map(v => card(v, picks, comparing)).join('')}</ul>
    </section>`;
  }).join('');

  return `${intro}<div class="loved-wrap">${sections}</div>`;
}

// ---------------------------------------------------------------- YES

export function renderYes(picks, index, profile, now) {
  const s = yesSummary(picks.yes, picks.booked ?? new Set(), index);
  const date = parseDate(profile?.wedding_date);
  const title = coupleTitle(profile);
  const when = date ? `${longDate(date)} · ${countdownLabel(daysBetween(now, date))}` : '';

  const intro = `<section class="intro intro-tight"><div class="intro-inner">
    ${when ? `<span class="eyebrow">${esc(when)}</span>` : '<span class="eyebrow">Your wedding team</span>'}
    <h1>${title ? esc(title) : 'Your YES <em>list</em>'}</h1>
    <p class="note">${s.chosen.length} of ${index.categories.length} chosen · ${s.bookedCount} booked</p>
    <button type="button" class="text-btn" data-action="edit-wedding">${title || date ? 'Edit wedding details' : 'Add your wedding details'}</button>
  </div></section>`;

  const chosen = s.chosen.length ? `<ul class="yes-list">${s.chosen.map(({ category: cat, vendor: v, booked }) => `<li class="yes-row${booked ? ' is-booked' : ''}">
      <a class="yes-photo" href="${esc(v.url)}" tabindex="-1" aria-hidden="true">${photo(v)}</a>
      <div class="yes-text">
        <span class="eyebrow">${ICON.yes}Your YES for ${esc(cat.name)}</span>
        <a class="yes-name" href="${esc(v.url)}">${esc(v.name)}</a>
        <span class="yes-meta">${esc([v.location, v.price && v.price.length <= 24 ? `From ${v.price}` : ''].filter(Boolean).join(' · '))}</span>
      </div>
      <div class="yes-actions">
        <button type="button" class="pick${booked ? '' : ''}" data-action="booked" data-vendor-id="${esc(v.id)}" aria-pressed="${booked}">${ICON.check}<span>${booked ? 'Booked' : 'Mark as booked'}</span></button>
        <button type="button" class="text-btn" data-add-budget data-budget-name="${esc(v.name)}" data-budget-amount="${v.amount ?? ''}" data-vendor-id="${esc(v.id)}" data-category="${esc(cat.name)}">Add to budget</button>
        <button type="button" class="text-btn is-quiet" data-pick="yes" data-vendor-id="${esc(v.id)}" data-category="${esc(cat.name)}" aria-pressed="true">Remove YES</button>
      </div>
    </li>`).join('')}</ul>`
    : `<div class="empty-state"><h2>No YES yet</h2><p>When you find the one, tap YES on their page and they'll show up here.</p></div>`;

  const open = s.open.length ? `<section class="still-open">
      <span class="eyebrow">Still to choose</span>
      <ul>${s.open.map(c => `<li><a href="/vendors/${esc(c.slug)}/">${esc(c.plural)}${ICON.arrow}</a></li>`).join('')}</ul>
    </section>` : '';

  return `${intro}<div class="yes-wrap">${chosen}${open}</div>`;
}
