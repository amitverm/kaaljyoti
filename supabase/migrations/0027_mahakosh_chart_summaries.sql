-- ============================================================================
-- 0027 — mahakosh_chart_summaries: yoga + life-event counts for list rows
-- ============================================================================
-- The Mahakosh list shows "3 yogas · 1 events" per row, but those counts
-- are NOT columns on mahakosh_charts — only the combination-search edge
-- function ever computed them, as scalar subqueries. Every other path
-- (browse, bookmarks) did a plain select, so the keys were simply absent
-- and the client's `?? 0` turned that into a silent zero. A chart with a
-- recorded life event showed no event count anywhere but in search.
--
-- A view rather than PostgREST's embedded `life_events(count)` aggregate:
-- that syntax needs db-aggregates-enabled, which is off by default in
-- PostgREST 12+ and is not set in this project's config. A view needs no
-- feature flag and mirrors the SQL combination-search already runs.
--
-- security_invoker so the caller's RLS applies to the base tables — the
-- view must not become a way to read charts the policies would refuse.
-- (Postgres 15; see config.toml db.major_version.)

create or replace view public.mahakosh_chart_summaries
with (security_invoker = true) as
  select
    c.id,
    c.mk_code,
    c.birth_year,
    c.location_general,
    c.ayanamsa_id,
    c.status,
    c.created_at,
    (select count(*)::int from public.chart_yogas cy
      where cy.chart_id = c.id) as yoga_count,
    (select count(*)::int from public.life_events le
      where le.chart_id = c.id) as life_event_count
  from public.mahakosh_charts c;

comment on view public.mahakosh_chart_summaries is
  'Row-level summary of a community chart plus its yoga and life-event counts. Deliberately excludes contributor_id and chart_payload, so it is safe for list queries. security_invoker: RLS on mahakosh_charts / chart_yogas / life_events governs every read.';

grant select on public.mahakosh_chart_summaries to authenticated;
