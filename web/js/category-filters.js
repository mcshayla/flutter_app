// Filters on a /vendors/<type>/ page. The build puts this type's questions and
// each vendor's answers in #filter-data; picking filters hides the cards that
// don't match (the cards stay in the HTML for search engines). The picks live
// in the link, so a filtered list can be shared or bookmarked.

import { filtersFor, filterVendors, availableStates, availableCounties, activeCount, toQuery, fromQuery } from './vendor-filter.js';
import { renderPanel, renderToolbar, renderNone, readPanel } from './filter-view.js';

const data = JSON.parse(document.getElementById('filter-data')?.textContent ?? 'null');
const panel = document.getElementById('vfilters');
const toolbar = document.getElementById('vtoolbar');
const none = document.getElementById('vnone');
const cards = new Map([...document.querySelectorAll('.vlist > .vcard[data-vid]')].map(li => [li.dataset.vid, li]));

if (data && panel && toolbar && cards.size) {
  const fs = filtersFor(data.category, data.defs, data.options);
  const noun = data.noun ?? ['vendor', 'vendors'];
  let sel = fromQuery(location.search, fs.questions.map(q => q.key));

  const areas = () => ({ states: availableStates(data.vendors), counties: availableCounties(data.vendors, sel.state) });
  const hasAnything = () => fs.questions.length || fs.price || fs.guests || areas().states.length || areas().counties.length;

  function drawPanel() {
    panel.innerHTML = renderPanel(fs, sel, areas());
  }

  function apply() {
    const shown = new Set(filterVendors(data.vendors, sel).map(v => v.id));
    for (const [id, li] of cards) li.hidden = !shown.has(id);
    toolbar.innerHTML = renderToolbar({ shown: shown.size, total: cards.size, active: activeCount(sel), noun });
    none.hidden = shown.size > 0;
    none.innerHTML = shown.size ? '' : renderNone(noun);
    const qs = toQuery(sel);
    history.replaceState(null, '', qs ? `?${qs}` : location.pathname);
  }

  const open = on => {
    document.body.classList.toggle('vf-is-open', on);
    if (on) panel.querySelector('select, input, button')?.focus();
  };

  if (hasAnything()) {
    document.querySelector('.vbrowse')?.classList.add('has-filters');
    panel.hidden = false;
    toolbar.hidden = false;
    drawPanel();
    apply();

    // The guest count updates as it's typed, not only when the box is left.
    let typing;
    panel.addEventListener('input', e => {
      if (e.target.name !== 'guests') return;
      clearTimeout(typing);
      typing = setTimeout(() => { sel = readPanel(new FormData(panel.querySelector('form')), fs); apply(); }, 300);
    });
    panel.addEventListener('change', e => {
      const before = sel.state;
      sel = readPanel(new FormData(panel.querySelector('form')), fs);
      // A new state changes which counties make sense.
      if (sel.state !== before) { sel.county = null; drawPanel(); }
      apply();
    });
    panel.addEventListener('submit', e => e.preventDefault());
    document.addEventListener('click', e => {
      const b = e.target.closest('[data-vf]');
      if (!b) return;
      const act = b.dataset.vf;
      if (act === 'clear') { sel = fromQuery('', []); drawPanel(); apply(); }
      if (act === 'open') open(true);
      if (act === 'close') { open(false); toolbar.querySelector('.vf-open')?.focus(); }
    });
    document.addEventListener('keydown', e => { if (e.key === 'Escape' && document.body.classList.contains('vf-is-open')) open(false); });
  }
}
