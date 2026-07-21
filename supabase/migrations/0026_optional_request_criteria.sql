-- ============================================================================
-- 0026 — research_requests.criteria becomes optional
-- ============================================================================
-- A requester may not know which combination represents the pattern they
-- want to study — that unknown IS the research question (e.g. "kundlis of
-- organ donors": no established combination to search for). Such requests
-- are posted without criteria: they skip auto-matching entirely and
-- collect charts through manual responses only (_shared/matching.ts
-- treats null criteria as "match nothing automatically").

alter table public.research_requests
  alter column criteria drop not null;
