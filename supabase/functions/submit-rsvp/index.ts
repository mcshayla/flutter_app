import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const { token, ...formData } = body

    if (!token) {
      return json({ error: 'Missing token' }, 400)
    }

    if (!formData.first_name?.trim()) {
      return json({ error: 'First name is required' }, 400)
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Resolve token → user_id, group, and field config
    const { data: config, error: configError } = await supabase
      .from('guest_link_configs')
      .select('user_id, group_name, fields_enabled, partner1_name, partner2_name')
      .eq('token', token)
      .single()

    if (configError || !config) {
      return json({ error: 'Invalid or expired link' }, 404)
    }

    const fields = (config.fields_enabled ?? {}) as Record<string, boolean>

    // Build guest record — only include fields that were enabled in the link config
    const guest: Record<string, unknown> = {
      user_id: config.user_id,
      first_name: formData.first_name.trim(),
      last_name: (formData.last_name ?? '').trim(),
      rsvp_status: 'invited',
      group_name: config.group_name ?? '',
    }

    if (fields['email'])    guest['email']                = (formData.email ?? '').trim()
    if (fields['phone'])    guest['phone']                = (formData.phone ?? '').trim()
    if (fields['address'])  guest['address']              = (formData.address ?? '').trim()
    if (fields['dietary'])  guest['dietary_restrictions'] = (formData.dietary_restrictions ?? '').trim()
    if (fields['meal'])     guest['meal_preference']      = (formData.meal_preference ?? '').trim()
    if (fields['notes'])    guest['notes']                = (formData.notes ?? '').trim()
    if (fields['plus_one']) {
      const count = Math.max(0, parseInt(formData.plus_one_count ?? '0', 10) || 0)
      guest['plus_one_count'] = count
      guest['plus_one_allowed'] = count > 0
    }

    const { error: insertError } = await supabase.from('guests').insert(guest)

    if (insertError) {
      console.error('Insert error:', insertError)
      return json({ error: 'Failed to save your response. Please try again.' }, 500)
    }

    return json({ success: true }, 200)
  } catch (err) {
    console.error('Unexpected error:', err)
    return json({ error: 'Internal server error' }, 500)
  }
})

function json(data: unknown, status: number) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
