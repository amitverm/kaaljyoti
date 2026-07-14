-- ============================================================================
-- Kaal Jyoti — initial schema (Mahakosh + personal sync + research engine)
-- ============================================================================
-- Design notes
-- ------------
-- * Mahakosh is a consent-governed community repository of contributed,
--   ANONYMIZED kundalis. Charts never carry names or exact birth data:
--   birth_year is generalized (year only) and location_general is a coarse
--   region string ("North India"), never coordinates or a town.
-- * Postgres (not a document store) because combination search needs
--   multi-condition relational queries and joins:
--     mahakosh_charts -> chart_index / chart_yogas / life_events
--                     -> research_requests -> request_matches
--                     -> consent_records.
-- * Row-Level Security enforces consent/visibility at the DB layer.
--   The app is the only client (no public API, no bulk export); edge
--   functions use the service role and re-apply visibility rules in SQL.
-- * Consent invariant: an ACTIVE mahakosh chart must always have at least
--   one non-revoked consent record. The client inserts the chart and its
--   consent rows IN THE SAME TRANSACTION; a deferred constraint trigger
--   verifies the invariant at COMMIT time (see trg_chart_requires_consent).
-- ============================================================================

-- gen_random_uuid() is built in on Postgres 13+; pgcrypto kept for safety on
-- hosted projects where extensions live in the "extensions" schema.
create extension if not exists pgcrypto with schema extensions;

-- ============================================================================
-- 1. profiles — thin public profile over auth.users
-- ============================================================================
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at   timestamptz not null default now()
);

comment on table public.profiles is
  'Public-facing profile row per auth user. Display name only; no PII beyond what the user chooses to show.';

-- ============================================================================
-- 2. synced_kundlis — opt-in cross-device sync of PERSONAL kundlis
-- ============================================================================
-- The payload is encrypted CLIENT-SIDE before upload; the server only ever
-- stores an opaque blob. Strict owner-only RLS: nobody but the owner (and
-- the service role) can even see that a row exists.
create table public.synced_kundlis (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users (id) on delete cascade,
  payload_encrypted text not null,            -- client-side encrypted blob (opaque to the server)
  updated_at        timestamptz not null default now()
);

create index idx_synced_kundlis_user on public.synced_kundlis (user_id);

-- Keep updated_at server-authoritative (used for last-write-wins sync).
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_synced_kundlis_touch
  before update on public.synced_kundlis
  for each row execute function public.touch_updated_at();

-- ============================================================================
-- 3. mahakosh_charts — contributed anonymized charts
-- ============================================================================
create sequence public.mahakosh_mk_code_seq start with 1001;

create table public.mahakosh_charts (
  id               uuid primary key default gen_random_uuid(),
  mk_code          text unique,                 -- 'MK-4831', assigned by trigger below
  contributor_id   uuid not null references auth.users (id) on delete restrict,
  is_own           boolean not null default true,   -- own chart vs. third-party (relative etc.)
  notify_on_match  boolean not null default false,  -- contributor opted in to "your chart matched" notifications
  birth_year       int,                         -- generalized: year only, never full date/time
  location_general text,                        -- generalized region, never exact place
  ayanamsa_id      int,                         -- which ayanamsa the payload was computed with
  chart_payload    jsonb not null,              -- planet longitudes, ascendant, nakshatras —
                                                -- NO name, NO exact birth data (client strips before upload)
  status           text not null default 'active'
                     check (status in ('active', 'withdrawn')),
  created_at       timestamptz not null default now(),
  withdrawn_at     timestamptz
);

create index idx_mahakosh_charts_status      on public.mahakosh_charts (status);
create index idx_mahakosh_charts_contributor on public.mahakosh_charts (contributor_id);

-- --- mk_code generation -----------------------------------------------------
create or replace function public.assign_mk_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.mk_code is null then
    new.mk_code := 'MK-' || nextval('public.mahakosh_mk_code_seq');
  end if;
  return new;
end;
$$;

create trigger trg_mahakosh_charts_mk_code
  before insert on public.mahakosh_charts
  for each row execute function public.assign_mk_code();

-- --- consent invariant (checked at COMMIT, so chart + consent rows can be
-- --- inserted in the same transaction in any order) --------------------------
create or replace function public.enforce_chart_has_consent()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'active' and not exists (
    select 1
    from public.consent_records cr
    where cr.chart_id = new.id
      and cr.revoked_at is null
  ) then
    raise exception
      'mahakosh chart % cannot be active without at least one non-revoked consent record', new.id
      using errcode = '23514';
  end if;
  return new;
end;
$$;

