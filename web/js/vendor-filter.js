// Vendor filtering for the website's category pages. A port of the app's
// lib/services/vendor_filter.dart, so couples get the same results on both.
// Pure: no DOM, no Supabase.
//
// Vendors here are the small records the build writes into each category
// page: { id, state, county, f (filter_values), price, cmin, cmax }.
// 'Any' in state/county means the vendor serves everywhere; it is never
// offered as a choice.

const ANYWHERE = 'Any';

export const emptySelection = () => ({ state: null, county: null, tags: {}, price: null, guests: null });

const picked = tags => Object.values(tags ?? {}).filter(v => v?.length);

export const isEmpty = s => !s.state && !s.county && !s.price && s.guests == null && picked(s.tags).length === 0;

export const activeCount = s =>
  (s.state ? 1 : 0) + (s.county ? 1 : 0) + (s.price ? 1 : 0) + (s.guests != null ? 1 : 0) +
  picked(s.tags).reduce((n, v) => n + v.length, 0);

const asList = v => (v == null ? [] : Array.isArray(v) ? v.map(String) : [String(v)]);
const serves = (column, chosen) => { const l = asList(column); return l.includes(ANYWHERE) || l.includes(chosen); };

/** A vendor with nothing listed for an area that's been chosen doesn't match. */
export function matchesRegion(v, state, county) {
  if (state && !(v.state != null && serves(v.state, state))) return false;
  if (county && !(v.county != null && serves(v.county, county))) return false;
  return true;
}

/** Any pick within a question, every question. Unanswered = left out, not guessed. */
export function matchesTags(v, tags) {
  for (const [key, chosen] of Object.entries(tags ?? {})) {
    if (!chosen?.length) continue;
    const answered = asList(v.f?.[key]);
    if (!answered.length || !chosen.some(c => answered.includes(c))) return false;
  }
  return true;
}

export function matchesPrice(v, band) {
  if (!band) return true;
  if (typeof v.price !== 'number') return false;
  return v.price >= band.min && v.price <= band.max;
}

/** The venue holds that many guests; a blank side is open ended. */
export function matchesGuests(v, guests) {
  if (guests == null) return true;
  if (v.cmin == null && v.cmax == null) return false;
  return (v.cmin ?? 0) <= guests && guests <= (v.cmax ?? Infinity);
}

export function filterVendors(vendors, s) {
  if (isEmpty(s)) return vendors;
  return vendors.filter(v => matchesRegion(v, s.state, s.county) && matchesTags(v, s.tags) && matchesPrice(v, s.price) && matchesGuests(v, s.guests));
}

const selectable = column => asList(column).map(x => x.trim()).filter(x => x && x !== ANYWHERE);

export function availableStates(vendors) {
  return [...new Set(vendors.flatMap(v => selectable(v.state)))].sort();
}

export function availableCounties(vendors, state) {
  const out = new Set();
  for (const v of vendors) {
    if (state && v.state != null && !serves(v.state, state)) continue;
    selectable(v.county).forEach(c => out.add(c));
  }
  return [...out].sort();
}

/**
 * The filters a vendor type offers, from category_filters and filter_options:
 * the questions (chips, split into sections by option_group), and whether
 * there's a price band or a guest count.
 */
export function filtersFor(category, defs, options) {
  const name = String(category).trim();
  const mine = defs.filter(d => String(d.category_name).trim() === name).sort((a, b) => (a.display_order ?? 0) - (b.display_order ?? 0));
  const priceDef = mine.find(d => d.filter_type === 'range' && d.filter_key === 'starting_price');
  const questions = mine.filter(d => d.filter_type !== 'range').map(d => {
    const rows = options.filter(o => o.filter_key === d.filter_key).sort((a, b) => (a.display_order ?? 0) - (b.display_order ?? 0));
    const sections = [];
    if (rows.length) {
      for (const r of rows) {
        const title = r.option_group ?? null;
        let sec = sections.find(x => x.title === title);
        if (!sec) sections.push(sec = { title, options: [] });
        sec.options.push({ value: String(r.option_value), label: String(r.option_label ?? r.option_value) });
      }
    } else if (Array.isArray(d.options) && d.options.length) {
      sections.push({ title: null, options: d.options.map(o => ({ value: String(o), label: String(o) })) });
    }
    return { key: d.filter_key, label: d.filter_label ?? d.filter_key, sections };
  }).filter(q => q.sections.length);
  return {
    questions,
    price: priceDef ? { label: priceDef.filter_label ?? 'Starting price', min: priceDef.range_min ?? 0, max: priceDef.range_max ?? 10000, step: priceDef.range_step ?? 500 } : null,
    guests: mine.some(d => d.filter_type === 'range' && d.filter_key === 'guest_capacity_range'),
  };
}

/** Choices for the price dropdowns: about ten even steps. */
export function priceSteps({ min, max, step }) {
  const raw = Math.max(1, step || 1);
  const k = Math.max(1, Math.ceil((max - min) / raw / 10));
  const s = raw * k;
  const out = [];
  for (let p = min; p < max; p += s) out.push(p);
  out.push(max);
  return out;
}

const RESERVED = ['state', 'county', 'price', 'guests'];

export function toQuery(s) {
  const q = new URLSearchParams();
  if (s.state) q.set('state', s.state);
  if (s.county) q.set('county', s.county);
  if (s.price) q.set('price', `${s.price.min}-${s.price.max}`);
  if (s.guests != null) q.set('guests', String(s.guests));
  for (const [k, v] of Object.entries(s.tags ?? {})) if (v?.length && !RESERVED.includes(k)) q.set(k, v.join(','));
  return q.toString();
}

export function fromQuery(qs, questionKeys) {
  const q = new URLSearchParams(qs);
  const s = emptySelection();
  s.state = q.get('state') || null;
  s.county = q.get('county') || null;
  const m = /^(\d+)-(\d+)$/.exec(q.get('price') ?? '');
  if (m) s.price = { min: Number(m[1]), max: Number(m[2]) };
  const g = q.get('guests');
  if (g && /^\d+$/.test(g)) s.guests = Number(g);
  for (const k of questionKeys) {
    const v = q.get(k);
    if (v) s.tags[k] = v.split(',').filter(Boolean);
  }
  return s;
}
