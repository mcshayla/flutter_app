// The "On the map" part of the listing form: suggests a pin when the vendor
// types a city or address, lets them drag it, or remove it. The rules are in
// vendor-pin.js.

import { pinQuery, parseGeocode, pinStatus } from './vendor-pin.js';
import { loadLeaflet, TILES, TILE_OPTIONS, pinIcon } from './leaflet-loader.js';

const UTAH = [39.5, -111.6];
const round = n => Math.round(n * 1e5) / 1e5;

async function geocode(q) {
  const u = new URL('https://nominatim.openstreetmap.org/search');
  u.search = new URLSearchParams({ q, countrycodes: 'us', format: 'jsonv2', limit: '1' });
  const res = await fetch(u, { headers: { Accept: 'application/json' } });
  if (!res.ok) throw new Error(`Geocoder ${res.status}`);
  return parseGeocode(await res.json());
}

export function wirePin(form, vendor) {
  const lat = form.querySelector('[name=latitude]');
  const lng = form.querySelector('[name=longitude]');
  const cleared = form.querySelector('[name=pin_cleared]');
  const status = form.querySelector('#pin-status');
  const box = form.querySelector('#pin-map');
  const adjust = form.querySelector('[data-action=pin-adjust]');
  const remove = form.querySelector('[data-action=pin-remove]');
  if (!lat || !lng || !cleared || !status || !box || !adjust || !remove) return;

  let map = null;
  let marker = null;
  let L = null;
  // Once the vendor places the pin by hand, typing in City/Address doesn't move it.
  let placedByHand = false;
  let lookup = 0;

  const current = () => (lat.value && lng.value ? [Number(lat.value), Number(lng.value)] : null);

  function setPin(p, label) {
    lat.value = p[0];
    lng.value = p[1];
    cleared.value = '';
    remove.hidden = false;
    status.textContent = pinStatus({ lat: p[0], lng: p[1], label });
    if (marker) {
      marker.setLatLng(p).setOpacity(1);
      if (!map.hasLayer(marker)) marker.addTo(map);
      map.setView(p, Math.max(map.getZoom(), 11));
    }
  }

  function removePin() {
    lookup++; // drop any lookup still on its way back
    placedByHand = false;
    lat.value = '';
    lng.value = '';
    cleared.value = '1';
    remove.hidden = true;
    status.textContent = pinStatus('removed');
    if (marker) marker.remove();
  }

  const fields = () => ({
    vendor_category: form.querySelector('[name=vendor_category]')?.value ?? vendor.vendor_category ?? '',
    address: form.querySelector('[name=address]')?.value ?? '',
    vendor_location: form.querySelector('[name=vendor_location]')?.value ?? '',
  });

  async function suggest() {
    if (placedByHand) return;
    const q = pinQuery(fields());
    if (!q) return;
    const mine = ++lookup;
    status.textContent = 'Finding you on the map…';
    try {
      const hit = await geocode(q);
      if (mine !== lookup) return; // a newer lookup started while this one was out
      if (hit) setPin([hit.lat, hit.lng], hit.label);
      else status.textContent = pinStatus('notfound');
    } catch {
      if (mine === lookup) status.textContent = pinStatus(current() ? { lat: 0, lng: 0 } : cleared.value ? 'removed' : null);
    }
  }

  async function openMap() {
    box.hidden = false;
    adjust.hidden = true;
    try {
      L = await loadLeaflet();
      const start = current();
      map = L.map(box).setView(start ?? UTAH, start ? 12 : 6);
      L.tileLayer(TILES, TILE_OPTIONS).addTo(map);
      marker = L.marker(start ?? UTAH, { icon: pinIcon(L), draggable: true, opacity: start ? 1 : 0.5 }).addTo(map);
      const byHand = p => { placedByHand = true; setPin([round(p.lat), round(p.lng)]); };
      marker.on('dragend', () => byHand(marker.getLatLng()));
      map.on('click', e => byHand(e.latlng));
      const tip = document.createElement('p');
      tip.className = 'muted pin-tip';
      tip.textContent = 'Drag the pin, or tap the map where you want it.';
      box.after(tip);
    } catch {
      box.innerHTML = '<p class="vmap-error">The map couldn\'t load. Check your connection and try again.</p>';
    }
  }

  // Suggest only when the vendor types a place, never just from opening the
  // form, so someone who removed their pin isn't put back on the map.
  form.querySelector('[name=vendor_location]')?.addEventListener('change', suggest);
  form.querySelector('[name=address]')?.addEventListener('change', suggest);
  form.querySelector('[name=vendor_category]')?.addEventListener('change', suggest);
  adjust.addEventListener('click', openMap);
  remove.addEventListener('click', removePin);
}
