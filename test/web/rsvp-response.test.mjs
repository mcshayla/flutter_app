import { test } from 'node:test';
import assert from 'node:assert/strict';
import { guestFromRsvp } from '../../supabase/functions/submit-rsvp/rsvp-response.js';

const fields = { email: true, meal: true, plus_one: true, dietary: true, notes: true };
const rsvpLink = { user_id: 'couple-1', group_name: 'Smith family', fields_enabled: { ...fields, attending: true } };
const addressLink = { user_id: 'couple-1', group_name: '', fields_enabled: { address: true } };

test('address-only link: guests are saved as Not sent (no invitation yet)', () => {
  const g = guestFromRsvp(addressLink, { first_name: 'Jane', address: '1 Main St' });
  assert.equal(g.rsvp_status, 'not_sent');
  assert.equal(g.address, '1 Main St');
});

test('address-only link ignores an attending answer it never asked for', () => {
  assert.equal(guestFromRsvp(addressLink, { first_name: 'Jane', attending: 'yes' }).rsvp_status, 'not_sent');
});

test('RSVP link: a guest who accepts is saved as attending', () => {
  const g = guestFromRsvp(rsvpLink, { first_name: ' Jane ', last_name: 'Smith', attending: 'yes', email: 'jane@x.com ', meal_preference: 'Fish', plus_one_count: '2' });
  assert.equal(g.rsvp_status, 'accepted');
  assert.equal(g.first_name, 'Jane');
  assert.equal(g.user_id, 'couple-1');
  assert.equal(g.group_name, 'Smith family');
  assert.equal(g.email, 'jane@x.com');
  assert.equal(g.meal_preference, 'Fish');
  assert.equal(g.plus_one_count, 2);
  assert.equal(g.plus_one_allowed, true);
});

test('RSVP link: a guest who declines is saved as not attending, with no meal or extra guests', () => {
  const g = guestFromRsvp(rsvpLink, { first_name: 'Sam', attending: 'no', meal_preference: 'Fish', dietary_restrictions: 'Vegan', plus_one_count: '3', notes: 'So sorry!' });
  assert.equal(g.rsvp_status, 'declined');
  assert.equal(g.plus_one_count, 0);
  assert.equal(g.plus_one_allowed, false);
  assert.equal(g.meal_preference, '');
  assert.equal(g.dietary_restrictions, '');
  assert.equal(g.notes, 'So sorry!');
});

test('RSVP link with no usable answer (an old copy of the form) saves as Not sent', () => {
  assert.equal(guestFromRsvp(rsvpLink, { first_name: 'Old' }).rsvp_status, 'not_sent');
  assert.equal(guestFromRsvp(rsvpLink, { first_name: 'Odd', attending: 'maybe?' }).rsvp_status, 'not_sent');
});

test('only the fields the couple turned on are saved', () => {
  const g = guestFromRsvp({ user_id: 'c', fields_enabled: {} }, { first_name: 'A', email: 'a@x.com', phone: '123' });
  assert.equal('email' in g, false);
  assert.equal('phone' in g, false);
  assert.equal(g.group_name, '');
});
