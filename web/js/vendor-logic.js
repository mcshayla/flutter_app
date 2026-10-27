// The vendor side of the website (/vendor.html): pure logic and HTML for the
// dashboard, claiming a listing and the listing form. Mirrors the app's
// vendor_create.dart / vendor_edit_profile.dart / vendor_dashboard.dart.
// Tested in test/web/vendor-dashboard.test.mjs.

import { esc } from './plan-view.js';
import { formatMoney } from './plan-logic.js';
import { field } from './dialog.js';

export const US_STATES = ['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming', 'Any'];
export const UTAH_COUNTIES = ['Beaver County', 'Box Elder County', 'Cache County', 'Carbon County', 'Daggett County', 'Davis County', 'Duchesne County', 'Emery County', 'Garfield County', 'Grand County', 'Iron County', 'Juab County', 'Kane County', 'Millard County', 'Morgan County', 'Piute County', 'Rich County', 'Salt Lake County', 'San Juan County', 'Sanpete County', 'Sevier County', 'Summit County', 'Tooele County', 'Uintah County', 'Utah County', 'Wasatch County', 'Washington County', 'Wayne County', 'Weber County', 'Any'];
export const servesUtah = states => states.includes('Utah') || states.includes('Any');

/** Same folder name the app uses for a vendor's photos (image_utils.dart). */
export const storageFolder = name => String(name ?? '').replace(/[^a-zA-Z0-9 _-]/g, '_').trim();

// ---------------------------------------------------------------- links

const LINK_KINDS = [
  ['instagram', /instagram\.com/i], ['facebook', /facebook\.com|fb\.com/i], ['tiktok', /tiktok\.com/i],
  ['pinterest', /pinterest\./i], ['youtube', /youtube\.com|youtu\.be/i],
];
export const LINK_LABELS = { instagram: 'Instagram', facebook: 'Facebook', tiktok: 'TikTok', pinterest: 'Pinterest', youtube: 'YouTube', other: 'Other links' };

export function linksByKind(links) {
  const out = {};
  for (const raw of links ?? []) {
    const url = String(raw).trim();
    if (!url) continue;
    const kind = LINK_KINDS.find(([, re]) => re.test(url))?.[0] ?? 'other';
    out[kind] = out[kind] ? `${out[kind]}, ${url}` : url;
  }
  return out;
}

export function collectLinks(byKind) {
  return Object.keys(LINK_LABELS).flatMap(k => String(byKind?.[k] ?? '').split(',').map(s => s.trim()).filter(Boolean));
}

// ---------------------------------------------------------------- payload

const intOrNull = v => (/^\s*\d+\s*$/.test(String(v ?? '')) ? parseInt(v, 10) : null);
const withScheme = u => {
  const s = String(u ?? '').trim();
  return !s ? '' : /^https?:\/\//i.test(s) ? s : `https://${s}`;
};

/** The vendors-table row for the listing form, same rules as the app. */
export function vendorPayload(f) {
  const states = f.states ?? [];
  const filters = {};
  for (const [k, v] of Object.entries(f.filters ?? {})) if (v?.length) filters[k] = v; // skipped groups stay unanswered
  const t = k => String(f[k] ?? '').trim();
  return {
    vendor_name: t('vendor_name'),
    vendor_category: t('vendor_category'),
    vendor_description: t('vendor_description'),
    vendor_location: t('vendor_location'),
    address: t('address'),
    vendor_price: t('vendor_price'),
    guest_capacity: t('guest_capacity'),
    // null (not 0) when blank, so range filters skip rather than match at 0.
    starting_price: intOrNull(f.starting_price),
    capacity_min: intOrNull(f.capacity_min),
    capacity_max: intOrNull(f.capacity_max),
    contact_email: t('contact_email'),
    contact_phone: t('contact_phone'),
    website_url: withScheme(f.website_url),
    style_keywords: t('style_keywords'),
    social_media_links: collectLinks(f.links),
    vendor_state: states,
    vendor_county: servesUtah(states) ? (f.counties ?? []) : [],
    filter_values: filters,
  };
}