-- (created after consent_records below — see trg_chart_requires_consent)

-- --- restrict contributor updates to "withdraw / notification toggle" -------
-- RLS grants the contributor UPDATE, but the only legitimate self-service
-- updates are withdrawing the chart and toggling notify_on_match. Everything
-- else (payload, generalized fields, ownership) is immutable after
-- contribution; only the service role may touch it (moderation/tooling).
create or replace function public.restrict_chart_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Service-role / direct-DB (postgres) callers bypass the restriction.
  if coalesce(auth.jwt() ->> 'role', '') = 'service_role' or auth.uid() is null then
    return new;
  end if;

  if new.contributor_id   is distinct from old.contributor_id
     or new.mk_code          is distinct from old.mk_code
     or new.is_own           is distinct from old.is_own
     or new.birth_year       is distinct from old.birth_year
     or new.location_general is distinct from old.location_general
     or new.ayanamsa_id      is distinct from old.ayanamsa_id
     or new.chart_payload    is distinct from old.chart_payload
     or new.created_at       is distinct from old.created_at
  then
    raise exception 'only status (withdraw) and notify_on_match may be changed by the contributor';
  end if;

  -- Withdrawal is one-way for contributors.
  if old.status = 'withdrawn' and new.status = 'active' then
    raise exception 'a withdrawn chart cannot be re-activated; contribute it again instead';
  end if;

  if new.status = 'withdrawn' and old.status = 'active' then
    new.withdrawn_at := now();
  end if;

  return new;
end;
$$;

create trigger trg_mahakosh_charts_restrict_update
  before update on public.mahakosh_charts
  for each row execute function public.restrict_chart_update();

-- ============================================================================
-- 4. chart_index / chart_yogas — precomputed search index
-- ============================================================================
-- Written by the client at contribution time (same transaction as the chart).
-- One row per planet per chart; this is what combination search queries, so
-- searches never have to open chart_payload jsonb.
create table public.chart_index (
  chart_id  uuid not null references public.mahakosh_charts (id) on delete cascade,
  planet    text not null,                       -- 'Sun', 'Moon', ..., 'Rahu', 'Ketu', 'Ascendant'
  sign      int  not null check (sign between 0 and 11),      -- 0 = Aries ... 11 = Pisces
  house     int  not null check (house between 1 and 12),
  nakshatra int  not null check (nakshatra between 0 and 26), -- 0 = Ashwini ... 26 = Revati
  pada      int  not null check (pada between 1 and 4),
  primary key (chart_id, planet)
);

create index idx_chart_index_planet_sign      on public.chart_index (planet, sign);
create index idx_chart_index_planet_house     on public.chart_index (planet, house);
create index idx_chart_index_planet_nakshatra on public.chart_index (planet, nakshatra);

-- Yoga presence flags (e.g. 'gajakesari', 'neecha_bhanga') for yoga filters.
create table public.chart_yogas (
  chart_id  uuid not null references public.mahakosh_charts (id) on delete cascade,
  yoga_code text not null,
  primary key (chart_id, yoga_code)
);

create index idx_chart_yogas_yoga on public.chart_yogas (yoga_code);

-- ============================================================================
-- 5. life_events — tagged life events attached to a contributed chart
-- ============================================================================
create table public.life_events (
  id                uuid primary key default gen_random_uuid(),
  chart_id          uuid not null references public.mahakosh_charts (id) on delete cascade,
  tag               text not null,               -- e.g. 'marriage', 'job_change', 'surgery'
  event_date        date,                        -- month/day precision is contributor's choice
  is_health_related boolean not null default false,
  note              text,
  created_at        timestamptz not null default now()
);

create index idx_life_events_tag   on public.life_events (tag);
create index idx_life_events_chart on public.life_events (chart_id);

-- ============================================================================
-- 6. consent_records — the consent ledger per chart
-- ============================================================================
-- kind:
--   'self'        — contributor consents to sharing their own chart
--   'third_party' — contributor attests they may share someone else's chart
--   'health'      — extra consent required before any health-related life event
-- text_version pins the exact consent text the user agreed to.
create table public.consent_records (
  id           uuid primary key default gen_random_uuid(),
  chart_id     uuid not null references public.mahakosh_charts (id) on delete cascade,
  kind         text not null check (kind in ('self', 'third_party', 'health')),
  text_version text not null,
  granted_at   timestamptz not null default now(),
  revoked_at   timestamptz                        -- null = still in force
);

create index idx_consent_records_chart on public.consent_records (chart_id);

