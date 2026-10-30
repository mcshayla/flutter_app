-- The public /vendors/ pages are static HTML built on each Amplify deploy.
-- Vendor changes mark a rebuild as pending; a cron job fires the Amplify
-- incoming webhook (URL kept in Vault as 'amplify_rebuild_webhook') at most
-- once every 5 minutes, so a burst of edits starts one build.
--
-- Store the webhook URL separately (never commit it):
--   select vault.create_secret('<webhook url>', 'amplify_rebuild_webhook');
create extension if not exists pg_net;
create extension if not exists pg_cron;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.site_rebuild (
  id boolean primary key default true check (id),
  pending boolean not null default false,
  requested_at timestamptz,
  last_fired_at timestamptz
);
insert into private.site_rebuild (id) values (true) on conflict do nothing;

create or replace function private.mark_site_rebuild()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Only changes that can alter a public page: rows listed before or after.
  if (tg_op = 'DELETE' and old.is_listed)
     or (tg_op = 'INSERT' and new.is_listed)
     or (tg_op = 'UPDATE' and (old.is_listed or new.is_listed)
         and to_jsonb(old) - 'bookings_count' is distinct from to_jsonb(new) - 'bookings_count') then
    update private.site_rebuild set pending = true, requested_at = now() where id;
  end if;
  return null;
end;
$$;

drop trigger if exists vendors_mark_site_rebuild on public.vendors;
create trigger vendors_mark_site_rebuild
  after insert or update or delete on public.vendors
  for each row execute function private.mark_site_rebuild();

create or replace function private.fire_site_rebuild()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  hook text;
begin
  if not exists (select 1 from private.site_rebuild where id and pending) then
    return;
  end if;
  select decrypted_secret into hook from vault.decrypted_secrets where name = 'amplify_rebuild_webhook';
  if hook is null then
    return;
  end if;
  perform net.http_post(url := hook, body := '{}'::jsonb, headers := '{"Content-Type":"application/json"}'::jsonb);
  update private.site_rebuild set pending = false, last_fired_at = now() where id;
end;
$$;

revoke all on function private.mark_site_rebuild() from public, anon, authenticated;
revoke all on function private.fire_site_rebuild() from public, anon, authenticated;

select cron.unschedule(jobid) from cron.job where jobname = 'fire-site-rebuild';
select cron.schedule('fire-site-rebuild', '*/5 * * * *', 'select private.fire_site_rebuild()');
