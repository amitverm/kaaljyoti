-- 0030: How many devices, how many kundlis — counted without knowing who.
--
-- 0029 answered "how many kundlis exist" only for the SYNCED subset: a
-- chart made on a phone that never signs in never reaches the server and
-- is invisible there. That is most of them. This migration adds the one
-- thing that can see the rest — a per-install ping carrying three
-- numbers — and folds both views into a single admin RPC.
--
-- THE ANONYMITY CONTRACT, stated plainly and meant literally:
--   * install_id is a RANDOM uuid v4 minted ON THE DEVICE on first ping
--     and kept in SharedPreferences. It is derived from NOTHING — no
--     hardware identifier, no advertising id, no account, no email, no
--     hash of any of those. It is a coin flip that happens to be 128
--     bits long, and it is the only identity in this table.
--   * The table stores NO user_id, NO IP address, NO platform, NO app
--     version, NO locale, NO timezone, NO device model. One row per
--     install: three numbers and two timestamps. There is nothing here
--     to correlate with anything, because there is nothing here.
--   * Deleting the app orphans the row — nothing tells the server the
--     install is gone, and a reinstall mints a NEW random install_id and
--     starts a new row. That is accepted, not overlooked: the only way
--     to recognise a returning device would be to derive the id from
--     something durable about the device or the user, which is exactly
--     what this design refuses to do. The cost is that devices_total
--     drifts upward over time and long-dead installs linger until they
--     fall out of the 30-day window.
--
-- SCOPE, equally plainly:
--   * Only devices that come online at least once ever appear. A phone
--     used entirely offline is uncounted, forever.
--   * A kundli synced to N devices is counted by EACH of them, because
--     each device honestly reports what it holds and no device knows
--     what the others hold. So the device-summed totals below are an
--     UPPER-BOUND APPROXIMATION, not a count of distinct kundlis.
--   * The synced_* numbers from 0029's registry stay exact — for the
--     synced subset only. The two pairs answer different questions and
--     the admin screen shows both rather than pretending either is the
--     whole truth.
--   * "How many kundlis exist right now" gets TWO answers on purpose.
--     kundlis_current sums every device's last report, however old —
--     optimistic, because a phone last heard from in March is still
--     credited with the charts it held in March. kundlis_current_active_30d
--     sums only devices seen this month — conservative, because a device
--     that fell silent is treated as contributing nothing rather than as
--     frozen in time. The truth is between them; neither is worth
--     rounding away.
--
-- TIMING, now that pings are event-triggered as well as daily: a ping
-- fires shortly after a kundli is created or deleted (debounced), so
-- last_seen may coincide with the moment a chart was made or removed on
-- some anonymous install. That is a real, documented cost and it was
-- accepted deliberately — it buys counts that are current within a
-- minute instead of within a day. Nothing else changes: the payload is
-- byte-for-byte what it always was, there is still no identity beyond a
-- self-minted random uuid, still nothing about any chart, and still one
-- row per install rather than a row per event. What a reader of this
-- table can infer is "this random uuid did something at 14:02", of a
-- device it cannot connect to a person, an account, or another device.
--
-- ============================================================================
-- 1. device_pings — one row per install
-- ============================================================================

create table public.device_pings (
  install_id            uuid primary key,
  first_seen            timestamptz not null default now(),
  last_seen             timestamptz not null default now(),
  kundlis_created_total integer     not null,
  kundlis_current       integer     not null,
  -- Bounds, not business rules: a real device holds tens of charts, not
  -- millions. These exist so a buggy or hostile client cannot push a
  -- number that swamps the sums (see the anon-grant note below).
  constraint device_pings_created_total_range
    check (kundlis_created_total between 0 and 1000000),
  constraint device_pings_current_range
    check (kundlis_current between 0 and 1000000)
);

comment on table public.device_pings is
  'One row per app install, written by record_device_ping(). install_id is a RANDOM uuid minted on the device and derived from nothing — no hardware id, no account. No user_id, no IP, no platform, no version is stored. Deleting the app orphans the row; a reinstall is a new install_id. Device-summed kundli counts are an upper bound (a chart synced to N devices is reported by each).';

alter table public.device_pings enable row level security;
-- Deliberately NO policies — the same default-deny shape as public.admins
-- (0008) and public.kundli_registry (0029): RLS on with zero policies
-- means anon and authenticated can neither read nor write this table
-- directly. Everything in and out goes through the two SECURITY DEFINER
-- functions below, which is what makes a write-only-by-RPC, read-only-by-
-- admin table possible at all.

-- ============================================================================
-- 2. record_device_ping — the write path, and the only one
-- ============================================================================

