// Writes the vendor pages and an updated sitemap from live Supabase data.
//
//   node scripts/vendor-pages/build.mjs <outDir> [sitemap.xml]
//
// Amplify runs this on every deploy (amplify.yml), so the pages follow
// vendors' latest details. It uses the public anon key and reads only what
// row-level security lets anyone read: listed vendors, categories, reviews.
// If Supabase can't be reached the build fails, so the last good site stays up.

import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { SUPABASE_URL, SUPABASE_ANON } from '../../web/js/supabase-config.js';
import { categoryInfo, isPublic, assignSlugs, renderVendorPage, renderCategoryPage, renderIndexPage, sitemapWithPages } from './pages.mjs';

const VENDOR_COLUMNS = [
  'vendor_id', 'vendor_name', 'vendor_category', 'vendor_description', 'vendor_location', 'vendor_price', 'starting_price',
  'website_url', 'contact_email', 'contact_phone', 'image_url', 'address', 'style_keywords', 'social_media_links',
  'latitude', 'longitude', 'filter_values', 'capacity_min', 'capacity_max', 'is_listed', 'created_at',
].join(',');

async function rows(path, { optional = false } = {}) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, { headers: { apikey: SUPABASE_ANON, Authorization: `Bearer ${SUPABASE_ANON}` } });
  if (!res.ok) {
    if (optional) return [];
    throw new Error(`Supabase ${path.split('?')[0]}: ${res.status} ${await res.text()}`);
  }
  return res.json();
}

async function write(file, html) {
  await mkdir(join(file, '..'), { recursive: true });
  await writeFile(file, html, 'utf8');
}

async function main() {
  const [outDir, sitemapSource] = process.argv.slice(2);
  if (!outDir) throw new Error('Usage: node scripts/vendor-pages/build.mjs <outDir> [sitemap.xml]');

  const [allVendors, categories, reviews, filters, options] = await Promise.all([
    rows(`vendors?select=${VENDOR_COLUMNS}&is_listed=eq.true`),
    rows('categories?select=name,display_order&order=display_order.asc'),
    rows('reviews?select=vendor_id,rating,comment,created_at&order=created_at.desc'),
    // Filter definitions are readable by logged-in users only today; without
    // them the pages still build, just without the Details and Included blocks.
    rows('category_filters?select=*&order=display_order.asc', { optional: true }),
    rows('filter_options?select=*&order=display_order.asc', { optional: true }),
  ]);

  const vendors = allVendors.filter(isPublic);
  const slugs = assignSlugs(vendors);
  const optionsByKey = {};
  for (const o of options) (optionsByKey[o.filter_key] ??= []).push(o);
  const reviewsByVendor = {};
  for (const r of reviews) (reviewsByVendor[r.vendor_id] ??= []).push(r);

  const order = new Map(categories.map((c, i) => [c.name.trim(), i]));
  const byCategory = new Map();
  for (const v of vendors) {
    const name = String(v.vendor_category ?? 'Other').trim();
    if (!byCategory.has(name)) byCategory.set(name, []);
    byCategory.get(name).push({ vendor: v, slug: slugs.get(v.vendor_id) });
  }
  const names = [...byCategory.keys()].sort((a, b) => (order.get(a) ?? 999) - (order.get(b) ?? 999) || a.localeCompare(b));

  const paths = ['/vendors/'];
  const groups = [];
  for (const name of names) {
    const cat = categoryInfo(name);
    // Vendors with photos first, then alphabetical, so each list opens strong.
    const entries = byCategory.get(name).sort((a, b) =>
      Number(!a.vendor.image_url?.length) - Number(!b.vendor.image_url?.length) || a.vendor.vendor_name.localeCompare(b.vendor.vendor_name));
    const catFilters = filters.filter(f => String(f.category_name).trim() === name);
    await write(join(outDir, 'vendors', cat.slug, 'index.html'), renderCategoryPage(cat, entries));
    paths.push(`/vendors/${cat.slug}/`);
    for (const e of entries) {
      const html = renderVendorPage(e.vendor, { category: cat, slug: e.slug, filters: catFilters, optionsByKey, reviews: reviewsByVendor[e.vendor.vendor_id] ?? [] });
      await write(join(outDir, 'vendors', cat.slug, e.slug, 'index.html'), html);
      paths.push(`/vendors/${cat.slug}/${e.slug}/`);
    }
    groups.push({ category: cat, count: entries.length, cover: entries.find(e => e.vendor.image_url?.length)?.vendor.image_url[0] ?? null });
  }
  await write(join(outDir, 'vendors', 'index.html'), renderIndexPage(groups));

  if (sitemapSource) {
    const base = await readFile(sitemapSource, 'utf8');
    await writeFile(join(outDir, 'sitemap.xml'), sitemapWithPages(base, paths, new Date().toISOString().slice(0, 10)), 'utf8');
  }
  console.log(`Vendor pages: ${vendors.length} vendors in ${groups.length} types (${allVendors.length - vendors.length} skipped), ${filters.length ? 'with' : 'WITHOUT'} filter details.`);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
