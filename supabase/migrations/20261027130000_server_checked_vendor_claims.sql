-- Claiming a listing now goes through two server functions that check the
-- claimer really received a code at the listing's contact email. Before this,
-- the update policies let any logged-in user edit or claim any unclaimed
-- listing, and the emailed-code check only ran in the app or browser.
--
-- Flow (website /vendor.html):
--   1. The vendor confirms a code sent to the listing's contact email, which
--      briefly logs the browser in as that email.
--   2. start_vendor_claim(listing): the server checks that this login's email
--      is the listing's contact email and that it came from an emailed code in
--      the last 15 minutes, then returns a one-use ticket.
--   3. The vendor's own login is put back and finish_vendor_claim(ticket)
--      claims the listing for that account.
-- Claiming from the phone app is turned off; it points vendors to the website.

create table if not exists public.vendor_claim_tickets (
  ticket uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors (vendor_id) on delete cascade,
  created_at timestamptz not null default now(),
  used_at timestamptz
);
-- Only the two functions below touch tickets.
alter table public.vendor_claim_tickets enable row level security;
revoke all on public.vendor_claim_tickets from anon, authenticated;

create or replace function public.start_vendor_claim(target_vendor uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  claims jsonb := auth.jwt();
  listing record;
  new_ticket uuid;
begin
  if auth.uid() is null then
    raise exception 'Log in first.';
  end if;

  select vendor_id, contact_email, vendor_user_id, is_claimed
    into listing
    from public.vendors
   where vendor_id = target_vendor;
  if not found then
    raise exception 'That listing was not found.';
  end if;
  if listing.vendor_user_id is not null or coalesce(listing.is_claimed, false) then
    raise exception 'That listing has already been claimed.';
  end if;
  if coalesce(btrim(listing.contact_email), '') = ''
     or lower(btrim(listing.contact_email)) <> lower(coalesce(claims ->> 'email', '')) then
    raise exception 'Confirm the business email for this listing first.';
  end if;
  -- A password login doesn't prove the inbox: some accounts are confirmed
  -- without an email, so only a recent emailed code counts.
  if not exists (
    select 1
      from jsonb_array_elements(coalesce(claims -> 'amr', '[]'::jsonb)) m
     where m ->> 'method' in ('otp', 'magiclink')
       and (m ->> 'timestamp')::bigint > extract(epoch from now()) - 900
  ) then
    raise exception 'Confirm the business email with the code we send it.';
  end if;

  insert into public.vendor_claim_tickets (vendor_id)
  values (target_vendor)
  returning ticket into new_ticket;
  return new_ticket;
end;
$$;

create or replace function public.finish_vendor_claim(claim_ticket uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := auth.uid();
  claimed_vendor uuid;
  claimed_name text;
begin
  if me is null then
    raise exception 'Log in first.';
  end if;

  update public.vendor_claim_tickets
     set used_at = now()
   where ticket = claim_ticket
     and used_at is null
     and created_at > now() - interval '15 minutes'
  returning vendor_id into claimed_vendor;
  if claimed_vendor is null then
    raise exception 'That confirmation has expired. Start the claim again.';
  end if;

  -- One listing per account, the same as the app.
  if exists (
    select 1
      from public.vendor_profiles p
      join public.vendors v on v.vendor_id = p.vendor_id
     where p.user_id = me and v.vendor_user_id = me
  ) then
    raise exception 'This account already has a listing.';
  end if;

  update public.vendors
     set vendor_user_id = me, is_claimed = true, claimed_at = now()
   where vendor_id = claimed_vendor
     and vendor_user_id is null
     and coalesce(is_claimed, false) = false
  returning vendor_name into claimed_name;
  if not found then
    raise exception 'That listing has already been claimed.';
  end if;

  -- Replaces a leftover profile from an earlier claim that never finished.
  insert into public.vendor_profiles (user_id, vendor_id, business_name)
  values (me, claimed_vendor, claimed_name)
  on conflict (user_id) do update
    set vendor_id = excluded.vendor_id,
        business_name = excluded.business_name,
        updated_at = now();

  return claimed_vendor;
end;
$$;

revoke all on function public.start_vendor_claim(uuid) from public, anon;
revoke all on function public.finish_vendor_claim(uuid) from public, anon;
grant execute on function public.start_vendor_claim(uuid) to authenticated;
grant execute on function public.finish_vendor_claim(uuid) to authenticated;

-- Vendors can now only change listings they own. "Vendors can update own
-- info" (auth.uid() = vendor_user_id) stays.
drop policy if exists "Users can claim unclaimed vendors" on public.vendors;
drop policy if exists "Vendors can update their own record" on public.vendors;

-- A vendor profile can only point at a listing the account owns.
drop policy if exists "Vendors can insert own profile" on public.vendor_profiles;
drop policy if exists "Users can create own vendor profile" on public.vendor_profiles;
drop policy if exists "Vendors can update own profile" on public.vendor_profiles;

create policy "Vendors can insert own profile" on public.vendor_profiles
  for insert to authenticated
  with check (
    auth.uid() = user_id
    and vendor_id in (select vendor_id from public.vendors where vendor_user_id = auth.uid())
  );

create policy "Vendors can update own profile" on public.vendor_profiles
  for update to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and vendor_id in (select vendor_id from public.vendors where vendor_user_id = auth.uid())
  );
