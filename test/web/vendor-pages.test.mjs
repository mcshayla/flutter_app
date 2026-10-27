import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as P from '../../scripts/vendor-pages/pages.mjs';

const text = html => html.replace(/<script[\s\S]*?<\/script>/g, ' ').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

test('slugify', () => {
  assert.equal(P.slugify('The Barn at Wall Brothers Orchards'), 'the-barn-at-wall-brothers-orchards');
  assert.equal(P.slugify('Photo & Video'), 'photo-and-video');
  assert.equal(P.slugify("  Café L'Amour!! "), 'cafe-l-amour');
  assert.equal(P.slugify('Invitations '), 'invitations');
});

test('category names, slugs and counts', () => {
  assert.deepEqual(P.categoryInfo('Venue'), { name: 'Venue', plural: 'Venues', slug: 'venues', one: 'venue', many: 'venues' });
  assert.equal(P.categoryInfo('Photo & Video').slug, 'photo-and-video');
  assert.equal(P.categoryInfo('Wedding Planning').plural, 'Wedding Planning');
  assert.equal(P.countLabel(P.categoryInfo('Catering'), 1), '1 caterer');
  assert.equal(P.countLabel(P.categoryInfo('Beauty'), 3), '3 vendors');
});

test('only listed, non-sample vendors are published', () => {
  assert.equal(P.isPublic({ is_listed: true, vendor_name: 'Memorial House' }), true);
  assert.equal(P.isPublic({ is_listed: false, vendor_name: 'Hidden' }), false);
  assert.equal(P.isPublic({ is_listed: true, vendor_name: '[SAMPLE] Willowbrook' }), false);
  assert.equal(P.isPublic({ is_listed: true, vendor_name: '  ' }), false);
});

test('vendor slugs are unique within a category and stable by creation order', () => {
  const vendors = [
    { vendor_id: 'b', vendor_name: 'Bloom', vendor_category: 'Florist', created_at: '2026-02-01' },
    { vendor_id: 'a', vendor_name: 'Bloom', vendor_category: 'Florist', created_at: '2026-01-01' },
    { vendor_id: 'c', vendor_name: 'Bloom', vendor_category: 'Cake', created_at: '2026-03-01' },
  ];
  const slugs = P.assignSlugs(vendors);
  assert.equal(slugs.get('a'), 'bloom');
  assert.equal(slugs.get('b'), 'bloom-2');
  assert.equal(slugs.get('c'), 'bloom');
});

test('price and capacity for the at-a-glance numbers', () => {
  assert.equal(P.glancePrice(4500, 'whatever'), '$4,500');
  assert.equal(P.glancePrice(null, '1000'), '$1,000');
  assert.equal(P.glancePrice(null, '$3,200'), '$3,200');
  assert.equal(P.glancePrice(null, ' Unknown '), null);
  assert.equal(P.glancePrice(null, ''), null);
  assert.equal(P.formatCapacity(50, 250), '50–250');
  assert.equal(P.formatCapacity(null, 120), 'Up to 120');
  assert.equal(P.formatCapacity(80, null), '80+');
  assert.equal(P.formatCapacity(null, null), null);
});

test('instagram handle from a profile link', () => {
  assert.equal(P.instagramHandle('https://www.instagram.com/adalynk.photography?igsh=x'), '@adalynk.photography');
  assert.equal(P.instagramHandle('https://instagram.com/_aa_beauty/'), '@_aa_beauty');
  assert.equal(P.instagramHandle('https://facebook.com/x'), null);
});

test('vendor slots: glance, details and grouped included items', () => {
  const slots = P.vendorSlots({
    filters: [
      { filter_key: 'starting_price', filter_type: 'range' },
      { filter_key: 'guest_capacity_range', filter_type: 'range' },
      { filter_key: 'venue_type', filter_label: 'Venue Type', filter_type: 'chips' },
      { filter_key: 'catering', filter_label: 'Catering', filter_type: 'chips', options: ['In-house', 'BYO caterer'] },
      { filter_key: 'venue_amenities', filter_label: 'Amenities', filter_type: 'chips' },
      { filter_key: 'unanswered', filter_label: 'Nope', filter_type: 'chips' },
    ],
    optionsByKey: {
      venue_type: [{ option_value: 'barn', option_label: 'Barns & Ranches' }],
      venue_amenities: [
        { option_value: 'bridal_suite', option_label: 'Bridal Suite', option_group: 'Facilities', icon_name: 'bed' },
        { option_value: 'sound', option_label: 'Sound System', option_group: 'Equipment', icon_name: 'speaker' },
      ],
    },
    vendor: {
      starting_price: 3200, capacity_min: 50, capacity_max: 300,
      filter_values: { venue_type: ['barn', 'old_value'], catering: ['BYO caterer'], venue_amenities: ['sound', 'bridal_suite'] },
    },
  });
  assert.deepEqual(slots.glance, [{ value: '$3,200', label: 'Starting price' }, { value: '50–300', label: 'Guests' }]);
  assert.deepEqual(slots.details, [{ label: 'Venue Type', value: 'Barns & Ranches · old_value' }, { label: 'Catering', value: 'BYO caterer' }]);
  assert.deepEqual(slots.included.map(g => [g.title, g.items.map(i => i.label)]), [['Facilities', ['Bridal Suite']], ['Equipment', ['Sound System']]]);
});

