// Turns an RSVP form (rsvp.html) into a guests row. Plain JS with no imports
// so the edge function (Deno) and the website tests (Node) share it.

// The form's "Will you be there?" answer -> guests.rsvp_status.
const STATUS = { yes: 'accepted', no: 'declined' }

/**
 * config: the guest_link_configs row (user_id, group_name, fields_enabled).
 * form: what the guest sent. Only the fields the couple turned on are saved.
 * Most links just collect addresses before invitations go out, so guests
 * save as 'not_sent'. Only a link with the "Will you be there?" question
 * turned on (fields_enabled.attending) saves Attending / Not attending.
 */
export function guestFromRsvp(config, form) {
  const fields = config.fields_enabled ?? {}
  const text = key => String(form[key] ?? '').trim()
  const status = (fields.attending && STATUS[form.attending]) || 'not_sent'
  const declined = status === 'declined'

  const guest = {
    user_id: config.user_id,
    first_name: text('first_name'),
    last_name: text('last_name'),
    rsvp_status: status,
    group_name: config.group_name ?? '',
  }
  if (fields.email) guest.email = text('email')
  if (fields.phone) guest.phone = text('phone')
  if (fields.address) guest.address = text('address')
  // Someone who isn't coming has no meal, diet or extra guests to plan for.
  if (fields.dietary) guest.dietary_restrictions = declined ? '' : text('dietary_restrictions')
  if (fields.meal) guest.meal_preference = declined ? '' : text('meal_preference')
  if (fields.notes) guest.notes = text('notes')
  if (fields.plus_one) {
    const count = declined ? 0 : Math.max(0, parseInt(form.plus_one_count ?? '0', 10) || 0)
    guest.plus_one_count = count
    guest.plus_one_allowed = count > 0
  }
  return guest
}