-- Now that consent_records exists, attach the deferred consent invariant.
-- DEFERRABLE INITIALLY DEFERRED => evaluated at COMMIT, so the client can
-- insert chart + index + consents in one transaction in any order.
create constraint trigger trg_chart_requires_consent
  after insert or update of status on public.mahakosh_charts
  deferrable initially deferred
  for each row execute function public.enforce_chart_has_consent();

-- --- health-event gate -------------------------------------------------------
-- A life event flagged health-related may only exist while a non-revoked
-- 'health' consent record exists for that chart.
-- (Note: revoking health consent later does not auto-delete existing health
-- events; the client's "revoke health consent" flow deletes them explicitly.)
create or replace function public.enforce_health_consent()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_health_related and not exists (
    select 1
    from public.consent_records cr
    where cr.chart_id = new.chart_id
      and cr.kind = 'health'
      and cr.revoked_at is null
  ) then
    raise exception
      'health-related life events require a non-revoked ''health'' consent record for chart %', new.chart_id
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger trg_life_events_health_consent
  before insert or update on public.life_events
  for each row execute function public.enforce_health_consent();

-- ============================================================================
-- 7. research_requests — community research questions (moderated)
-- ============================================================================
-- criteria is a structured filter tree — the SAME shape the combination-search
-- edge function accepts, e.g.:
--   { "op": "AND", "children": [
--       { "type": "planet_in_house", "planet": "Saturn", "house": 7 },
--       { "type": "life_event", "tag": "divorce" } ] }
-- New requests always start in 'pending_review' (light moderation queue to
-- catch de-anonymization attempts, e.g. absurdly narrow criteria) and only
-- become searchable/matchable once a moderator sets them 'live'.
create table public.research_requests (
  id           uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users (id) on delete cascade,
  title        text not null,
  description  text,
  criteria     jsonb not null,
  status       text not null default 'pending_review'
                 check (status in ('pending_review', 'live', 'rejected', 'closed')),
  created_at   timestamptz not null default now(),
  reviewed_at  timestamptz,
  review_note  text
);

create index idx_research_requests_status    on public.research_requests (status);
create index idx_research_requests_requester on public.research_requests (requester_id);

-- ============================================================================
-- 8. request_matches — charts matched to research requests
-- ============================================================================
create table public.request_matches (
  id         uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.research_requests (id) on delete cascade,
  chart_id   uuid not null references public.mahakosh_charts (id) on delete cascade,
  source     text not null check (source in ('auto', 'manual')),
  matched_by uuid references auth.users (id),   -- who tagged it, for manual matches
  created_at timestamptz not null default now(),
  unique (request_id, chart_id)
);

create index idx_request_matches_request on public.request_matches (request_id);
create index idx_request_matches_chart   on public.request_matches (chart_id);

-- ============================================================================
-- 9. notifications — in-app notification inbox
-- ============================================================================
-- type examples: 'request_match_new', 'your_chart_matched',
--                'request_approved', 'request_rejected'
-- Rows are inserted by edge functions (service role) only.
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  type       text not null,
  payload    jsonb not null default '{}'::jsonb,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_user_read on public.notifications (user_id, read);

-- ============================================================================
-- 10. Row-Level Security
-- ============================================================================
-- The service role bypasses RLS entirely (Supabase default); everything below
-- governs what signed-in app users (role 'authenticated') can do. The anon
-- role gets nothing.
alter table public.profiles          enable row level security;
alter table public.synced_kundlis    enable row level security;
alter table public.mahakosh_charts   enable row level security;
alter table public.chart_index       enable row level security;
alter table public.chart_yogas       enable row level security;
alter table public.life_events       enable row level security;
alter table public.consent_records   enable row level security;
alter table public.research_requests enable row level security;
alter table public.request_matches   enable row level security;
alter table public.notifications     enable row level security;

-- ---------------------------------------------------------------------------
-- profiles: everyone signed in can read display names (shown on research
-- requests); users manage only their own row.
-- ---------------------------------------------------------------------------
create policy profiles_select on public.profiles
  for select to authenticated
  using (true);

create policy profiles_insert_own on public.profiles
  for insert to authenticated
  with check (id = auth.uid());

create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- synced_kundlis: strict owner-only, all operations.
-- ---------------------------------------------------------------------------
create policy synced_kundlis_owner_all on public.synced_kundlis
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- mahakosh_charts:
--   SELECT — any signed-in user sees ACTIVE charts; contributors always see
--            their own (including withdrawn ones).
--   INSERT — contributor only. The client MUST insert the chart, its
--            chart_index/chart_yogas rows and its consent_records in ONE
--            transaction; the deferred trg_chart_requires_consent trigger
--            rejects the commit if an active chart ends up with no
--            non-revoked consent.
--   UPDATE — contributor only, and trg_mahakosh_charts_restrict_update limits
--            it to withdrawing / toggling notify_on_match.
--   Moderation & repair go through the service role (bypasses RLS).
-- ---------------------------------------------------------------------------
create policy mahakosh_charts_select on public.mahakosh_charts
  for select to authenticated
  using (status = 'active' or contributor_id = auth.uid());

create policy mahakosh_charts_insert on public.mahakosh_charts
  for insert to authenticated
  with check (contributor_id = auth.uid());

create policy mahakosh_charts_update on public.mahakosh_charts
  for update to authenticated
  using (contributor_id = auth.uid())
  with check (contributor_id = auth.uid());

-- ---------------------------------------------------------------------------
-- chart_index / chart_yogas / life_events: readable when the parent chart is
-- visible (active, or your own); writable only by the parent contributor
-- (rows are written at contribution time, in the same transaction).
-- ---------------------------------------------------------------------------
create policy chart_index_select on public.chart_index
  for select to authenticated
  using (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id
      and (c.status = 'active' or c.contributor_id = auth.uid())
  ));

