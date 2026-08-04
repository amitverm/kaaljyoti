-- 0029: How many kundlis has this app ever made? Two numbers, honestly scoped.
--
-- There was no way to answer "how many kundlis exist" without opening the
-- SQL editor and counting rows — and even that only ever answered "how many
-- are on the server RIGHT NOW". A chart deleted, or un-synced, or belonging
-- to a deleted account, vanishes from that count as if it had never been
-- made. This migration adds the missing creation date and a tiny registry
-- that remembers the total, then exposes both to admins through one RPC.
--
-- SCOPE, stated plainly: these numbers cover kundlis whose owner signed in
-- AND switched sync on. A kundli made on a device that never signs in never
-- reaches the server and is invisible here — by design. There is no
-- telemetry in this app and this migration does not add any; it only counts
-- what users have already chosen to store with us.
--
-- ============================================================================
-- 1. synced_kundlis.created_at — the date the server could not read
-- ============================================================================
-- The kundli's true creation date already travels to the server on every
-- push — sealed inside payload_encrypted, which is an opaque blob the server
-- cannot read. Lifting the date into its own column is what makes it
-- queryable at all.
--
-- The value is CLIENT-supplied: the local Kundli model's immutable createdAt
-- (lib/data/models.dart), sent by pushAll on every push. Note what is
-- deliberately absent: no trigger freezes this column the way
-- trg_synced_kundlis_touch owns updated_at. Freezing it would be wrong here.
-- Every push re-sends the SAME immutable value, so updates cost nothing —
-- and letting them through is precisely how the backfilled estimates below
-- converge on the truth, as each existing row gets pushed by a new client.
-- ============================================================================

alter table public.synced_kundlis
  add column if not exists created_at timestamptz;

-- Backfill is an ESTIMATE and should be read as one. updated_at is
-- last-write time, not creation time — but it is the only date signal an
-- already-stored row carries. Each of these rows corrects itself the first
-- time its device pushes from a build that sends the real created_at.
update public.synced_kundlis
  set created_at = updated_at
  where created_at is null;

alter table public.synced_kundlis
  alter column created_at set not null,
  alter column created_at set default now();

comment on column public.synced_kundlis.created_at is
  'When the kundli was created ON THE DEVICE — client-supplied on every push (the model''s immutable createdAt), NOT server-stamped. Rows predating 0029 were backfilled from updated_at as an estimate and converge on the true date once pushed by a current client.';

-- ============================================================================
-- 2. kundli_registry — the number that survives deletion
-- ============================================================================
-- "Currently synced" is a live count and always will be; counting rows in
-- synced_kundlis answers it. "Ever created" cannot be answered that way,
-- because the row is gone: toggling sync off HARD-deletes it (removeRemote),
-- and deleting the account cascades the whole lot away.
--
-- So the registry holds bare chart UUIDs ONLY — deliberately NO user_id and
-- NO foreign key. That is not an oversight, it is the entire design: the row
-- must survive sync-off hard-deletes and account-deletion cascades, and
-- holding nothing but an opaque UUID is exactly what makes that retention
-- acceptable. A leftover uuid identifies no person, no chart, and no birth
-- data; it is a tally mark. A user_id or an FK would make it a record of a
-- user we promised to forget.
-- ============================================================================

create table public.kundli_registry (
  id         uuid primary key,
  first_seen timestamptz not null default now()
);

comment on table public.kundli_registry is
  'Tally marks: one bare chart UUID per kundli ever synced. No user_id, no FK — the row must outlive sync-off deletes and account-deletion cascades, and holding nothing but an opaque uuid is what makes keeping it acceptable.';

alter table public.kundli_registry enable row level security;
-- Deliberately NO policies — same default-deny pattern as public.admins in
-- 0008: RLS enabled + zero policies means 'authenticated' gets nothing at
-- all. Only the service role bypasses RLS, and the count reaches admins
-- solely through the SECURITY DEFINER RPC below.

create or replace function public.register_kundli()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.kundli_registry (id, first_seen)
    values (new.id, coalesce(new.created_at, now()))
    on conflict (id) do nothing;
  return new;
end;
$$;

comment on function public.register_kundli() is
  'AFTER INSERT trigger on synced_kundlis: records the chart id in kundli_registry, once, forever.';

-- AFTER INSERT only, and on conflict do nothing — two separate guards for
-- two separate ways of double-counting:
--   * INSERT only: pushAll upserts on every push. An upsert that lands on
--     the conflict-UPDATE path is a re-push of a kundli we already know
--     about and must not fire this at all.
--   * do nothing: since 0022 the table is keyed by (id, user_id), so the
--     same chart id synced by two accounts is genuinely two rows and two
--     inserts. It is still one kundli, and it registers once.
create trigger trg_synced_kundlis_register
  after insert on public.synced_kundlis
  for each row execute function public.register_kundli();

-- Seed the registry with everything already stored. Charts deleted before
-- today are simply lost to the count — nothing recorded them at the time.
insert into public.kundli_registry (id, first_seen)
  select id, created_at from public.synced_kundlis
  on conflict (id) do nothing;

-- ============================================================================
-- 3. kundli_stats() — the two numbers, admin-gated
-- ============================================================================

create or replace function public.kundli_stats()
returns json
language plpgsql
security definer
set search_path = public
stable
as $$
begin
  if not public.is_admin() then
    raise exception 'admin required';
  end if;

  return json_build_object(
    'total_created', (select count(*) from public.kundli_registry),
    'current_synced', (select count(distinct id)
                         from public.synced_kundlis
                         where deleted_at is null)
  );
end;
$$;

comment on function public.kundli_stats() is
  'Admin-only kundli counts. total_created = every kundli ever synced, including ones since deleted or un-synced (kundli_registry). current_synced = distinct chart ids live on the server right now, tombstones excluded — distinct because 0022 lets two accounts each hold a row for the same chart. Both cover only kundlis whose owners enabled sync; local-only charts never reach the server. The is_admin() check inside is the security boundary — the function is SECURITY DEFINER over two default-deny tables, so it must gate itself.';

grant execute on function public.kundli_stats() to authenticated;