test('capacity only shows for vendor types that filter by it', () => {
  const slots = P.vendorSlots({ filters: [], optionsByKey: {}, vendor: { capacity_min: 10, capacity_max: 20, vendor_price: '900' } });
  assert.deepEqual(slots.glance, [{ value: '$900', label: 'Starting price' }]);
});

test('featured review is the newest with words', () => {
  const r = P.featuredReview([
    { comment: 'Old', created_at: '2026-01-01' },
    { comment: '  ', created_at: '2026-09-01' },
    { comment: 'New', created_at: '2026-05-01' },
  ]);
  assert.equal(r.comment, 'New');
  assert.equal(P.featuredReview([]), null);
});

const venue = {
  vendor_id: 'v-1', vendor_name: 'Barn & <Orchard>', vendor_category: 'Venue', vendor_location: 'Santaquin, Utah',
  vendor_description: 'A timber barn.\n\nHand-built with care.', vendor_price: '$3,200', starting_price: null,
  website_url: 'https://thebarn.com/', contact_email: 'hi@thebarn.com', contact_phone: '801-555-0100',
  image_url: ['https://x.supabase.co/a.jpg', 'https://x.supabase.co/b.jpg', 'https://x.supabase.co/c.jpg', 'https://x.supabase.co/d.jpg'],
  address: '918 UT-198, Santaquin, UT', style_keywords: 'Rustic, Elegant, ', social_media_links: ['https://www.instagram.com/thebarn/'],
  filter_values: {}, latitude: 40.0, longitude: -111.8,
};
const ctx = {
  category: P.categoryInfo('Venue'), slug: 'barn-and-orchard', filters: [], optionsByKey: {},
  reviews: [{ rating: 5, comment: 'Perfect "day"', created_at: '2026-06-01' }, { rating: 4, comment: '', created_at: '2026-07-01' }],
};

test('vendor page: head, structured data and escaping', () => {
  const html = P.renderVendorPage(venue, ctx);
  assert.match(html, /<title>Barn &amp; &lt;Orchard&gt; – Venue in Santaquin, Utah \| easiYESt<\/title>/);
  assert.match(html, /<link rel="canonical" href="https:\/\/www\.easiyest\.com\/vendors\/venues\/barn-and-orchard\/">/);
  assert.match(html, /<meta property="og:image" content="https:\/\/x\.supabase\.co\/a\.jpg">/);
  assert.doesNotMatch(html, /<Orchard>/);
  const ld = JSON.parse(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/.exec(html)[1]);
  assert.equal(ld['@type'], 'LocalBusiness');
  assert.equal(ld.name, 'Barn & <Orchard>');
  assert.equal(ld.aggregateRating.ratingValue, 4.5);
  assert.equal(ld.aggregateRating.reviewCount, 2);
  assert.equal(ld.address.streetAddress, '918 UT-198, Santaquin, UT');
});

test('structured data cannot close its script tag', () => {
  const html = P.renderVendorPage({ ...venue, vendor_description: 'x</script><script>alert(1)</script>' }, ctx);
  assert.equal((html.match(/<\/script>/g) || []).length, (html.match(/<script/g) || []).length);
});