/** The category's choice filters with their options in display order. Ranges map to fixed columns. */
export function filterGroups(category, filters, options) {
  return filters
    .filter(f => String(f.category_name).trim() === String(category).trim() && f.filter_type !== 'range')
    .sort((a, b) => (a.display_order ?? 0) - (b.display_order ?? 0))
    .map(f => {
      const rows = options.filter(o => o.filter_key === f.filter_key).sort((a, b) => (a.display_order ?? 0) - (b.display_order ?? 0));
      const opts = rows.length
        ? rows.map(o => ({ value: String(o.option_value), label: String(o.option_label ?? o.option_value), group: o.option_group ?? null }))
        : (Array.isArray(f.options) ? f.options : []).map(o => ({ value: String(o), label: String(o) }));
      return { key: f.filter_key, label: f.filter_label ?? f.filter_key, multi: f.multi_select !== false, options: opts.map(({ group, ...o }) => (group ? { ...o, group } : o)) };
    });
}

// ---------------------------------------------------------------- dashboard

export function profileStrength(v, filterCount) {
  const items = [
    { label: 'Add your business name', done: Boolean(String(v.vendor_name ?? '').trim()) },
    { label: 'Write a description of at least 150 characters', done: String(v.vendor_description ?? '').trim().length >= 150 },
    { label: 'Add at least 5 photos', done: (v.image_url ?? []).length >= 5 },
    { label: 'Add a starting price', done: v.starting_price != null || Boolean(String(v.vendor_price ?? '').trim()) },
    { label: 'Add a contact email', done: Boolean(String(v.contact_email ?? '').trim()) },
    { label: 'Add your website or Instagram', done: Boolean(String(v.website_url ?? '').trim()) || (v.social_media_links ?? []).length > 0 },
    { label: 'Add style words', done: Boolean(String(v.style_keywords ?? '').trim()) },
  ];
  if (filterCount > 0) items.push({ label: 'Answer your search filters', done: Object.keys(v.filter_values ?? {}).length > 0 });
  return { done: items.filter(i => i.done).length, total: items.length, missing: items.filter(i => !i.done) };
}

export const listingStatus = v => (v.is_listed ? { live: true, label: 'Live on easiYESt' } : { live: false, label: 'Waiting for review' });

export function maskEmail(email) {
  const [user, domain] = String(email ?? '').split('@');
  if (!user || !domain) return '';
  return `${user[0]}${'*'.repeat(Math.max(1, user.length - 1))}@${domain}`;
}

const stat = (n, label) => `<div class="vstat"><b>${esc(Number(n || 0).toLocaleString('en-US'))}</b><small>${esc(label)}</small></div>`;

export function renderDashboard({ vendor: v, stats, pageUrl, filterCount }) {
  const status = listingStatus(v);
  const strength = profileStrength(v, filterCount);
  const pct = Math.round((strength.done / strength.total) * 100);
  const img = (v.image_url ?? [])[0];
  return `<section class="intro intro-tight"><div class="intro-inner">
      <span class="eyebrow">Vendor dashboard · ${esc(v.vendor_category ?? '')}</span>
      <h1>${esc(v.vendor_name)}</h1>
      <p class="status ${status.live ? 'is-live' : 'is-pending'}"><span aria-hidden="true"></span>${esc(status.label)}</p>
    </div></section>
    <div class="vdash">
      <div class="vstats">${stat(stats.views, 'Profile views')}${stat(stats.websiteClicks, 'Website clicks')}${stat(stats.hearts, 'Couples loved you')}${stat(stats.yes, 'Said YES')}${stat(stats.booked, 'Booked')}</div>
      <div class="vdash-grid">
        <section class="vcardbox">
          ${img ? `<img class="vdash-photo" src="${esc(img)}" alt="">` : ''}
          <span class="eyebrow">Your listing</span>
          <p class="muted">${status.live ? 'Couples can find you in search and on your page.' : 'We review new listings before they go live. You can keep editing while you wait.'}</p>
          <div class="card-actions">
            <button type="button" class="btn btn-plum btn-sm" data-action="edit">Edit listing</button>
            ${status.live && pageUrl ? `<a class="btn btn-line btn-sm" href="${esc(pageUrl)}">View your page</a>` : ''}
          </div>
        </section>
        <section class="vcardbox">
          <span class="eyebrow">Profile strength</span>
          <p class="strength"><b>${pct}%</b> <span>${strength.done} of ${strength.total} done</span></p>
          <div class="bar"><i style="width:${pct}%"></i></div>
          ${strength.missing.length ? `<ul class="todo">${strength.missing.map(m => `<li>${esc(m.label)}</li>`).join('')}</ul>` : '<p class="muted">Your profile is complete. Couples see everything they need.</p>'}
        </section>
      </div>
    </div>`;
}

