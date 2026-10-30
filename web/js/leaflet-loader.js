// Leaflet is only fetched the first time a page opens a map, so pages that
// never show one load as fast as before.

const LEAFLET = 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/';
let leaflet;

export const loadLeaflet = () => (leaflet ??= new Promise((resolve, reject) => {
  const css = Object.assign(document.createElement('link'), { rel: 'stylesheet', href: `${LEAFLET}leaflet.min.css` });
  const js = Object.assign(document.createElement('script'), { src: `${LEAFLET}leaflet.min.js`, onload: () => resolve(window.L), onerror: reject });
  document.head.append(css, js);
}));

export const TILES = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
export const TILE_OPTIONS = { maxZoom: 18, attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors' };

/** The plum map pin used on every map. */
export const pinIcon = L => L.divIcon({ className: 'vpin', html: '<span></span>', iconSize: [26, 26], iconAnchor: [13, 26], popupAnchor: [0, -24] });
