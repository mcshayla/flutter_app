// HTML for the category-page filters (/js/category-filters.js wires it up).
// Pure: strings in, strings out, so it's tested without a browser.

import { esc } from './plan-view.js';
import { emptySelection, priceSteps } from './vendor-filter.js';
import { formatMoney } from './plan-logic.js';

const select = (name, label, choices, current, anyLabel) => `<div class="vf-field"><label for="vf-${name}">${esc(label)}</label>
  <select id="vf-${name}" name="${name}"><option value="">${esc(anyLabel)}</option>${choices.map(([v, l]) => `<option value="${esc(v)}"${String(current ?? '') === String(v) ? ' selected' : ''}>${esc(l)}</option>`).join('')}</select></div>`;

function area(sel, { states, counties }) {
  if (!states.length && !counties.length) return '';
  return `<fieldset class="vf-group"><legend>Area</legend>
    ${states.length > 1 ? select('state', 'State', states.map(s => [s, s]), sel.state, 'Any state') : ''}
    ${counties.length ? select('county', 'County', counties.map(c => [c, c]), sel.county, 'Anywhere') : ''}
  </fieldset>`;
}

function price(p, sel) {
  if (!p) return '';
  const steps = priceSteps(p).map(n => [n, formatMoney(n)]);
  const min = sel.price && sel.price.min !== p.min ? sel.price.min : '';
  const max = sel.price && sel.price.max !== p.max ? sel.price.max : '';
  return `<fieldset class="vf-group"><legend>${esc(p.label)}</legend>
    <div class="vf-pair">${select('pmin', 'From', steps.slice(0, -1), min, 'Any')}${select('pmax', 'Up to', steps.slice(1), max, 'Any')}</div>
  </fieldset>`;
}

const guests = (on, sel) => (on ? `<fieldset class="vf-group"><legend>Guests</legend>
  <div class="vf-field"><label for="vf-guests">How many guests?</label><input id="vf-guests" name="guests" type="number" min="1" inputmode="numeric" placeholder="e.g. 150" value="${sel.guests ?? ''}"></div>
</fieldset>` : '');

function question(q, sel) {
  const chosen = new Set(sel.tags?.[q.key] ?? []);
  return `<fieldset class="vf-group"><legend>${esc(q.label)}</legend>
    ${q.sections.map(s => `${s.title ? `<p class="vf-sub">${esc(s.title)}</p>` : ''}<div class="vf-chips">${s.options.map(o => `<label class="vf-chip"><input type="checkbox" name="q:${esc(q.key)}" value="${esc(o.value)}"${chosen.has(o.value) ? ' checked' : ''}><span>${esc(o.label)}</span></label>`).join('')}</div>`).join('')}
  </fieldset>`;
}

export function renderPanel(fs, sel, areas) {
  return `<form class="vf-form" id="vf-form">
    <div class="vf-head"><h2>Filters</h2><button type="button" class="vf-close" data-vf="close" aria-label="Close filters">&times;</button></div>
    ${area(sel, areas)}${price(fs.price, sel)}${guests(fs.guests, sel)}
    ${fs.questions.map(q => question(q, sel)).join('')}
    ${fs.questions.length ? '<p class="vf-note">When you pick an answer, only vendors who answered that question show up.</p>' : ''}
    <div class="vf-foot"><button type="button" class="btn btn-line btn-sm" data-vf="clear">Clear all</button><button type="button" class="btn btn-plum btn-sm vf-done" data-vf="close">Show results</button></div>
  </form>`;
}

const plural = (noun, n) => (n === 1 ? noun[0] : noun[1]);

export function renderToolbar({ shown, total, active, noun }) {
  return `<button type="button" class="btn btn-line btn-sm vf-open" data-vf="open" aria-controls="vfilters">Filters${active ? ` <b class="vf-badge">${active}</b>` : ''}</button>
    <p class="vf-count" aria-live="polite">${active ? `Showing ${shown} of ${total} ${plural(noun, total)}` : `${total} ${plural(noun, total)}`}</p>
    ${active ? '<button type="button" class="vf-clear" data-vf="clear">Clear all</button>' : ''}`;
}

export const renderNone = noun => `<p>No ${esc(noun[1])} match these filters.</p><button type="button" class="btn btn-line btn-sm" data-vf="clear">Clear filters</button>`;

/** The panel's form fields back into a selection (FormData or URLSearchParams). */
export function readPanel(fd, fs) {
  const s = emptySelection();
  s.state = fd.get('state') || null;
  s.county = fd.get('county') || null;
  if (fs.price) {
    const min = fd.get('pmin'), max = fd.get('pmax');
    if (min || max) s.price = { min: min ? Number(min) : fs.price.min, max: max ? Number(max) : fs.price.max };
  }
  const g = Number.parseInt(fd.get('guests') ?? '', 10);
  if (fs.guests && g > 0) s.guests = g;
  for (const q of fs.questions) {
    const picks = fd.getAll(`q:${q.key}`);
    if (picks.length) s.tags[q.key] = picks;
  }
  return s;
}