// ---------------------------------------------------------------- start / claim

export function renderStart() {
  return `<section class="intro intro-tight"><div class="intro-inner">
      <span class="eyebrow">List your business</span>
      <h1>Welcome to <em>easiYESt</em></h1>
      <p>Is your business already on easiYESt? Claim it to manage it. Otherwise, create your listing.</p>
    </div></section>
    <div class="vstart">
      <button type="button" class="vchoice" data-action="claim"><span class="eyebrow">Already listed</span><b>Claim my listing</b><small>Find your business and confirm it's yours with a code sent to its email.</small></button>
      <button type="button" class="vchoice" data-action="create"><span class="eyebrow">New to easiYESt</span><b>Create my listing</b><small>Add your photos, prices and details. We review new listings before they go live.</small></button>
    </div>`;
}

export function renderClaimResults(results) {
  if (!results.length) return '<p class="muted claim-empty">No unclaimed listings match. Try another spelling, or create a new listing.</p>';
  return `<ul class="claim-results">${results.map(v => {
    const email = String(v.contact_email ?? '').trim();
    return `<li><div><b>${esc(v.vendor_name)}</b><small>${esc([v.vendor_category, v.vendor_location].filter(Boolean).join(' · '))}</small>
      <small>${email ? `We'll email a code to ${esc(maskEmail(email))}` : 'No email on file. Contact us to claim it.'}</small></div>
      <button type="button" class="btn btn-line btn-sm" data-action="claim-this" data-id="${esc(v.vendor_id)}"${email ? '' : ' disabled'}>This is mine</button></li>`;
  }).join('')}</ul>`;
}

export const moneyLabel = n => (n == null ? '' : formatMoney(n));

// ---------------------------------------------------------------- listing form


const checks = (name, values, chosen, { label = v => v } = {}) =>
  values.map(v => `<label><input type="checkbox" name="${esc(name)}" value="${esc(v)}"${chosen.includes(v) ? ' checked' : ''}> ${esc(label(v))}</label>`).join('');