create or replace function public.record_device_ping(
  p_install_id     uuid,
  p_created_total  integer,
  p_current        integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_install_id is null then
    raise exception 'install_id required';
  end if;
  if p_created_total is null or p_created_total < 0
     or p_created_total > 1000000 then
    raise exception 'created_total out of range';
  end if;
  if p_current is null or p_current < 0 or p_current > 1000000 then
    raise exception 'current out of range';
  end if;

  insert into public.device_pings (
    install_id, first_seen, last_seen, kundlis_created_total, kundlis_current
  )
  values (p_install_id, now(), now(), p_created_total, p_current)
  on conflict (install_id) do update set
    last_seen             = now(),
    -- greatest(), not assignment: "created ever" is MONOTONIC on a device
    -- and must never shrink. A phone restored from an old backup, or a
    -- user downgraded to a build with a smaller local counter, would
    -- otherwise silently erase creations we already know happened.
    kundlis_created_total = greatest(device_pings.kundlis_created_total,
                                     excluded.kundlis_created_total),
    -- "current" is the opposite: it is a live figure and deletions are
    -- real, so the newest report simply wins.
    kundlis_current       = excluded.kundlis_current;
end;
$$;

comment on function public.record_device_ping(uuid, integer, integer) is
  'Upserts one install''s ping. created_total is monotonic (greatest); current is overwritten. Granted to anon on purpose: the ping must work signed-out or it undercounts exactly the local-only users it exists to see.';

-- anon, not just authenticated, and that is the whole point: the users
-- this ping exists to count are the ones who never sign in. Gating it
-- behind a session would leave us re-counting the synced subset 0029
-- already counts exactly.
--
-- ACCEPTED RISK, on the record: the anon key ships inside the app, so
-- anyone can extract it and write junk rows. The bounds checks cap what
-- a single row can claim, the uuid primary key caps a single caller to
-- one row per uuid it bothers to invent, and the table holds nothing
-- worth stealing (see the anonymity contract above). These numbers are
-- informational — nothing is billed, gated, or decided by them — so
-- inflating them buys an attacker a wrong number on an admin screen and
-- nothing else. That is a fair trade for counting the offline majority.
grant execute on function public.record_device_ping(uuid, integer, integer)
  to anon, authenticated;

-- ============================================================================
-- 3. app_stats() — seven numbers, admin-gated
-- ============================================================================
-- Absorbs 0029's kundli_stats(). Dropping rather than keeping both is
-- safe: 0029 has never been applied to any database, so kundli_stats()
-- has no live caller anywhere, and the client moved to app_stats() in
-- the same change.

drop function if exists public.kundli_stats();

create or replace function public.app_stats()
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
    'devices_total',
      (select count(*) from public.device_pings),
    'devices_active_30d',
      (select count(*) from public.device_pings
         where last_seen > now() - interval '30 days'),
    'kundlis_created_total',
      (select coalesce(sum(kundlis_created_total), 0) from public.device_pings),
    'kundlis_current',
      (select coalesce(sum(kundlis_current), 0) from public.device_pings),
    -- The conservative twin of the line above. Same sum, restricted to
    -- devices seen inside the same 30-day window devices_active_30d
    -- uses, so a dormant install stops contributing a stale figure
    -- instead of holding it forever.
    'kundlis_current_active_30d',
      (select coalesce(sum(kundlis_current), 0) from public.device_pings
         where last_seen > now() - interval '30 days'),
    'synced_created_total',
      (select count(*) from public.kundli_registry),
    'synced_current',
      (select count(distinct id) from public.synced_kundlis
         where deleted_at is null)
  );
end;
$$;

comment on function public.app_stats() is
  'Admin-only app counts, seven numbers from two independent sources. devices_total = installs that have ever pinged (a reinstall counts again; an uninstall never stops counting). devices_active_30d = installs seen in the last 30 days — the closest honest reading of "in use". kundlis_created_total / kundlis_current = sums across all reporting devices, synced or not, and therefore an UPPER BOUND: a chart synced to N devices is reported by each of them. kundlis_current and kundlis_current_active_30d are the OPTIMISTIC and CONSERVATIVE reads of the same question: the first sums every device as last reported however long ago, so a device silent since March still counts its March charts; the second sums only devices seen in the last 30 days, so a dormant install contributes nothing rather than a frozen figure. Read them as a range, not as a headline and a footnote. synced_created_total / synced_current come from 0029''s registry and are EXACT, but cover only kundlis whose owner signed in and enabled sync. Absorbs kundli_stats() from 0029, which was never deployed and had no caller. The is_admin() check inside is the security boundary — SECURITY DEFINER over three default-deny tables must gate itself.';

grant execute on function public.app_stats() to authenticated;
