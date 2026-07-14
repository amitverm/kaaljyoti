-- 0007: "Report to moderators" — the other half of App Store Guideline 1.2.
--
-- §2.7a (0006) gave users a personal, silent filter ("hide from my view").
-- Guideline 1.2 separately requires a way to REPORT objectionable content
-- for moderator review — a report can end with the chart being pulled for
-- EVERYONE, not just hidden for the reporter. That mechanism did not exist
-- anywhere before this migration (research_requests moderation, §2.7,
-- moderates research QUESTIONS users post, not individual contributed
-- charts).
--
-- Reporting a chart also hides it from the reporter's own view immediately
-- (the client calls hide_mahakosh_chart right after this RPC) — a reporter
-- shouldn't have to keep looking at content they just flagged while it's
-- under review. That reuses 0006's hidden_mahakosh_charts table as-is; no
-- schema change needed for that part.

create table public.chart_reports (
  id          uuid primary key default gen_random_uuid(),
  chart_id    uuid not null references public.mahakosh_charts (id) on delete cascade,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason      text not null check (reason in (
                'deanonymization',  -- could identify a real, named person
                'health_privacy',   -- sensitive health info shouldn't be public
                'harassment',       -- harassing, hateful, or abusive content
                'spam',             -- spam or fake/test data
                'other'
              )),
  details     text not null default '',
  status      text not null default 'pending_review'
                check (status in ('pending_review', 'actioned', 'dismissed')),
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz,
  review_note text,
  -- One open report per (user, chart): resubmitting updates the existing
  -- row (see report_mahakosh_chart's ON CONFLICT) instead of piling up
  -- duplicates that would otherwise inflate the moderation queue.
  unique (chart_id, reporter_id)
);

create index idx_chart_reports_status on public.chart_reports (status);
create index idx_chart_reports_chart  on public.chart_reports (chart_id);

comment on table public.chart_reports is
  'User reports of individual Mahakosh charts for moderator review (App Store Guideline 1.2 content reporting). Distinct from hidden_mahakosh_charts (0006): a report can get a chart withdrawn for EVERYONE after review, not just hidden for the reporter.';

alter table public.chart_reports enable row level security;

-- SELECT: reporters see only their own reports (no "my reports" UI in v1,
-- but this keeps the door open without leaking the moderation queue to
-- end users). INSERT: any signed-in user, reporter_id forced to themselves.
-- No UPDATE policy for authenticated — moderation transitions (actioned /
-- dismissed) happen only via the service role (moderate-chart-report edge
-- function), mirroring research_requests' moderation boundary (§2.7).
create policy chart_reports_select_own on public.chart_reports
  for select to authenticated
  using (reporter_id = auth.uid());

create policy chart_reports_insert_own on public.chart_reports
  for insert to authenticated
  with check (reporter_id = auth.uid());

-- ============================================================================
-- report_mahakosh_chart — mk_code-based RPC (same reasoning as
-- hide_mahakosh_chart/unhide_mahakosh_chart in 0006): the client only ever
-- handles mk_code, and SECURITY DEFINER lets a report be filed against a
-- chart that RLS might otherwise hide from the reporter (e.g. they are
-- reporting it via a research-request match after already hiding it once).
-- ============================================================================
create or replace function public.report_mahakosh_chart(
  p_mk_code text,
  p_reason text,
  p_details text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_chart_id uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  if p_reason not in ('deanonymization', 'health_privacy', 'harassment', 'spam', 'other') then
    raise exception 'invalid report reason: %', p_reason;
  end if;

  select id into v_chart_id
    from public.mahakosh_charts
    where mk_code = p_mk_code;

  if v_chart_id is null then
    raise exception 'chart not found';
  end if;

  insert into public.chart_reports (chart_id, reporter_id, reason, details)
    values (v_chart_id, auth.uid(), p_reason, coalesce(p_details, ''))
    on conflict (chart_id, reporter_id) do update
      set reason      = excluded.reason,
          details      = excluded.details,
          status       = 'pending_review',
          created_at   = now(),
          reviewed_at  = null,
          review_note  = null;
end;
$$;

grant execute on function public.report_mahakosh_chart(text, text, text) to authenticated;