/** The create / edit listing form. Category can only be picked when creating, like the app. */
export function renderListingForm({ vendor: v, categories, groups, isNew }) {
  const links = linksByKind(v.social_media_links);
  const states = v.vendor_state ?? [];
  const counties = v.vendor_county ?? [];
  const answers = v.filter_values ?? {};
  const photos = v.image_url ?? [];
  const num = x => (x == null ? '' : String(x));
  return `<form class="listing-form" novalidate>
    <section class="form-section">
      <h2>The basics</h2>
      ${field('vendor_name', 'Business name', { value: v.vendor_name ?? '', required: true })}
      ${isNew ? field('vendor_category', 'What do you offer?', { type: 'select', required: true, value: v.vendor_category ?? '', options: [['', 'Choose a vendor type'], ...categories.map(c => [c, c])] }) : `<p class="muted">Vendor type: <b>${esc(v.vendor_category ?? '')}</b></p>`}
      ${field('vendor_description', 'Description', { type: 'textarea', value: v.vendor_description ?? '', attrs: 'rows="7" placeholder="What makes you different? Who do you love working with?"' })}
      ${field('style_keywords', 'Style words', { value: v.style_keywords ?? '', attrs: 'placeholder="Rustic, Elegant, Mountain Views"' })}
    </section>

    <section class="form-section">
      <h2>Photos</h2>
      <p class="muted">The first photo leads your page. We resize photos for fast loading.</p>
      ${photos.length ? `<ul class="photo-grid">${photos.map((src, i) => `<li><img src="${esc(src)}" alt="Photo ${i + 1}"><button type="button" class="photo-remove" data-remove-photo="${i}" aria-label="Remove photo ${i + 1}">&times;</button></li>`).join('')}</ul>` : ''}
      <div class="field"><label for="f-photos">Add photos</label><input id="f-photos" type="file" name="photos" accept="image/*" multiple></div>
      <ul class="photo-grid photo-new" id="new-photos"></ul>
    </section>

    <section class="form-section">
      <h2>Pricing &amp; capacity</h2>
      <div class="field-row">${field('starting_price', 'Starting price ($)', { value: num(v.starting_price), attrs: 'inputmode="numeric" placeholder="3200"' })}${field('vendor_price', 'Pricing details', { value: v.vendor_price ?? '', attrs: 'placeholder="Packages from $3,200"' })}</div>
      <div class="field-row">${field('capacity_min', 'Fewest guests', { value: num(v.capacity_min), attrs: 'inputmode="numeric"' })}${field('capacity_max', 'Most guests', { value: num(v.capacity_max), attrs: 'inputmode="numeric"' })}</div>
      ${field('guest_capacity', 'Capacity notes', { value: v.guest_capacity ?? '', attrs: 'placeholder="150 seated, 300 standing"' })}
    </section>

    ${groups.length ? `<section class="form-section">
      <h2>Search filters</h2>
      <p class="muted">Couples filter by these. Vendors who leave them blank don't show up when a couple uses that filter.</p>
      ${groups.map(g => `<fieldset class="checks"><legend>${esc(g.label)}</legend>${g.options.map(o => `<label><input type="checkbox" name="filter:${esc(g.key)}" value="${esc(o.value)}"${(answers[g.key] ?? []).map(String).includes(o.value) ? ' checked' : ''}> ${esc(o.label)}</label>`).join('')}</fieldset>`).join('')}
    </section>` : ''}

    <section class="form-section">
      <h2>Where you work</h2>
      <div class="field-row">${field('vendor_location', 'City', { value: v.vendor_location ?? '', attrs: 'placeholder="Salt Lake City"' })}${field('address', 'Address', { value: v.address ?? '', attrs: 'placeholder="Optional"' })}</div>
      <details class="area"${states.length ? '' : ' open'}><summary>States you serve${states.length ? `: ${esc(states.join(', '))}` : ''}</summary><fieldset class="checks">${checks('state', US_STATES, states)}</fieldset></details>
      <details class="area"><summary>Utah counties you serve${counties.length ? `: ${esc(counties.join(', '))}` : ''}</summary><fieldset class="checks">${checks('county', UTAH_COUNTIES, counties)}</fieldset></details>
    </section>

    <section class="form-section">
      <h2>Contact</h2>
      <div class="field-row">${field('contact_email', 'Email', { type: 'email', value: v.contact_email ?? '' })}${field('contact_phone', 'Phone', { type: 'tel', value: v.contact_phone ?? '' })}</div>
      ${field('website_url', 'Website', { value: v.website_url ?? '', attrs: 'placeholder="yourbusiness.com"' })}
      <div class="field-row">${Object.entries(LINK_LABELS).map(([k, label]) => field(`link_${k}`, label, { value: links[k] ?? '', attrs: k === 'other' ? 'placeholder="Separate with commas"' : '' })).join('')}</div>
    </section>

    <p class="sheet-error" role="alert" hidden></p>
    <div class="form-actions">
      <button type="button" class="btn btn-line" data-action="cancel-edit">Cancel</button>
      <button type="submit" class="btn btn-plum">${isNew ? 'Create my listing' : 'Save changes'}</button>
    </div>
  </form>`;
}

/** FormData from the listing form -> the shape vendorPayload expects. */
export function readListingForm(fd) {
  const out = { links: {}, filters: {}, states: fd.getAll('state'), counties: fd.getAll('county') };
  for (const [k, v] of fd.entries()) {
    if (k.startsWith('link_')) out.links[k.slice(5)] = v;
    else if (k.startsWith('filter:')) (out.filters[k.slice(7)] ??= []).push(v);
    else if (!['state', 'county', 'photos'].includes(k)) out[k] = v;
  }
  return out;
}
