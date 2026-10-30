// Where a vendor shows on the category-page map. Pure: no DOM, no network.
//
// Venues are pinned at their street address (couples go there); everyone
// else at their town, since many work from home. Vendors can drag the pin,
// leave the suggestion as it is, or remove it. A pin is only suggested when
// they type a city or address, so a removed pin stays removed.

const NOT_A_PLACE = /anywhere|wherever|county|counties|travel|^\s*$/i;

/** The town from a free-text location like "Orem Utah" or "Layton, UT". */
const town = loc => String(loc ?? '').replace(/[,\s]*\b(UT|Utah)\b\.?\s*$/i, '').trim();

const DIRECTIONS = { N: 'North', S: 'South', E: 'East', W: 'West' };

/** Utah grid addresses ("291 S 300 W") with the directions spelled out, which the geocoder matches. */
const spellDirections = street => street.replace(/\b([NSEW])\b\.?/g, (_, d) => DIRECTIONS[d]);

/** What to ask the geocoder for, or null when there's no real place to pin. */
export function pinQuery({ vendor_category: category, address, vendor_location: location }) {
  const street = spellDirections(String(address ?? '').trim());
  const place = town(location);
  if (String(category ?? '').trim() === 'Venue' && street) {
    const parts = [street];
    if (!street.includes(',') && place) parts.push(place);
    if (!/\b(UT|Utah)\b/i.test(parts.join(' '))) parts.push('Utah');
    return parts.join(', ');
  }
  if (!place || NOT_A_PLACE.test(place)) return null;
  return `${place}, Utah`;
}

const round = n => Math.round(n * 1e5) / 1e5;

/** Nominatim's first answer as { lat, lng, label }, or null. */
export function parseGeocode(results) {
  const [hit] = Array.isArray(results) ? results : [];
  if (!hit) return null;
  const label = String(hit.display_name ?? '').split(',').map(s => s.trim()).filter(s => s && s !== 'United States' && !/^\d{5}$/.test(s)).join(', ');
  return { lat: round(Number(hit.lat)), lng: round(Number(hit.lon)), label };
}

const coord = (v, limit) => {
  const n = Number.parseFloat(v);
  return Number.isFinite(n) && Math.abs(n) <= limit ? n : null;
};

/** The vendors-table columns for the pin. A removed pin clears it; no usable pin keeps the saved one. */
export function pinFields(f) {
  const lat = coord(f.latitude, 90);
  const lng = coord(f.longitude, 180);
  if (lat != null && lng != null) return { latitude: lat, longitude: lng };
  return f.pin_cleared ? { latitude: null, longitude: null } : {};
}

/** The line under the map controls. `pin` is { lat, lng, label? }, null, or 'notfound'. */
export function pinStatus(pin) {
  if (pin === 'removed') return 'You won\'t appear on the map. Use Adjust pin, or change your city or address, to add a pin.';
  if (pin === 'notfound') return'We couldn\'t find that place. Use Adjust pin to place it yourself.';
  if (!pin) return 'Add your city and we\'ll suggest a pin.';
  return pin.label ? `We'll pin you at ${pin.label}.` : 'You\'re on the map.';
}
