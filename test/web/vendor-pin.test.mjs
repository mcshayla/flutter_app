import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as Pin from '../../web/js/vendor-pin.js';
import * as V from '../../web/js/vendor-logic.js';

const text = html => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

test('what to look up: a venue\'s address, everyone else\'s town', () => {
  // Utah grid addresses: the geocoder finds "291 South 300 West", not "291 S 300 W".
  assert.equal(Pin.pinQuery({ vendor_category: 'Venue', address: '291 S 300 W', vendor_location: 'Logan' }), '291 South 300 West, Logan, Utah');
  assert.equal(Pin.pinQuery({ vendor_category: 'Venue', address: '375 N. Canyon Rd., Salt Lake City, UT 84103', vendor_location: '' }), '375 North Canyon Rd., Salt Lake City, UT 84103');
  assert.equal(Pin.pinQuery({ vendor_category: 'Photographer', address: '1414 36th St, Ogden', vendor_location: 'Ogden' }), 'Ogden, Utah');
  // A venue with no street address still gets its town.
  assert.equal(Pin.pinQuery({ vendor_category: 'Venue', address: '', vendor_location: 'Lehi' }), 'Lehi, Utah');
  // Not a place: no pin suggested.
  assert.equal(Pin.pinQuery({ vendor_category: 'DJ', address: '', vendor_location: 'Anywhere you are' }), null);
  assert.equal(Pin.pinQuery({ vendor_category: 'DJ', address: '', vendor_location: '  ' }), null);
  assert.equal(Pin.pinQuery({ vendor_category: 'DJ', address: '', vendor_location: 'Utah' }), null);
});

test('a geocoder answer becomes a pin, rounded, or nothing', () => {
  const hit = [{ lat: '40.298163', lon: '-111.694431', display_name: 'Orem, Utah County, Utah, United States' }];
  assert.deepEqual(Pin.parseGeocode(hit), { lat: 40.29816, lng: -111.69443, label: 'Orem, Utah County, Utah' });
  assert.equal(Pin.parseGeocode([]), null);
  assert.equal(Pin.parseGeocode(null), null);
});

test('saving: a pin, or no change', () => {
  assert.deepEqual(Pin.pinFields({ latitude: '40.29816', longitude: '-111.69443' }), { latitude: 40.29816, longitude: -111.69443 });
  // Nothing new to save: keep whatever pin is there.
  assert.deepEqual(Pin.pinFields({ latitude: '', longitude: '' }), {});
  assert.deepEqual(Pin.pinFields({ latitude: 'abc', longitude: '200' }), {});
});

test('saving: a removed pin is cleared, not kept', () => {
  assert.deepEqual(Pin.pinFields({ latitude: '', longitude: '', pin_cleared: '1' }), { latitude: null, longitude: null });
  // Placing a new pin after removing one wins.
  assert.deepEqual(Pin.pinFields({ latitude: '40.3', longitude: '-111.7', pin_cleared: '' }), { latitude: 40.3, longitude: -111.7 });
  const p = V.vendorPayload(V.readListingForm(new URLSearchParams('vendor_name=X&latitude=&longitude=&pin_cleared=1')));
  assert.equal(p.latitude, null);
  assert.equal(p.longitude, null);
});

test('form: Remove my pin only when there is a pin', () => {
  const pinned = V.renderListingForm({ vendor: { latitude: 40.3, longitude: -111.7 }, categories: ['DJ'], groups: [], isNew: false });
  assert.match(pinned, /<button type="button" class="text-btn" data-action="pin-remove">Remove my pin<\/button>/);
  assert.match(pinned, /<input type="hidden" name="pin_cleared" value="">/);
  const none = V.renderListingForm({ vendor: {}, categories: ['DJ'], groups: [], isNew: true });
  assert.match(none, /data-action="pin-remove" hidden>/);
});

test('the listing payload carries the pin, and only columns that exist', () => {
  const p = V.vendorPayload(V.readListingForm(new URLSearchParams('vendor_name=X&latitude=40.3&longitude=-111.7')));
  assert.equal(p.latitude, 40.3);
  assert.equal(p.longitude, -111.7);
  assert.equal('show_on_map' in p, false);
  assert.equal('latitude' in V.vendorPayload({ vendor_name: 'X', states: [], filters: {} }), false);
});

test('form: the map section shows the current pin', () => {
  const pinned = V.renderListingForm({ vendor: { latitude: 40.29816, longitude: -111.69443, show_on_map: true }, categories: ['DJ'], groups: [], isNew: false });
  assert.match(pinned, /<input type="hidden" name="latitude" value="40.29816">/);
  assert.match(pinned, /<input type="hidden" name="longitude" value="-111.69443">/);
  assert.match(text(pinned), /You're on the map/);
  assert.match(pinned, /data-action="pin-adjust"/);
  assert.match(pinned, /<div class="pin-map" id="pin-map" hidden><\/div>/);
  assert.doesNotMatch(pinned, /hide_from_map/);

  const fresh = V.renderListingForm({ vendor: {}, categories: ['DJ'], groups: [], isNew: true });
  assert.match(text(fresh), /Add your city and we'll suggest a pin/);
  assert.match(fresh, /name="latitude" value=""/);
});

test('pin status text', () => {
  assert.equal(Pin.pinStatus({ lat: 40.3, lng: -111.7, label: 'Orem, Utah County, Utah' }), 'We\'ll pin you at Orem, Utah County, Utah.');
  assert.equal(Pin.pinStatus({ lat: 40.3, lng: -111.7 }), 'You\'re on the map.');
  assert.equal(Pin.pinStatus(null), 'Add your city and we\'ll suggest a pin.');
  assert.equal(Pin.pinStatus('removed'), 'You won\'t appear on the map. Use Adjust pin, or change your city or address, to add a pin.');
  assert.equal(Pin.pinStatus('notfound'),'We couldn\'t find that place. Use Adjust pin to place it yourself.');
});
