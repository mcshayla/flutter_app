// HTML for the Plan page's three tabs, built from plain data so it can be
// tested without a browser (test/web/plan-view.test.mjs). plan-app.js puts
// these strings on the page and handles the clicks through data-action.
// Everything a person typed goes through esc().

import {
  parseDate, daysBetween, countdownLabel, longDate, shortDate, formatMoney, isPastDue,
  groupChecklist, budgetSummary, groupBudget, isYesVendorItem, rsvpLabel, RSVP_STATUSES,
  headcount, statusCounts, filterGuests, guestGroups, guestName,
} from './plan-logic.js';

const ENTITIES = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
export const esc = v => String(v ?? '').replace(/[&<>"']/g, c => ENTITIES[c]);

const pct = f => `${Math.round(f * 100)}%`;

export const ICONS = {
  check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
  chevron: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M9 6l6 6-6 6"/></svg>',
  caret: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M6 9l6 6 6-6"/></svg>',
  plus: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M12 5v14M5 12h14"/></svg>',
  spark: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4" aria-hidden="true"><path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/></svg>',
  link: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/></svg>',
  meal: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M7 3v8M5 3v4a2 2 0 0 0 4 0V3M7 11v10M17 3c-2 0-3 2.5-3 6h3v12"/></svg>',
  download: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><path d="M12 4v11M7 10l5 5 5-5M5 20h14"/></svg>',
  diamond: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M6.5 4h11L21 9l-9 11L3 9z"/></svg>',
  circle: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><circle cx="12" cy="12" r="8"/></svg>',
  paid: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><circle cx="12" cy="12" r="8"/><path d="M8.5 12.2l2.4 2.4 4.6-4.8"/></svg>',
  heart: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true"><path d="M12 21s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 11c0 5.5-7 10-7 10z"/></svg>',
};

const button = (action, label, { variant = 'line', icon = '', extra = '' } = {}) =>
  `<button type="button" class="btn btn-${variant} btn-sm" data-action="${action}"${extra}>${icon ? ICONS[icon] : ''}<span>${esc(label)}</span></button>`;

const split = (summary, list) =>
  `<div class="plan-split"><aside class="plan-summary">${summary}</aside><section class="plan-list">${list}</section></div>`;

const card = (inner, cls = '') => `<div class="plan-card ${cls}">${inner}</div>`;
const stat = (value, label, cls = '') => `<div class="stat ${cls}"><b>${esc(value)}</b><small>${esc(label)}</small></div>`;
const emptyNote = (title, body) => `<div class="empty-note"><h3>${esc(title)}</h3><p>${esc(body)}</p></div>`;

// ---------------------------------------------------------------- countdown

export function renderCountdown(profile, now) {
  const date = parseDate(profile?.wedding_date);
  const label = countdownLabel(date ? daysBetween(now, date) : null);
  const m = /^(\d+) (.*)$/.exec(label);
  const big = m ? `<span>${m[1]}</span> <em>${esc(m[2])}</em>` : date ? esc(label) : `<em>${esc(label)}</em>`;
  return `<button type="button" class="countdown" data-action="edit-date">
    <span class="eyebrow">${esc(date ? longDate(date) : 'Your wedding')}</span>
    <span class="countdown-big">${big}</span>
    <span class="countdown-edit">${date ? 'Change date' : 'Add date'}</span>
  </button>`;
}

// ---------------------------------------------------------------- checklist

export function renderChecklist({ items, view, collapsed, now }) {
  if (!items.length) {
    return `<div class="plan-empty">
      <span class="eyebrow">Your checklist</span>
      <h2>Every task, in the <em>right order</em></h2>
      <div class="rule" aria-hidden="true"><i></i>${ICONS.heart}<i></i></div>
      <p>Pick the vendors you need and we'll build a timeline of tasks counted back from your wedding date.</p>
      <div class="plan-empty-actions">
        ${button('generate', 'Generate my checklist', { variant: 'plum', icon: 'spark' })}
        ${button('add-task', 'Add a task myself')}
      </div>
    </div>`;
  }

  const done = items.filter(i => i.is_completed === true).length;
  const summary = card(`
    <span class="eyebrow">Your checklist</span>
    <p class="card-title">${done} of ${items.length} tasks done</p>
    <div class="bar"><i style="width:${pct(done / items.length)}"></i></div>
    <div class="segmented" role="group" aria-label="Group tasks by">
      ${['timeline', 'category'].map(v => `<button type="button" data-action="view" data-view="${v}" aria-pressed="${view === v}">${v === 'timeline' ? 'Timeline' : 'Category'}</button>`).join('')}
    </div>
    <div class="card-actions">
      ${button('add-task', 'Add task', { variant: 'plum', icon: 'plus' })}
      ${button('generate', 'Regenerate', { icon: 'spark' })}
    </div>`);

  const list = groupChecklist(items, view, now).map(g => {
    const open = !collapsed.has(g.label);
    const rows = open ? `<ul class="rows">${g.items.map(i => taskRow(i, view, now)).join('')}</ul>` : '';
    return `<div class="group">
      <button type="button" class="group-head" data-action="toggle-group" data-group="${esc(g.label)}" aria-expanded="${open}">
        <h3>${esc(g.label)}</h3><span>${g.doneCount}/${g.items.length}</span>${ICONS.caret}
      </button>${rows}</div>`;
  }).join('');

  return split(summary, list);
}

function taskRow(item, view, now) {
  const done = item.is_completed === true;
  const due = parseDate(item.due_date);
  const meta = [view === 'timeline' && item.category ? item.category : '', due ? `Due ${shortDate(due)}` : ''].filter(Boolean).join(' · ');
  return `<li class="row${done ? ' is-done' : ''}">
    <button type="button" class="check" data-action="toggle-task" data-id="${esc(item.id)}" aria-pressed="${done}" aria-label="${done ? 'Mark not done' : 'Mark done'}: ${esc(item.title)}">${done ? ICONS.check : ''}</button>
    <button type="button" class="row-main" data-action="open-task" data-id="${esc(item.id)}">
      <span class="row-text"><span class="row-title">${esc(item.title)}</span>${meta ? `<span class="row-meta">${esc(meta)}</span>` : ''}</span>
      ${isPastDue(item, now) ? '<span class="tag tag-late">Past due</span>' : ''}${ICONS.chevron}
    </button>
  </li>`;
}

// ---------------------------------------------------------------- guests

const STATUS_CLASS = { accepted: 'tag-yes', declined: 'tag-no', invited: 'tag-wait', maybe: 'tag-wait' };

export function renderGuests({ guests, query, status, group }) {
  const counts = statusCounts(guests);
  const groups = guestGroups(guests);
  const shown = filterGuests(guests, { query, status, group });
  const option = (value, label, current) => `<option value="${esc(value)}"${value === current ? ' selected' : ''}>${esc(label)}</option>`;

  const summary = `
    ${card(`<div class="stats">${stat(headcount(guests), 'Guests')}${stat(counts.accepted, 'Attending', 'is-plum')}${stat(counts.declined, 'Declined')}${stat(counts.invited, 'Waiting')}</div>`, 'card-stats')}
    <div class="card-actions">
      ${button('rsvp-links', 'RSVP link', { icon: 'link' })}
      ${button('meals', 'Meals', { icon: 'meal' })}
      ${button('export', 'Export', { icon: 'download' })}
    </div>
    <div class="card-actions">${button('add-guest', 'Add guest', { variant: 'plum', icon: 'plus' })}</div>`;

  const filters = `<div class="filters">
    <label class="search"><span class="sr-only">Search guests</span><input type="search" data-filter="query" placeholder="Search guests" value="${esc(query)}"></label>
    <label><span class="sr-only">RSVP</span><select data-filter="status">${option('', 'All RSVPs', status)}${RSVP_STATUSES.map(s => option(s, rsvpLabel(s), status)).join('')}</select></label>
    ${groups.length ? `<label><span class="sr-only">Group</span><select data-filter="group">${option('', 'All groups', group)}${groups.map(g => option(g, g, group)).join('')}</select></label>` : ''}
  </div>`;

  let body;
  if (!guests.length) body = emptyNote('Your guest list starts here', 'Add guests one by one, or share your RSVP link and let them add themselves.');
  else if (!shown.length) body = emptyNote('No matches', 'Try a different name or clear the filters.');
  else body = `<ul class="rows">${shown.map(guestRow).join('')}</ul>`;

  return split(summary, filters + body);
}

function guestRow(g) {
  const name = guestName(g) || 'Unnamed guest';
  const plus = Math.trunc(Number(g.plus_one_count) || 0);
  const meta = [g.group_name, String(g.dietary_restrictions ?? '').trim()].filter(Boolean).join(' · ');
  return `<li class="row"><button type="button" class="row-main" data-action="open-guest" data-id="${esc(g.id)}">
    <span class="row-text"><span class="row-title">${esc(name)}${plus > 0 ? ` <small>+${plus}</small>` : ''}</span>${meta ? `<span class="row-meta">${esc(meta)}</span>` : ''}</span>
    <span class="tag ${STATUS_CLASS[g.rsvp_status] ?? 'tag-none'}">${esc(rsvpLabel(g.rsvp_status))}</span>
  </button></li>`;
}

// ---------------------------------------------------------------- budget

export function renderBudget({ total, items, yesByCategory }) {
  const s = budgetSummary(total, items);
  const totalLine = total > 0
    ? `<button type="button" class="budget-total" data-action="set-budget" aria-label="Change total budget">${formatMoney(total)}</button>`
    : `<button type="button" class="btn btn-line btn-sm" data-action="set-budget">Set your budget</button>`;

  const summary = `
    ${card(`<div class="budget-card">
      <span class="eyebrow">Total budget</span>
      ${totalLine}
      <div class="bar bar-budget${s.isOverBudget ? ' is-over' : ''}"><i class="planned" style="width:${pct(s.plannedFraction)}"></i><i style="width:${pct(s.spentFraction)}"></i></div>
      <div class="stats">${stat(formatMoney(s.planned), 'Planned')}${stat(formatMoney(s.spent), 'Spent', 'is-plum')}${stat(formatMoney(s.remaining), 'Remaining', s.isOverBudget ? 'is-error' : '')}</div>
      ${s.isOverBudget ? '<p class="over">Over budget</p>' : ''}
    </div>`)}
    <div class="card-actions">${button('add-expense', 'Add expense', { variant: 'plum', icon: 'plus' })}</div>`;

  const list = items.length
    ? groupBudget(items).map(g => {
      const gs = budgetSummary(0, g.items);
      return `<div class="group"><div class="group-head is-static"><h3>${esc(g.label)}</h3><span>${formatMoney(gs.spent)} of ${formatMoney(gs.planned)}</span></div>
        <ul class="rows">${g.items.map(i => budgetRow(i, yesByCategory)).join('')}</ul></div>`;
    }).join('')
    : emptyNote('Nothing added yet', 'Add expenses as you book. When you say YES to a vendor, you can add them here from their page.');

  return split(summary, list);
}

function budgetRow(item, yesByCategory) {
  const yes = isYesVendorItem(item, yesByCategory);
  const paid = item.is_paid === true;
  const amount = item.actual_cost ?? item.estimated_cost ?? 0;
  const icon = yes ? `<span class="row-icon is-yes" title="Your YES">${ICONS.diamond}</span>` : `<span class="row-icon${paid ? ' is-paid' : ''}">${paid ? ICONS.paid : ICONS.circle}</span>`;
  return `<li class="row"><button type="button" class="row-main" data-action="open-expense" data-id="${esc(item.id)}">
    ${icon}
    <span class="row-text"><span class="row-title">${esc(item.item_name)}</span><span class="row-meta">${[yes ? 'Your YES' : '', paid ? 'Paid' : 'Planned'].filter(Boolean).join(' · ')}</span></span>
    <span class="row-amount">${formatMoney(amount)}</span>${ICONS.chevron}
  </button></li>`;
}

// ---------------------------------------------------------------- saving

export function renderSaveBanner(user) {
  if (user) return '';
  return `<div class="save-banner" role="note">
    <p><strong>Your plan is saved in this browser only.</strong> Create a free account to keep it safe and see it on your phone.</p>
    <button type="button" class="btn btn-solid btn-sm" data-action="sign-up">Save my plan</button>
  </div>`;
}
