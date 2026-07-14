-- ============================================================================
-- 0023 — make in-app account deletion possible
-- ============================================================================
-- Deletion itself happens in the delete-account edge function (the caller's
-- JWT is verified, then auth.admin.deleteUser). Every user-owned table
-- already cascades from auth.users; two foreign keys would block the
-- delete and are adjusted here:
--
-- 1. mahakosh_charts.contributor_id (NOT NULL + ON DELETE RESTRICT).
--    Contributed charts are anonymized research data and — per the
--    published deletion policy — stay in the pool unless the user asks
--    for withdrawal. The edge function DETACHES them first
--    (contributor_id := null, notify_on_match := false), so the column
--    must be nullable. The FK keeps ON DELETE RESTRICT deliberately:
--    deleting a user who still has attached charts should stay
--    impossible — the detach step is a required part of the flow.
--
-- 2. request_matches.matched_by (bare FK = NO ACTION) records which
--    admin manually tagged a match. Attribution must never block that
--    admin's own account deletion → ON DELETE SET NULL.

alter table public.mahakosh_charts
  alter column contributor_id drop not null;

comment on column public.mahakosh_charts.contributor_id is
  'Contributing user; NULL after the contributor deleted their account (chart stays in the research pool, fully anonymized, unless withdrawn).';

alter table public.request_matches
  drop constraint request_matches_matched_by_fkey;

alter table public.request_matches
  add constraint request_matches_matched_by_fkey
  foreign key (matched_by) references auth.users (id) on delete set null;
