import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { guestFromRsvp } from './rsvp-response.js'

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

    // Attending or not, plus only the fields enabled in the link config.
    const guest = guestFromRsvp(config, formData)

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
