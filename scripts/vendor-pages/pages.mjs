// Builds the website's vendor pages as plain HTML, so Google can read them:
//   /vendors/                     every vendor type
//   /vendors/<type>/              the vendors of one type
//   /vendors/<type>/<vendor>/     one vendor
// Pure functions: rows from Supabase in, HTML strings out. build.mjs fetches
// the data and writes the files at deploy time. Tested in
// test/web/vendor-pages.test.mjs.

import { formatMoney, parseMoney } from '../../web/js/plan-logic.js';
import { esc, ICONS } from '../../web/js/plan-view.js';

export const SITE = 'https://www.easiyest.com';

// ---------------------------------------------------------------- names

export function slugify(s) {
  return String(s ?? '')
    .normalize('NFKD').replace(/[\u0300-\u036f]/g, '')
    .toLowerCase().replace(/&/g, ' and ')
    .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

// Same wording as the app (lib/utils/category_names.dart).
const PLURAL = { Venue: 'Venues', Photographer: 'Photographers', Videographer: 'Videographers', Florist: 'Florists', DJ: 'DJs', Cake: 'Cakes', Jeweler: 'Jewelers' };
const NOUNS = {
  Venue: ['venue', 'venues'], Photographer: ['photographer', 'photographers'], Videographer: ['videographer', 'videographers'],
  'Photo & Video': ['photo & video team', 'photo & video teams'], Florist: ['florist', 'florists'], DJ: ['DJ', 'DJs'],
  Cake: ['baker', 'bakers'], Jeweler: ['jeweler', 'jewelers'], Catering: ['caterer', 'caterers'], 'Wedding Planning': ['planner', 'planners'],
};

export function categoryInfo(raw) {
  const name = String(raw ?? 'Other').trim();
  const plural = PLURAL[name] ?? name;
  const [one, many] = NOUNS[name] ?? ['vendor', 'vendors'];
  return { name, plural, slug: slugify(plural), one, many };
}

export const countLabel = (cat, n) => `${n} ${n === 1 ? cat.one : cat.many}`;

export const isPublic = v => v.is_listed === true && String(v.vendor_name ?? '').trim() !== '' && !/^\s*\[sample\]/i.test(v.vendor_name);

/** vendor_id -> slug, unique within each category; older vendors keep the plain name. */
export function assignSlugs(vendors) {
  const sorted = [...vendors].sort((a, b) => String(a.created_at ?? '').localeCompare(String(b.created_at ?? '')) || String(a.vendor_id).localeCompare(String(b.vendor_id)));
  const taken = new Set();
  const out = new Map();
  for (const v of sorted) {
    const cat = categoryInfo(v.vendor_category).slug;
    const base = slugify(v.vendor_name) || 'vendor';
    let slug = base, n = 2;
    while (taken.has(`${cat}/${slug}`)) slug = `${base}-${n++}`;
    taken.add(`${cat}/${slug}`);
    out.set(v.vendor_id, slug);
  }
  return out;
}

// ---------------------------------------------------------------- facts

export function glancePrice(startingPrice, priceText) {
  if (startingPrice != null) return formatMoney(startingPrice);
  const t = String(priceText ?? '').trim();
  if (!t || /^unknown$/i.test(t)) return null;
  return /^\d+(\.\d+)?$/.test(t) ? formatMoney(Number(t)) : t;
}

export function formatCapacity(min, max) {
  if (min == null && max == null) return null;
  if (min == null) return `Up to ${max}`;
  if (max == null) return `${min}+`;
  return min === max ? `${min}` : `${min}–${max}`;
}

export function instagramHandle(url) {
  const m = /instagram\.com\/([A-Za-z0-9._]+)/i.exec(String(url ?? ''));
  return m ? `@${m[1]}` : null;
}

const safeUrl = u => (/^https?:\/\//i.test(String(u ?? '').trim()) ? String(u).trim() : null);
const images = v => (Array.isArray(v.image_url) ? v.image_url.map(safeUrl).filter(Boolean) : []);
const keywords = v => String(v.style_keywords ?? '').split(',').map(s => s.trim()).filter(Boolean);
const answers = raw => (raw == null ? [] : (Array.isArray(raw) ? raw : [raw]).map(String).filter(Boolean));

/** Same three slots as the app's vendor page (lib/services/vendor_page_logic.dart). */
export function vendorSlots({ filters, optionsByKey, vendor }) {
  const glance = [];
  const price = glancePrice(vendor.starting_price, vendor.vendor_price);
  if (price) glance.push({ value: price, label: 'Starting price' });
  const capacity = formatCapacity(vendor.capacity_min ?? null, vendor.capacity_max ?? null);
  if (capacity && filters.some(f => f.filter_type === 'range' && String(f.filter_key).includes('capacity'))) glance.push({ value: capacity, label: 'Guests' });

  const details = [], included = [];
  const values = vendor.filter_values ?? {};
  for (const f of filters) {
    if (f.filter_type === 'range' || !f.filter_key) continue;
    const picked = answers(values[f.filter_key]);
    if (!picked.length) continue;
    const rows = optionsByKey[f.filter_key] ?? [];
    const known = new Set(rows.map(r => String(r.option_value)));
    const chosen = rows.filter(r => picked.includes(String(r.option_value)));
    const orphans = picked.filter(p => !known.has(p));
    const label = r => String(r.option_label ?? r.option_value);

    if (rows.some(r => r.icon_name)) {
      const groups = new Map();
      for (const r of chosen) {
        const key = r.option_group ?? null;
        if (!groups.has(key)) groups.set(key, []);
        groups.get(key).push({ label: label(r), icon: r.icon_name ?? null });
      }
      if (orphans.length) {
        if (!groups.has(null)) groups.set(null, []);
        groups.get(null).push(...orphans.map(o => ({ label: o, icon: null })));
      }
      for (const [title, items] of groups) included.push({ title, items });
    } else {
      const legacy = Array.isArray(f.options) ? f.options.map(String) : [];
      const labels = rows.length
        ? [...chosen.map(label), ...orphans]
        : [...legacy.filter(o => picked.includes(o)), ...picked.filter(p => !legacy.includes(p))];
      details.push({ label: String(f.filter_label ?? f.filter_key), value: labels.join(' · ') });
    }
  }
  return { glance, details, included };
}

export function featuredReview(reviews) {
  const written = reviews.filter(r => String(r.comment ?? '').trim());
  if (!written.length) return null;
  return written.sort((a, b) => String(b.created_at ?? '').localeCompare(String(a.created_at ?? '')))[0];
}

// ---------------------------------------------------------------- layout

const jsonLd = obj => `<script type="application/ld+json">${JSON.stringify(obj).replace(/</g, '\\u003c')}</script>`;

const jsonData = (id, obj) => `<script type="application/json" id="${id}">${JSON.stringify(obj).replace(/</g, '\\u003c')}</script>`;

function layout({ title, description, path, image, body, ld = [], noindex = false, scripts = '' }) {
  const url = `${SITE}${path}`;
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <link rel="icon" type="image/png" href="/favicon.png">
  <title>${esc(title)}</title>
  <meta name="description" content="${esc(description)}">
  <link rel="canonical" href="${esc(url)}">${noindex ? '\n  <meta name="robots" content="noindex">' : ''}
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="easiYESt">
  <meta property="og:title" content="${esc(title)}">
  <meta property="og:description" content="${esc(description)}">
  <meta property="og:url" content="${esc(url)}">${image ? `\n  <meta property="og:image" content="${esc(image)}">` : ''}
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,600;1,500&family=Montserrat:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/site.css">
  <link rel="stylesheet" href="/vendors.css">
  ${ld.map(jsonLd).join('\n  ')}
</head>
<body>
  <header class="top">
    <div class="top-inner">
      <a class="logo" href="/">easi<span>YES</span>t</a>
      <nav aria-label="Main">
        <a href="/vendors/" aria-current="page">Find Vendors</a>
        <a href="/plan.html">Planning Tools</a>
        <a href="/vendorRegistration">List Your Business</a>
        <a href="/account.html" data-account>Log In</a>
      </nav>
      <button class="menu-btn" id="menu-btn" aria-label="Open menu" aria-expanded="false" aria-controls="mobile-menu"><span></span><span></span><span></span></button>
    </div>
    <div class="mobile-menu" id="mobile-menu" hidden>
      <a href="/vendors/" aria-current="page">Find Vendors</a>
      <a href="/plan.html">Planning Tools</a>
      <a href="/vendorRegistration">List Your Business</a>
      <a href="/account.html" data-account>Log In</a>
    </div>
  </header>
  <main>
${body}
  </main>
  <footer>
    <div class="foot">
      <a class="logo" href="/">easi<span>YES</span>t</a>
      <div class="rule" aria-hidden="true"><i></i>${ICONS.heart}<i></i></div>
      <nav aria-label="Footer">
        <a href="/vendors/">Find Vendors</a>
        <a href="/plan.html">Planning Tools</a>
        <a href="/for-couples">For Couples</a>
        <a href="/utah-weddings">Utah Guide</a>
        <a href="/vendorRegistration">List Your Business</a>
        <a href="/blog/">Blog</a>
        <a href="/privacy">Privacy Policy</a>
      </nav>
      <small>&copy; 2026 easiYESt</small>
    </div>
  </footer>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js"></script>
  <script type="module" src="/js/vendor-app.js"></script>${scripts}
</body>
</html>
`;
}

const PICK_ICONS = {
  love: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="M12 21s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 11c0 5.5-7 10-7 10z"/></svg>',
  yes: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="M6 3h12l3 6-9 12L3 9z"/><path d="M3 9h18"/></svg>',
  web: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/></svg>',
  pin: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="M12 21s-6-5.5-6-11a6 6 0 0 1 12 0c0 5.5-6 11-6 11z"/><circle cx="12" cy="10" r="2.2"/></svg>',
  back: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M15 5l-7 7 7 7"/></svg>',
  star: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z"/></svg>',
};

const pickButtons = (v, cat, { small = false } = {}) => {
  const attrs = kind => `data-pick="${kind}" data-vendor-id="${esc(v.vendor_id)}" data-category="${esc(cat.name)}" aria-pressed="false"`;
  if (small) {
    return `<button type="button" class="pick-icon" ${attrs('love')} aria-label="Love ${esc(v.vendor_name)}">${PICK_ICONS.love}</button>
      <button type="button" class="pick-icon" ${attrs('yes')} aria-label="Say YES to ${esc(v.vendor_name)}">${PICK_ICONS.yes}</button>`;
  }
  return `<button type="button" class="pick" ${attrs('love')}>${PICK_ICONS.love}<span>Love</span></button>
    <button type="button" class="pick pick-yes" ${attrs('yes')}>${PICK_ICONS.yes}<span>YES</span></button>`;
};

const vendorPath = (cat, slug) => `/vendors/${cat.slug}/${slug}/`;
const photoPlaceholder = name => `<div class="photo-placeholder" aria-hidden="true"><span>${esc(String(name ?? '').trim().charAt(0).toUpperCase())}</span></div>`;

// ---------------------------------------------------------------- vendor page

export function renderVendorPage(v, { category: cat, slug, filters, optionsByKey, reviews }) {
  const path = vendorPath(cat, slug);
  const imgs = images(v);
  const slots = vendorSlots({ filters, optionsByKey, vendor: v });
  const kw = keywords(v);
  const location = String(v.vendor_location ?? '').trim();
  const website = safeUrl(v.website_url);
  const socials = (v.social_media_links ?? []).map(safeUrl).filter(Boolean);
  const email = String(v.contact_email ?? '').trim();
  const phone = String(v.contact_phone ?? '').trim();
  const address = String(v.address ?? '').trim();
  const rated = reviews.filter(r => Number(r.rating) > 0);
  const avg = rated.length ? Math.round((rated.reduce((s, r) => s + Number(r.rating), 0) / rated.length) * 10) / 10 : null;
  const quote = featuredReview(reviews);
  const budgetAmount = v.starting_price ?? parseMoney(v.vendor_price);
  const paragraphs = String(v.vendor_description ?? '').split(/\n\s*\n/).map(p => p.trim()).filter(Boolean);
  const mosaic = imgs.length >= 4 ? imgs.slice(1, 4) : imgs.length === 3 ? imgs : [];

  const description = (paragraphs[0] ?? `${v.vendor_name}, a Utah wedding ${cat.one}.`).replace(/\s+/g, ' ').slice(0, 155);
  const ld = {
    '@context': 'https://schema.org', '@type': 'LocalBusiness', name: v.vendor_name, url: `${SITE}${path}`,
    description: paragraphs.join(' ').slice(0, 500) || undefined, image: imgs.length ? imgs.slice(0, 5) : undefined,
    telephone: phone || undefined, email: email || undefined, sameAs: [website, ...socials].filter(Boolean),
    address: address || location ? { '@type': 'PostalAddress', streetAddress: address || undefined, addressLocality: location || undefined, addressRegion: 'UT', addressCountry: 'US' } : undefined,
    geo: v.latitude != null && v.longitude != null ? { '@type': 'GeoCoordinates', latitude: v.latitude, longitude: v.longitude } : undefined,
    priceRange: slots.glance.find(g => g.label === 'Starting price')?.value,
    aggregateRating: avg != null ? { '@type': 'AggregateRating', ratingValue: avg, reviewCount: rated.length } : undefined,
  };
  const crumbs = {
    '@context': 'https://schema.org', '@type': 'BreadcrumbList', itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Vendors', item: `${SITE}/vendors/` },
      { '@type': 'ListItem', position: 2, name: cat.plural, item: `${SITE}/vendors/${cat.slug}/` },
      { '@type': 'ListItem', position: 3, name: v.vendor_name, item: `${SITE}${path}` },
    ],
  };

  // Short values ("$3,200", "50–300") get the big number; a vendor's
  // paragraph about seasonal rates reads better as ordinary text.
  const facts = [...slots.glance.map(g => (g.value.length <= 18
    ? `<div class="fact fact-big"><b>${esc(g.value)}</b><small>${esc(g.label)}</small></div>`
    : `<div class="fact fact-wide"><small>${g.label === 'Starting price' ? 'Pricing' : esc(g.label)}</small><b>${esc(g.value)}</b></div>`)),
    ...slots.details.map(d => `<div class="fact"><small>${esc(d.label)}</small><b>${esc(d.value)}</b></div>`)].join('');

  const contact = [
    address || location ? `<li><small>${address ? 'Address' : 'Location'}</small><a href="https://www.google.com/maps/search/?api=1&amp;query=${encodeURIComponent(address || location)}" rel="noopener" target="_blank">${esc(address || location)}</a></li>` : '',
    website ? `<li><small>Website</small><a href="${esc(website)}" rel="noopener" target="_blank">${esc(website.replace(/^https?:\/\/(www\.)?/i, '').replace(/\/$/, ''))}</a></li>` : '',
    email ? `<li><small>Email</small><a href="mailto:${esc(email)}">${esc(email)}</a></li>` : '',
    phone ? `<li><small>Phone</small><a href="tel:${esc(phone.replace(/[^\d+]/g, ''))}">${esc(phone)}</a></li>` : '',
    ...socials.map(s => `<li><small>${instagramHandle(s) ? 'Instagram' : 'Social'}</small><a href="${esc(s)}" rel="noopener" target="_blank">${esc(instagramHandle(s) ?? s.replace(/^https?:\/\/(www\.)?/i, ''))}</a></li>`),
  ].join('');

  const body = `
  <nav class="crumbs" aria-label="Breadcrumb"><a href="/vendors/">Vendors</a><span aria-hidden="true">/</span><a href="/vendors/${cat.slug}/">${esc(cat.plural)}</a></nav>
  <article class="vendor" data-vendor-id="${esc(v.vendor_id)}">
    <div class="vendor-top">
      <div class="gallery">
        ${imgs.length ? `<div class="gallery-track" tabindex="0" aria-label="Photos of ${esc(v.vendor_name)}">${imgs.map((src, i) => `<img src="${esc(src)}" alt="${esc(v.vendor_name)}, photo ${i + 1} of ${imgs.length}" ${i ? 'loading="lazy" ' : 'fetchpriority="high" '}decoding="async">`).join('')}</div>${imgs.length > 1 ? `<span class="gallery-count">${imgs.length} photos</span>` : ''}` : photoPlaceholder(v.vendor_name)}
      </div>
      <div class="vendor-head">
        <span class="eyebrow">${esc([cat.name, location].filter(Boolean).join(' · '))}</span>
        <h1>${esc(v.vendor_name)}</h1>
        ${avg != null ? `<p class="rating">${PICK_ICONS.star}<span>${avg} · ${rated.length} review${rated.length === 1 ? '' : 's'}</span></p>` : ''}
        ${kw.length ? `<ul class="keywords">${kw.map(k => `<li>${esc(k)}</li>`).join('')}</ul>` : ''}
        <div class="picks">
          ${pickButtons(v, cat)}
          ${website ? `<a class="pick" href="${esc(website)}" rel="noopener" target="_blank">${PICK_ICONS.web}<span>Website</span></a>` : ''}
        </div>
        <div class="yes-note" hidden>${PICK_ICONS.yes}<span>Your YES for ${esc(cat.name)}</span>
          <button type="button" class="text-btn" data-add-budget data-budget-name="${esc(v.vendor_name)}" data-budget-amount="${budgetAmount ?? ''}" data-vendor-id="${esc(v.vendor_id)}" data-category="${esc(cat.name)}">Add to budget</button></div>
        ${facts ? `<div class="facts">${facts}</div>` : ''}
      </div>
    </div>

    <div class="vendor-body">
      <div class="vendor-main">
        ${paragraphs.length ? `<section><span class="eyebrow">About</span><h2>About ${esc(v.vendor_name)}</h2>${paragraphs.map(p => `<p>${esc(p)}</p>`).join('\n')}</section>` : ''}
        ${slots.included.length ? `<section class="included"><span class="eyebrow">What's included</span>${slots.included.map(g => `${g.title ? `<h3>${esc(g.title)}</h3>` : ''}<ul>${g.items.map(i => `<li>${esc(i.label)}</li>`).join('')}</ul>`).join('')}</section>` : ''}
        ${mosaic.length ? `<section class="mosaic" aria-label="More photos">${mosaic.map((src, i) => `<img class="mosaic-img${i === 0 ? ' is-arch' : ''}" src="${esc(src)}" alt="${esc(v.vendor_name)}" loading="lazy" decoding="async">`).join('')}</section>` : ''}
        <section class="reviews" id="reviews">
          <span class="eyebrow">Reviews</span>
          ${quote ? `<blockquote><p>${esc(quote.comment)}</p>${Number(quote.rating) > 0 ? `<cite>${'★'.repeat(Number(quote.rating))}<span class="sr-only">${quote.rating} out of 5</span></cite>` : ''}</blockquote>` : '<p class="muted">No reviews yet.</p>'}
          ${reviews.filter(r => r !== quote && String(r.comment ?? '').trim()).map(r => `<div class="review"><p>${esc(r.comment)}</p>${Number(r.rating) > 0 ? `<small>${'★'.repeat(Number(r.rating))}</small>` : ''}</div>`).join('')}
        </section>
      </div>
      ${contact ? `<aside class="contact"><span class="eyebrow">Contact &amp; location</span><ul>${contact}</ul>
        ${email ? `<a class="btn btn-plum" href="mailto:${esc(email)}?subject=${encodeURIComponent('Wedding inquiry from easiYESt')}">Contact ${esc(v.vendor_name)}</a>` : website ? `<a class="btn btn-plum" href="${esc(website)}" rel="noopener" target="_blank">Visit their website</a>` : ''}</aside>` : ''}
    </div>
    <p class="back-link"><a href="/vendors/${cat.slug}/">${PICK_ICONS.back}<span>All ${esc(cat.plural.toLowerCase())}</span></a></p>
  </article>`;

  return layout({
    title: `${v.vendor_name} – ${cat.name}${location ? ` in ${location}` : ' in Utah'} | easiYESt`,
    description, path, image: imgs[0], body, ld: [ld, crumbs],
  });
}

// ---------------------------------------------------------------- lists

function vendorCard({ vendor: v, slug }, cat) {
  const img = images(v)[0];
  const price = glancePrice(v.starting_price, v.vendor_price);
  const location = String(v.vendor_location ?? '').trim();
  return `<li class="vcard" data-vid="${esc(v.vendor_id)}">
    <a class="vcard-link" href="${vendorPath(cat, slug)}">
      <span class="vcard-photo">${img ? `<img src="${esc(img)}" alt="" loading="lazy" decoding="async">` : photoPlaceholder(v.vendor_name)}</span>
      ${location ? `<span class="vcard-place">${PICK_ICONS.pin}${esc(location)}</span>` : ''}
      <span class="vcard-name">${esc(v.vendor_name)}</span>
      ${price && price.length <= 24 ? `<span class="vcard-price">From ${esc(price)}</span>` : ''}
    </a>
    <div class="vcard-picks">${pickButtons(v, cat, { small: true })}</div>
  </li>`;
}

/**
 * What /js/category-filters.js needs to filter this page in the browser:
 * each vendor's area, answers, price and capacity, and this type's questions.
 */
export function filterData(cat, entries, { filters = [], options = [] } = {}) {
  const defs = filters.filter(f => String(f.category_name).trim() === cat.name);
  const keys = new Set(defs.map(d => d.filter_key));
  return {
    category: cat.name,
    noun: [cat.one, cat.many],
    vendors: entries.map(({ vendor: v }) => ({
      id: v.vendor_id, state: v.vendor_state ?? null, county: v.vendor_county ?? null, f: v.filter_values ?? {},
      price: typeof v.starting_price === 'number' ? v.starting_price : null, cmin: v.capacity_min ?? null, cmax: v.capacity_max ?? null,
    })),
    defs,
    options: options.filter(o => keys.has(o.filter_key)),
  };
}

export function renderCategoryPage(cat, entries, filterSource = {}) {
  const path = `/vendors/${cat.slug}/`;
  const ld = {
    '@context': 'https://schema.org', '@type': 'ItemList', name: `Utah wedding ${cat.plural.toLowerCase()}`,
    itemListElement: entries.map((e, i) => ({ '@type': 'ListItem', position: i + 1, url: `${SITE}${vendorPath(cat, e.slug)}`, name: e.vendor.vendor_name })),
  };
  const body = `
  <section class="intro intro-tight">
    <div class="intro-inner">
      <nav class="crumbs crumbs-center" aria-label="Breadcrumb"><a href="/vendors/">All vendors</a></nav>
      <h1>Utah wedding <em>${esc(cat.plural.toLowerCase())}</em></h1>
      <p class="note">${esc(countLabel(cat, entries.length))}</p>
    </div>
  </section>
  <section class="section vlist-section">
    <div class="vbrowse">
      <aside class="vfilters" id="vfilters" aria-label="Filters" hidden></aside>
      <div class="vresults">
        <div class="vtoolbar" id="vtoolbar" hidden></div>
        <ul class="vlist">${entries.map(e => vendorCard(e, cat)).join('')}</ul>
        <div class="vnone" id="vnone" hidden></div>
      </div>
    </div>
  </section>
  ${jsonData('filter-data', filterData(cat, entries, filterSource))}`;
  return layout({
    title: `Utah Wedding ${cat.plural} | easiYESt`,
    description: `Browse ${countLabel(cat, entries.length)} for Utah weddings. Compare prices, photos and reviews, and save your favorites on easiYESt.`,
    path, image: entries.map(e => images(e.vendor)[0]).find(Boolean), body, ld: [ld],
    scripts: '\n  <script type="module" src="/js/category-filters.js"></script>',
  });
}

export function renderIndexPage(groups) {
  const body = `
  <section class="intro intro-tight">
    <div class="intro-inner">
      <span class="eyebrow">Loved · Local · Curated</span>
      <h1>Find your Utah wedding <em>vendors</em></h1>
      <p>Handpicked venues, photographers, florists and more, all in one place.</p>
    </div>
  </section>
  <section class="section">
    <ul class="types">${groups.map(({ category: c, count, cover }) => `<li><a href="/vendors/${c.slug}/">
      <span class="type-arch">${cover ? `<img src="${esc(cover)}" alt="" loading="lazy" decoding="async">` : photoPlaceholder(c.plural)}</span>
      <span class="type-name">${esc(c.plural)}</span><span class="type-count">${esc(countLabel(c, count))}</span></a></li>`).join('')}</ul>
  </section>`;
  return layout({
    title: 'Utah Wedding Vendors – Venues, Photographers, Florists & More | easiYESt',
    description: 'Find Utah wedding vendors in one place: venues, photographers, caterers, florists, DJs and more, with photos, prices and reviews.',
    path: '/vendors/', image: groups.find(g => g.cover)?.cover, body,
  });
}

// ---------------------------------------------------------------- sitemap

export function sitemapWithPages(baseXml, paths, lastmod) {
  const entries = paths.map(p => `  <url><loc>${esc(`${SITE}${p}`)}</loc><lastmod>${lastmod}</lastmod><changefreq>weekly</changefreq><priority>${p === '/vendors/' ? '0.9' : '0.7'}</priority></url>`).join('\n');
  return baseXml.replace(/\s*<\/urlset>\s*$/, `\n\n  <!-- Vendor pages, generated at deploy by scripts/vendor-pages/build.mjs -->\n${entries}\n</urlset>\n`);
}

// ---------------------------------------------------------------- vendor index

/**
 * /vendors/index.json: a small directory of every published vendor, so the
 * Loved, YES and Compare pages can show cards and link to vendor pages
 * without querying the database. groups: [{ category, entries }].
 */
export function vendorIndex(groups, reviewsByVendor = {}) {
  const vendors = {};
  for (const { category: cat, entries } of groups) {
    for (const { vendor: v, slug } of entries) {
      const rated = (reviewsByVendor[v.vendor_id] ?? []).filter(r => Number(r.rating) > 0);
      vendors[v.vendor_id] = {
        id: v.vendor_id,
        name: v.vendor_name,
        category: cat.name,
        url: vendorPath(cat, slug),
        image: images(v)[0] ?? null,
        location: String(v.vendor_location ?? '').trim() || null,
        price: glancePrice(v.starting_price, v.vendor_price),
        amount: v.starting_price ?? parseMoney(v.vendor_price),
        keywords: keywords(v),
        email: String(v.contact_email ?? '').trim() || null,
        phone: String(v.contact_phone ?? '').trim() || null,
        website: safeUrl(v.website_url),
        rating: rated.length ? Math.round((rated.reduce((s, r) => s + Number(r.rating), 0) / rated.length) * 10) / 10 : null,
        reviews: rated.length,
      };
    }
  }
  return { categories: groups.map(({ category: c }) => ({ name: c.name, plural: c.plural, slug: c.slug })), vendors };
}
