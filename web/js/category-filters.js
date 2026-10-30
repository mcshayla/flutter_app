// Filters on a /vendors/<type>/ page. The build puts this type's questions and
// each vendor's answers in #filter-data; picking filters hides the cards that
// don't match (the cards stay in the HTML for search engines). The picks live
// in the link, so a filtered list can be shared or bookmarked.

import { filtersFor, filterVendors, availableStates, availableCounties, activeCount, toQuery, fromQuery, mapPins, pinSpots } from './vendor-filter.js';
import { renderPanel, renderToolbar, renderNone, readPanel, renderPinPopup } from './filter-view.js';
import { loadLeaflet, TILES, TILE_OPTIONS, pinIcon } from './leaflet-loader.js';

const data = JSON.parse(document.getElementById('filter-data')?.textContent ?? 'null');
const panel = document.getElementById('vfilters');
const toolbar = document.getElementById('vtoolbar');
const none = document.getElementById('vnone');
const mapBox = document.getElementById('vmap');
const cards = new Map([...document.querySelectorAll('.vlist > .vcard[data-vid]')].map(li => [li.dataset.vid, li]));

/** The popup's details, read from the vendor's card already on the page. */
function cardInfo(li) {
  return {
    name: li.querySelector('.vcard-name')?.textContent ?? '',
    url: li.querySelector('.vcard-link')?.getAttribute('href') ?? '#',
    location: li.querySelector('.vcard-place')?.textContent.trim() ?? '',
    image: li.querySelector('.vcard-photo img')?.getAttribute('src') ?? null,
  };
}

if (data && panel && toolbar && cards.size) {
  const fs = filtersFor(data.category, data.defs, data.options);
  const noun = data.noun ?? ['vendor', 'vendors'];
  let sel = fromQuery(location.search, fs.questions.map(q => q.key));
  const pins = mapBox ? mapPins(data.vendors).filter(v => cards.has(v.id)) : [];
  let map = null;
  let mapOpen = false;

  const areas = () => ({ states: availableStates(data.vendors), counties: availableCounties(data.vendors, sel.state) });
  const hasAnything = () => pins.length || fs.questions.length || fs.price || fs.guests || areas().states.length || areas().counties.length;

  function drawPanel() {
    panel.innerHTML = renderPanel(fs, sel, areas());
  }

  const viewArea = () => {
    const b = map.getBounds();
    return { south: b.getSouth(), west: b.getWest(), north: b.getNorth(), east: b.getEast() };
  };

  async function showMap(on) {
    mapOpen = on;
    mapBox.hidden = !on;
    if (!on) { sel.mapArea = null; apply(); return; }
    apply();
    try {
      const L = await loadLeaflet();
      if (!map) {
        map = L.map(mapBox, { scrollWheelZoom: false });
        L.tileLayer(TILES, TILE_OPTIONS).addTo(map);
        const icon = pinIcon(L);
        for (const spot of pinSpots(pins)) {
          const here = spot.ids.map(id => cardInfo(cards.get(id)));
          L.marker([spot.lat, spot.lng], { icon, title: here.map(c => c.name).join(', ') })
            .bindPopup(here.length === 1 ? renderPinPopup(here[0]) : renderPinPopup(here)).addTo(map);
        }
        map.on('moveend', () => { if (mapOpen) { sel.mapArea = viewArea(); apply(); } });
        if (pins.length === 1) map.setView([pins[0].lat, pins[0].lng], 12);
        else map.fitBounds(pins.map(v => [v.lat, v.lng]), { padding: [36, 36] });
      } else {
        map.invalidateSize();
      }
      sel.mapArea = viewArea();
      apply();
    } catch {
      mapBox.innerHTML = '<p class="vmap-error">The map couldn\'t load. Check your connection and try again.</p>';
    }
  }

  function apply() {
    const shown = new Set(filterVendors(data.vendors, sel).map(v => v.id));
    for (const [id, li] of cards) li.hidden = !shown.has(id);
    toolbar.innerHTML = renderToolbar({ shown: shown.size, total: cards.size, active: activeCount(sel), noun, hasMap: pins.length > 0, mapOpen });
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
      typing = setTimeout(() => { sel = { ...readPanel(new FormData(panel.querySelector('form')), fs), mapArea: sel.mapArea }; apply(); }, 300);
    });
    panel.addEventListener('change', e => {
      const before = sel.state;
      sel = { ...readPanel(new FormData(panel.querySelector('form')), fs), mapArea: sel.mapArea };
      // A new state changes which counties make sense.
      if (sel.state !== before) { sel.county = null; drawPanel(); }
      apply();
    });
    panel.addEventListener('submit', e => e.preventDefault());
    document.addEventListener('click', e => {
      const b = e.target.closest('[data-vf]');
      if (!b) return;
      const act = b.dataset.vf;
      if (act === 'clear') { sel = { ...fromQuery('', []), mapArea: mapOpen && map ? viewArea() : null }; drawPanel(); apply(); }
      if (act === 'map') showMap(!mapOpen);
      if (act === 'open') open(true);
      if (act === 'close') { open(false); toolbar.querySelector('.vf-open')?.focus(); }
    });
    document.addEventListener('keydown', e => { if (e.key === 'Escape' && document.body.classList.contains('vf-is-open')) open(false); });
  }
}
