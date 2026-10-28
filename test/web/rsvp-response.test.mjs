import { test } from 'node:test';
import assert from 'node:assert/strict';
import { guestFromRsvp } from '../../supabase/functions/submit-rsvp/rsvp-response.js';

const config = { user_id: 'couple-1', group_name: 'Smith family', fields_enabled: { email: true, meal: true, plus_one: true, dietary: true, notes: true } };

test('a guest who accepts is saved as attending', () => {
  const g = guestFromRsvp(config, { first_name: ' Jane ', last_name: 'Smith', attending: 'yes', email: 'jane@x.com ', meal_preference: 'Fish', plus_one_count: '2' });
  assert.equal(g.rsvp_status, 'accepted');
  assert.equal(g.first_name, 'Jane');
  assert.equal(g.user_id, 'couple-1');
  assert.equal(g.group_name, 'Smith family');
  assert.equal(g.email, 'jane@x.com');
  assert.equal(g.meal_preference, 'Fish');
  assert.equal(g.plus_one_count, 2);
  assert.equal(g.plus_one_allowed, true);
});

test('a guest who declines is saved as not attending, with no meal or extra guests', () => {
  const g = guestFromRsvp(config, { first_name: 'Sam', attending: 'no', meal_preference: 'Fish', dietary_restrictions: 'Vegan', plus_one_count: '3', notes: 'So sorry!' });
  assert.equal(g.rsvp_status, 'declined');
  assert.equal(g.plus_one_count, 0);
  assert.equal(g.plus_one_allowed, false);
  assert.equal(g.meal_preference, '');
  assert.equal(g.dietary_restrictions, '');
  assert.equal(g.notes, 'So sorry!');
});

test('an old form with no answer still saves, as waiting', () => {
  assert.equal(guestFromRsvp(config, { first_name: 'Old' }).rsvp_status, 'invited');
  assert.equal(guestFromRsvp(config, { first_name: 'Odd', attending: 'maybe?' }).rsvp_status, 'invited');
});

test('only the fields the couple turned on are saved', () => {
  const g = guestFromRsvp({ user_id: 'c', fields_enabled: {} }, { first_name: 'A', attending: 'yes', email: 'a@x.com', phone: '123' });
  assert.equal('email' in g, false);
  assert.equal('phone' in g, false);
  assert.equal(g.group_name, '');
});
