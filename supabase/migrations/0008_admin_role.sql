-- 0008: Admin role + in-app moderation.
--
-- v1's design boundary said "no in-app moderator role" — moderation was
-- meant to happen via ops tooling holding the service-role key or
-- INTERNAL_TOKEN, i.e. leaving the Supabase dashboard open and curling
-- edge functions by hand. This migration adds a real admin role so
-- moderation can happen from inside the app itself, WITHOUT ever putting
-- the service-role key in the client.
--
-- Security model:
--   * admins is an allowlist table with NO policies granting
--     'authenticated' any access at all — RLS enabled + zero policies =
--     default deny. It can only be read/written by the service role
--     (you, via the SQL editor or `supabase db execute`). There is no
--     self-serve path to becoming an admin.
--   * is_admin() is SECURITY DEFINER so it can read that otherwise
--     unreadable table on the caller's behalf, but it only ever answers
--     for auth.uid() — it can't be used to enumerate admins or check
--     someone else's status.
--   * The app never holds the service-role key. Moderation edge functions
--     (requireInternalOrAdmin in _shared/edge.ts) accept the caller's OWN
--     JWT and call is_admin() themselves before doing anything privileged
--     — the admin check happens server-side, never in the client. A
--     non-admin calling the same function gets a 403; holding a valid JWT
--     proves nothing without also being on the allowlist.
--
-- To make someone an admin, run (as yourself, via the SQL editor):
--   insert into public.admins (user_id)
--     select id from auth.users where email = 'you@example.com';

create table public.admins (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

comment on table public.admins is
  'Allowlist of admin users. No RLS policies for "authenticated" — only the service role (you, via SQL) can read or write this table. See the migration header for how to add one.';

alter table public.admins enable row level security;
-- Deliberately NO policies here: RLS enabled + zero policies means
-- 'authenticated' gets nothing at all. Only the service role bypasses RLS.

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.admins where user_id = auth.uid()
  );
$$;

comment on function public.is_admin() is
  'Whether the CALLING user (auth.uid()) is an admin. Safe to grant to authenticated: it only ever answers for the caller, never enumerates admins.';

grant execute on function public.is_admin() to authenticated;

-- ============================================================================
-- Let admins see the moderation queues directly via ordinary RLS-governed
-- reads — no extra RPC needed for listing. Scoped as tightly as possible:
-- only pending_review rows, never other users' already-resolved history.
-- ============================================================================
drop policy if exists research_requests_select on public.research_requests;
create policy research_requests_select on public.research_requests
  for select to authenticated
  using (
    status = 'live'
    or requester_id = auth.uid()
    or (status = 'pending_review' and public.is_admin())
  );

drop policy if exists chart_reports_select_own on public.chart_reports;
create policy chart_reports_select_own on public.chart_reports
  for select to authenticated
  using (
    reporter_id = auth.uid()
    or (status = 'pending_review' and public.is_admin())
  );

-- Admins reviewing a report need to see the reported chart itself
-- (mk_code, birth year, location) regardless of its status or whether the
-- admin has personally hidden it via §2.7a — moderation should never be
-- blocked by the reviewer's own "hide from my view" list.
drop policy if exists mahakosh_charts_select on public.mahakosh_charts;
create policy mahakosh_charts_select on public.mahakosh_charts
  for select to authenticated
  using (
    public.is_admin()
    or (
      (status = 'active' or contributor_id = auth.uid())
      and not exists (
        select 1 from public.hidden_mahakosh_charts h
        where h.chart_id = mahakosh_charts.id and h.user_id = auth.uid()
      )
    )
  );
