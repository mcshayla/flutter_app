// Pure logic behind the website's Plan page (checklist, guests, budget).
// Mirrors lib/services/plan_logic.dart in the Flutter app so both show the
// same numbers. No DOM or Supabase here, so it is unit tested directly
// (test/web/plan-logic.test.mjs). Rows are the raw Supabase records.

// ---------------------------------------------------------------- dates

/** "2027-06-12" -> local Date at midnight; null for anything else. */
export function parseDate(raw) {
  if (typeof raw !== 'string') return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(raw);
  return m ? new Date(+m[1], +m[2] - 1, +m[3]) : null;
}

export function isoDate(d) {
  const p = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

/** Whole calendar days from `from` to `to`, ignoring the time of day. */
export function daysBetween(from, to) {
  const a = Date.UTC(from.getFullYear(), from.getMonth(), from.getDate());
  const b = Date.UTC(to.getFullYear(), to.getMonth(), to.getDate());
  return Math.round((b - a) / 86400000);
}

export function countdownLabel(daysToGo) {
  if (daysToGo == null) return 'Set your wedding date';
  if (daysToGo < 0) return 'Just married';
  if (daysToGo === 0) return 'Today is the day';
  if (daysToGo === 1) return '1 day to go';
  return `${daysToGo} days to go`;
}

const WEEKDAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/** "Saturday, June 12, 2027" */
export const longDate = d => `${WEEKDAYS[d.getDay()]}, ${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;

/** "Jun 12, 2027" */
export const shortDate = d => `${MONTHS[d.getMonth()].slice(0, 3)} ${d.getDate()}, ${d.getFullYear()}`;

// ---------------------------------------------------------------- money

/** "$25,000": whole dollars, which is how couples think about a budget. */
export function formatMoney(amount) {
  const whole = Math.round(Number(amount) || 0);
  return `${whole < 0 ? '-' : ''}$${Math.abs(whole).toLocaleString('en-US')}`;
}

/** "$3,200" or "1500.50" -> number; null when blank or not a number. */
export function parseMoney(raw) {
  const cleaned = String(raw ?? '').replace(/[$,\s]/g, '');
  if (cleaned === '') return null;
  const n = Number(cleaned);
  return Number.isFinite(n) ? n : null;
}

const num = v => (Number.isFinite(Number(v)) && v !== null && v !== '' ? Number(v) : 0);

// ---------------------------------------------------------------- checklist

export function isPastDue(item, now) {
  if (item.is_completed === true) return false;
  const due = parseDate(item.due_date);
  return due != null && daysBetween(now, due) < 0;
}

const PAST_DUE = 'Past due', NO_DATE = 'No due date', DONE = 'Done';
const TIMELINE_ORDER = [PAST_DUE, 'This month', 'Next month', 'In 2–3 months', 'In 4–6 months', 'In 7–12 months', 'A year or more', NO_DATE, DONE];

function timelineBucket(item, now) {
  if (item.is_completed === true) return DONE;
  const due = parseDate(item.due_date);
  if (!due) return NO_DATE;
  if (isPastDue(item, now)) return PAST_DUE;
  const months = (due.getFullYear() - now.getFullYear()) * 12 + due.getMonth() - now.getMonth();
  if (months <= 0) return 'This month';
  if (months === 1) return 'Next month';
  if (months <= 3) return 'In 2–3 months';
  if (months <= 6) return 'In 4–6 months';
  if (months <= 12) return 'In 7–12 months';
  return 'A year or more';
}

function byDue(a, b) {
  const da = parseDate(a.due_date), db = parseDate(b.due_date);
  if (!da && !db) return 0;
  if (!da) return 1;
  if (!db) return -1;
  return da - db;
}

/**
 * Groups tasks for display. 'timeline': past due first, then by month, then
 * undated, then done. 'category': alphabetical, with "Other" last.
 */
export function groupChecklist(items, view, now) {
  const map = new Map();
  for (const item of items) {
    const key = view === 'timeline' ? timelineBucket(item, now) : (item.category?.trim() || 'Other');
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(item);
  }
  const keys = [...map.keys()];
  if (view === 'timeline') keys.sort((a, b) => TIMELINE_ORDER.indexOf(a) - TIMELINE_ORDER.indexOf(b));
  else keys.sort((a, b) => (a === 'Other' ? 1 : b === 'Other' ? -1 : a.toLowerCase().localeCompare(b.toLowerCase())));
  return keys.map(label => {
    const groupItems = map.get(label).sort(byDue);
    return { label, items: groupItems, doneCount: groupItems.filter(i => i.is_completed === true).length };
  });
}

/**
 * New checklist rows from the shared templates, counted back from the
 * wedding (30 days a month, like the app). Tasks whose date has already
 * passed are due today. Category names are compared trimmed because the
 * categories table has "Invitations " with a trailing space.
 */
export function buildChecklist(templates, weddingDate, categories, now) {
  const wanted = new Set(categories.map(c => c.trim().toLowerCase()));
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return templates
    .filter(t => wanted.has((t.category ?? '').trim().toLowerCase()))
    .sort((a, b) => (a.display_order ?? 0) - (b.display_order ?? 0))
    .map((t, i) => {
      const raw = new Date(weddingDate.getFullYear(), weddingDate.getMonth(), weddingDate.getDate() - (t.months_before ?? 0) * 30);
      return {
        template_id: t.id,
        title: t.title,
        description: t.description ?? '',
        category: t.category?.trim() || 'Other',
        is_completed: false,
        due_date: isoDate(raw < today ? today : raw),
        display_order: i,
        notes: '',
      };
    });
}

// ---------------------------------------------------------------- budget

export function budgetSummary(total, items) {
  let planned = 0, spent = 0;
  for (const i of items) {
    planned += num(i.estimated_cost);
    spent += num(i.actual_cost);
  }
  const clamp = v => (total <= 0 ? 0 : Math.min(1, Math.max(0, v / total)));
  return {
    total,
    planned,
    spent,
    // Matches the app: what is left of the total after money actually spent.
    remaining: total - spent,
    isOverBudget: total > 0 && spent > total,
    spentFraction: clamp(spent),
    plannedFraction: clamp(planned),
  };
}

export function groupBudget(items) {
  const map = new Map();
  for (const i of items) {
    const key = i.category || 'Other';
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(i);
  }
  return [...map].map(([label, groupItems]) => ({ label, items: groupItems }));
}

/** A budget line for a vendor the couple said YES to. */
export function isYesVendorItem(item, yesByCategory) {
  const id = item.vendor_id;
  return typeof id === 'string' && id !== '' && Object.values(yesByCategory).includes(id);
}

// ---------------------------------------------------------------- guests

export const RSVP_STATUSES = ['not_sent', 'invited', 'accepted', 'declined', 'maybe'];

export function rsvpLabel(status) {
  switch (status) {
    case 'accepted': return 'Attending';
    case 'declined': return 'Not attending';
    case 'invited': return 'Waiting';
    case 'maybe': return 'Maybe';
    default: return 'Not sent';
  }
}

const partySize = g => 1 + (Math.trunc(num(g.plus_one_count)) || 0);

export const headcount = guests => guests.reduce((sum, g) => sum + partySize(g), 0);

/** People per RSVP status, counting each guest's additional guests too. */
export function statusCounts(guests) {
  const counts = Object.fromEntries(RSVP_STATUSES.map(s => [s, 0]));
  for (const g of guests) {
    const s = RSVP_STATUSES.includes(g.rsvp_status) ? g.rsvp_status : 'not_sent';
    counts[s] += partySize(g);
  }
  return counts;
}

export const guestName = g => `${g.first_name ?? ''} ${g.last_name ?? ''}`.trim();

export function filterGuests(guests, { query = '', status = '', group = '' } = {}) {
  const q = query.trim().toLowerCase();
  return guests.filter(g =>
    (!q || guestName(g).toLowerCase().includes(q)) &&
    (!status || (g.rsvp_status || 'not_sent') === status) &&
    (!group || g.group_name === group));
}

export const guestGroups = guests => [...new Set(guests.map(g => g.group_name).filter(Boolean))].sort();

export function mealInfo(guests) {
  return guests
    .map(g => ({ name: guestName(g), meal: String(g.meal_preference ?? '').trim(), diet: String(g.dietary_restrictions ?? '').trim() }))
    .filter(i => i.meal || i.diet);
}

/** Guest list as CSV for Excel or Google Sheets. */
export function guestsToCsv(guests) {
  const cell = v => {
    let s = String(v ?? '');
    // A leading = + - @ would run as a formula when the file is opened.
    if (/^[=+\-@]/.test(s)) s = `'${s}`;
    return /[",\r\n]|^'/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  const head = ['First Name', 'Last Name', 'Email', 'Phone', 'Address', 'Group', 'RSVP', 'Meal Preference', 'Dietary Restrictions', 'Additional Guests', 'Notes'];
  const rows = guests.map(g => [
    g.first_name, g.last_name, g.email, g.phone, g.address, g.group_name, rsvpLabel(g.rsvp_status),
    g.meal_preference, g.dietary_restrictions, num(g.plus_one_count) || '', g.notes,
  ].map(cell).join(','));
  return [head.join(','), ...rows].join('\r\n') + '\r\n';
}

// Vendor type -> the budget's category list (the app's budget_item_form.dart).
const BUDGET_CATEGORY = {
  venue: 'Venue', catering: 'Catering', photographer: 'Photography', 'photo & video': 'Photography', videographer: 'Videography',
  florist: 'Flowers', dj: 'Music', 'ensembles + soloists': 'Music', attire: 'Attire', invitations: 'Invitations',
  'event decor & rental': 'Decor', transportation: 'Transportation', cake: 'Cake', beauty: 'Hair & Makeup',
};
export const budgetCategoryFor = vendorCategory => BUDGET_CATEGORY[String(vendorCategory ?? '').trim().toLowerCase()] ?? 'Other';
