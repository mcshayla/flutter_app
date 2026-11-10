-- Vendors can have up to app_config.vendor_photo_limit photos (10). The app and
-- the website both check this, but an old copy of either could skip the check,
-- so the database enforces it too.
--
-- Only adding photos past the limit is refused. Listings that already have
-- more keep them and can still be edited, or have photos removed. Like
-- guard_vendor_is_listed, it applies to logged-in and anonymous requests only;
-- the Supabase dashboard and service-role scripts are not limited.

update public.app_config set value = '10' where key = 'vendor_photo_limit';

create or replace function public.guard_vendor_photo_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  photo_limit int;
  new_count int := coalesce(cardinality(new.image_url), 0);
  old_count int := case when tg_op = 'UPDATE' then coalesce(cardinality(old.image_url), 0) else 0 end;
begin
  if coalesce(auth.jwt() ->> 'role', '') not in ('authenticated', 'anon') then
    return new;
  end if;
  select nullif(value, '')::int into photo_limit
    from public.app_config where key = 'vendor_photo_limit';
  photo_limit := coalesce(photo_limit, 10);
  if new_count > photo_limit and new_count > old_count then
    raise exception 'Listings can have up to % photos.', photo_limit
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_vendor_photo_limit on public.vendors;
create trigger guard_vendor_photo_limit
  before insert or update on public.vendors
  for each row execute function public.guard_vendor_photo_limit();
