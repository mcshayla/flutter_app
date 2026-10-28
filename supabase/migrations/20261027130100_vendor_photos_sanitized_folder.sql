-- The app and website save vendor photos under the business name with
-- anything but letters, numbers, spaces, _ and - turned into _
-- (sanitizeStorageName in lib/utils/image_utils.dart, storageFolder in
-- web/js/vendor-logic.js). The upload rules compared the folder to the exact
-- name, so vendors with a ' or & in their name couldn't upload. Accept both.

create or replace function public.my_vendor_photo_folders()
returns setof text
language sql
stable
security definer
set search_path = ''
as $$
  select vendor_name from public.vendors where vendor_user_id = auth.uid()
  union
  select btrim(regexp_replace(vendor_name, '[^a-zA-Z0-9 _-]', '_', 'g'))
    from public.vendors where vendor_user_id = auth.uid();
$$;

revoke all on function public.my_vendor_photo_folders() from public, anon;
grant execute on function public.my_vendor_photo_folders() to authenticated;

drop policy if exists "Vendors can upload own photos" on storage.objects;
drop policy if exists "Vendors can update own photos" on storage.objects;
drop policy if exists "Vendors can delete own photos" on storage.objects;

create policy "Vendors can upload own photos" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'vendor-photos'
    and (storage.foldername(name))[1] in (select public.my_vendor_photo_folders())
  );

create policy "Vendors can update own photos" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'vendor-photos'
    and (storage.foldername(name))[1] in (select public.my_vendor_photo_folders())
  );

create policy "Vendors can delete own photos" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'vendor-photos'
    and (storage.foldername(name))[1] in (select public.my_vendor_photo_folders())
  );
