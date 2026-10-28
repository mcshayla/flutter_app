-- Only the easiYESt admin can make a listing live (is_listed). Vendors could
-- set it on their own listing through the API and skip review. Logged-in and
-- anonymous requests can no longer change it; the Supabase dashboard and
-- service-role requests (no app login) still can.

create or replace function public.guard_vendor_is_listed()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if coalesce(auth.jwt() ->> 'role', '') in ('authenticated', 'anon') then
    if tg_op = 'INSERT' and coalesce(new.is_listed, false) then
      raise exception 'New listings go live after easiYESt reviews them.';
    end if;
    if tg_op = 'UPDATE' and new.is_listed is distinct from old.is_listed then
      raise exception 'Only easiYESt can make a listing live or hide it.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_vendor_is_listed on public.vendors;
create trigger guard_vendor_is_listed
  before insert or update on public.vendors
  for each row execute function public.guard_vendor_is_listed();