create policy chart_index_insert on public.chart_index
  for insert to authenticated
  with check (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ));

create policy chart_yogas_select on public.chart_yogas
  for select to authenticated
  using (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id
      and (c.status = 'active' or c.contributor_id = auth.uid())
  ));

create policy chart_yogas_insert on public.chart_yogas
  for insert to authenticated
  with check (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ));

create policy life_events_select on public.life_events
  for select to authenticated
  using (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id
      and (c.status = 'active' or c.contributor_id = auth.uid())
  ));

create policy life_events_insert on public.life_events
  for insert to authenticated
  with check (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ));

create policy life_events_update on public.life_events
  for update to authenticated
  using (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ));

create policy life_events_delete on public.life_events
  for delete to authenticated
  using (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ));

-- ---------------------------------------------------------------------------
-- consent_records: visible/manageable only by the chart's contributor.
-- "Revoking" is an UPDATE setting revoked_at; rows are never edited otherwise.
-- ---------------------------------------------------------------------------
create policy consent_records_select on public.consent_records
  for select to authenticated
  using (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ));

create policy consent_records_insert on public.consent_records
  for insert to authenticated
  with check (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ));

create policy consent_records_update on public.consent_records
  for update to authenticated
  using (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.mahakosh_charts c
    where c.id = chart_id and c.contributor_id = auth.uid()
  ));

-- ---------------------------------------------------------------------------
-- research_requests:
--   SELECT — live requests are public (in-app); requesters see their own in
--            any status.
--   INSERT — any signed-in user, but status is FORCED to 'pending_review'
--            by the WITH CHECK (moderation queue).
--   UPDATE — no policy for authenticated => moderation transitions
--            (live/rejected/closed) happen only via the service role
--            (moderate-request edge function), which bypasses RLS.
-- ---------------------------------------------------------------------------
create policy research_requests_select on public.research_requests
  for select to authenticated
  using (status = 'live' or requester_id = auth.uid());

create policy research_requests_insert on public.research_requests
  for insert to authenticated
  with check (requester_id = auth.uid() and status = 'pending_review');

-- ---------------------------------------------------------------------------
-- request_matches: readable iff the parent request is visible to the user.
-- Manual tagging: the requester of a live request may hand-tag an ACTIVE
-- chart (source 'manual', matched_by = themselves). Auto matches are written
-- by the request-matching edge function (service role).
-- ---------------------------------------------------------------------------
create policy request_matches_select on public.request_matches
  for select to authenticated
  using (exists (
    select 1 from public.research_requests r
    where r.id = request_id
      and (r.status = 'live' or r.requester_id = auth.uid())
  ));

create policy request_matches_insert_manual on public.request_matches
  for insert to authenticated
  with check (
    source = 'manual'
    and matched_by = auth.uid()
    and exists (
      select 1 from public.research_requests r
      where r.id = request_id
        and r.status = 'live'
        and r.requester_id = auth.uid()
    )
    and exists (
      select 1 from public.mahakosh_charts c
      where c.id = chart_id and c.status = 'active'
    )
  );

-- ---------------------------------------------------------------------------
-- notifications: owner-only read + mark-as-read. Inserted by edge functions
-- (service role) only — no INSERT policy for authenticated.
-- ---------------------------------------------------------------------------
create policy notifications_select_own on public.notifications
  for select to authenticated
  using (user_id = auth.uid());

create policy notifications_update_own on public.notifications
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
