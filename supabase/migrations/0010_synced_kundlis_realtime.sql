-- 0010: Realtime for cross-device kundli sync.
--
-- The app subscribes to public.synced_kundlis (filtered to the current
-- user) so a kundli synced on one device appears on the others live,
-- without a manual "Sync now". Postgres change events are only delivered
-- for tables in the supabase_realtime publication, so add it here.
-- Owner-only RLS (0001) still governs which rows a client may see, and
-- the client also filters by user_id.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'synced_kundlis'
  ) then
    alter publication supabase_realtime add table public.synced_kundlis;
  end if;
end $$;