test('vendor page: content', () => {
  const html = P.renderVendorPage(venue, ctx);
  const t = text(html);
  assert.match(t, /Venue · Santaquin, Utah/);
  assert.match(t, /Rustic Elegant/);
  assert.match(t, /\$3,200 Starting price/);
  assert.match(html, /<p>A timber barn\.<\/p>\s*<p>Hand-built with care\.<\/p>/);
  assert.match(html, /data-pick="love" data-vendor-id="v-1" data-category="Venue"/);
  assert.match(html, /data-pick="yes" data-vendor-id="v-1"/);
  assert.match(html, /href="https:\/\/thebarn\.com\/" rel="noopener" target="_blank"/);
  assert.match(html, /href="mailto:hi@thebarn\.com"/);
  assert.match(html, /href="tel:8015550100"/);
  assert.match(t, /@thebarn/);
  assert.match(t, /Perfect &quot;day&quot;/);
  assert.match(t, /4\.5 · 2 reviews/);
  assert.equal((html.match(/class="mosaic-img/g) || []).length, 3);
  assert.match(html, /href="\/vendors\/venues\/"/);
  assert.match(html, /data-budget-name="Barn &amp; &lt;Orchard&gt;" data-budget-amount="3200"/);
});

test('vendor page leaves out what a vendor has not filled in', () => {
  const bare = { vendor_id: 'v2', vendor_name: 'Quiet Co', vendor_category: 'Beauty', image_url: null, social_media_links: [], filter_values: null };
  const html = P.renderVendorPage(bare, { ...ctx, category: P.categoryInfo('Beauty'), slug: 'quiet-co', reviews: [] });
  const t = text(html);
  assert.doesNotMatch(t, /Starting price|Website|Instagram|undefined|null/);
  assert.match(t, /No reviews yet/);
  assert.match(html, /class="photo-placeholder"/);
});

test('unsafe links are dropped', () => {
  const html = P.renderVendorPage({ ...venue, website_url: 'javascript:alert(1)', social_media_links: ['javascript:x'] }, ctx);
  assert.doesNotMatch(html, /javascript:/);
});

test('category page lists vendors as cards with love and YES', () => {
  const html = P.renderCategoryPage(P.categoryInfo('Venue'), [
    { vendor: { ...venue, vendor_id: 'v-1' }, slug: 'barn-and-orchard' },
    { vendor: { vendor_id: 'v-2', vendor_name: 'Memorial House', vendor_category: 'Venue', vendor_location: 'Salt Lake City', image_url: [] }, slug: 'memorial-house' },
  ]);
  const t = text(html);
  assert.match(html, /<h1>Utah wedding <em>venues<\/em><\/h1>/);
  assert.match(t, /2 venues/);
  assert.match(html, /href="\/vendors\/venues\/memorial-house\/"/);
  assert.match(html, /data-pick="love" data-vendor-id="v-2"/);
  assert.match(html, /<link rel="canonical" href="https:\/\/www\.easiyest\.com\/vendors\/venues\/">/);
  assert.match(html, /"@type":"ItemList"/);
});

test('index page shows each vendor type with a count and cover photo', () => {
  const html = P.renderIndexPage([
    { category: P.categoryInfo('Venue'), count: 4, cover: 'https://x/a.jpg' },
    { category: P.categoryInfo('DJ'), count: 1, cover: null },
  ]);
  assert.match(html, /href="\/vendors\/venues\/"/);
  assert.match(text(html), /Venues 4 venues/);
  assert.match(text(html), /DJs 1 DJ/);
  assert.match(html, /src="https:\/\/x\/a\.jpg"/);
});

test('sitemap adds every generated page', () => {
  const base = '<?xml version="1.0"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n  <url><loc>https://www.easiyest.com/</loc></url>\n</urlset>\n';
  const xml = P.sitemapWithPages(base, ['/vendors/', '/vendors/venues/a&b/'], '2026-10-27');
  assert.match(xml, /<loc>https:\/\/www\.easiyest\.com\/vendors\/<\/loc><lastmod>2026-10-27<\/lastmod>/);
  assert.match(xml, /a&amp;b/);
  assert.match(xml, /<\/url>\n<\/urlset>\n$/);
});

test('long price text shows as a normal detail, not a big number', () => {
  const long = 'Rental rates vary - Off Season: $1,500–$3,200 | Peak Season: $1,800 - $3,800';
  const html = P.renderVendorPage({ ...venue, vendor_price: long }, ctx);
  assert.doesNotMatch(html, /class="fact fact-big"><b>Rental/);
  assert.match(html, /<div class="fact fact-wide"><small>Pricing<\/small><b>Rental rates vary/);
  assert.match(P.renderVendorPage(venue, ctx), /class="fact fact-big"><b>\$3,200<\/b><small>Starting price/);
});

test('header: Find Vendors, Planning Tools, Blog, List Your Business, Log In, and no gold button', () => {
  const html = P.renderIndexPage([]);
  const nav = /<nav aria-label="Main">([\s\S]*?)<\/nav>/.exec(html)[1];
  assert.deepEqual([...nav.matchAll(/>([^<]+)<\/a>/g)].map(m => m[1]), ['Find Vendors', 'Planning Tools', 'Blog', 'List Your Business', 'Log In']);
  assert.match(nav, /href="\/vendors\/" aria-current="page"/);
  assert.doesNotMatch(/<header[\s\S]*?<\/header>/.exec(html)[0], /btn-solid/);
  assert.match(html, /<nav aria-label="Footer">\s*<a href="\/vendors\/">Find Vendors<\/a>\s*<a href="\/plan.html">Planning Tools<\/a>/);
  assert.doesNotMatch(html, />For Vendors</);
});
