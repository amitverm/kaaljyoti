-- 0018: Report-threshold auto-hold for discussion comments.
--
-- A comment that collects pending reports from >= 2 DISTINCT users is
-- automatically HELD: hidden from everyone except its author (who sees
-- a "held for review" placeholder on their own comment) until a
-- moderator decides. Community-signal based — no content analysis, so
-- it works identically for Hindi/Hinglish/English and has no
-- false-positive keyword problem. Strengthens the Guideline 1.2 story:
-- objectionable content is suppressed automatically while review is
-- pending, independent of moderator response time.
--
-- Lifecycle additions:
--   visible --2nd distinct report--> held   (body KEPT — restorable)
--   held    --moderator 'remove'---> removed (body wiped, as before)
--   held    --last pending report dismissed--> visible  (restored)
--
-- Privacy note: held rows keep their body server-side (restore must be
-- possible), so the SELECT policy hides held rows from other users
-- outright rather than trusting clients to render a placeholder —
-- the body must not be fetchable by the public while under review.
-- Replies quoting a held comment render "original comment unavailable".

-- 1. Allow the new status. The body check must also permit held rows
--    to keep their text (same shape as 'visible').
alter table public.chart_comments
  drop constraint chart_comments_status_check;
alter table public.chart_comments
  add constraint chart_comments_status_check
    check (status in ('visible', 'held', 'deleted', 'removed'));

-- The 0016 body/status CASE check references two columns, so Postgres
-- auto-named it chart_comments_check; drop under either name and
-- recreate explicitly named.
alter table public.chart_comments
  drop constraint if exists chart_comments_check;
alter table public.chart_comments
  drop constraint if exists chart_comments_body_check;
alter table public.chart_comments
  add constraint chart_comments_body_check
    check (
      case when status in ('visible', 'held')
        then char_length(body) between 1 and 2000
        else char_length(body) <= 2000
      end);

-- 2. Hide held rows from everyone but their author. (Admins review via
--    the comment_reports queue, which carries body_snapshot — they do
--    not need the live row through this policy.)
drop policy chart_comments_select on public.chart_comments;
create policy chart_comments_select on public.chart_comments
  for select to authenticated
  using (
    (status <> 'held' or author_id = auth.uid())
    and exists (
      select 1 from public.mahakosh_charts c
      where c.id = chart_comments.chart_id
    )
    and not exists (
      select 1 from public.user_blocks b
      where b.blocker_id = auth.uid()
        and b.blocked_id = chart_comments.author_id
    )
  );

-- 3. report_chart_comment: after filing, auto-hold at the threshold.
create or replace function public.report_chart_comment(
  p_comment_id uuid,
  p_reason text,
  p_details text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_body text;
  v_reporters int;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  if p_reason not in ('deanonymization', 'health_privacy', 'harassment', 'spam', 'other') then
    raise exception 'invalid report reason: %', p_reason;
  end if;

  -- Held comments can still be reported (more signal for the queue);
  -- deleted/removed ones cannot.
  select body into v_body
    from public.chart_comments
    where id = p_comment_id and status in ('visible', 'held');
  if v_body is null then
    raise exception 'comment not found';
  end if;

  insert into public.comment_reports
      (comment_id, reporter_id, reason, details, body_snapshot)
    values (p_comment_id, auth.uid(), p_reason, coalesce(p_details, ''), v_body)
    on conflict (comment_id, reporter_id) do update
      set reason        = excluded.reason,
          details       = excluded.details,
          body_snapshot = excluded.body_snapshot,
          status        = 'pending_review',
          created_at    = now(),
          reviewed_at   = null,
          review_note   = null;

  -- Auto-hold at >= 2 distinct pending reporters.
  select count(distinct reporter_id) into v_reporters
    from public.comment_reports
    where comment_id = p_comment_id and status = 'pending_review';
  if v_reporters >= 2 then
    update public.chart_comments
      set status = 'held'
      where id = p_comment_id and status = 'visible';
  end if;
end;
$$;

-- 4. moderate_comment_report: dismissing the LAST pending report on a
--    held comment restores it to visible.
create or replace function public.moderate_comment_report(
  p_report_id uuid,
  p_action text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_comment_id uuid;
  v_pending int;
begin
  if not public.is_admin() then
    raise exception 'admin required';
  end if;
  if p_action not in ('remove', 'dismiss') then
    raise exception 'invalid action: %', p_action;
  end if;

  select comment_id into v_comment_id
    from public.comment_reports
    where id = p_report_id and status = 'pending_review';
  if v_comment_id is null then
    raise exception 'report not found or already reviewed';
  end if;

  if p_action = 'remove' then
    update public.chart_comments
      set status = 'removed', body = ''
      where id = v_comment_id and status <> 'removed';
    update public.comment_reports
      set status = 'actioned', reviewed_at = now(), review_note = p_note
      where comment_id = v_comment_id and status = 'pending_review';
  else
    update public.comment_reports
      set status = 'dismissed', reviewed_at = now(), review_note = p_note
      where id = p_report_id;
    -- If that was the last pending report on a held comment, the hold
    -- has no remaining basis — restore visibility.
    select count(*) into v_pending
      from public.comment_reports
      where comment_id = v_comment_id and status = 'pending_review';
    if v_pending = 0 then
      update public.chart_comments
        set status = 'visible'
        where id = v_comment_id and status = 'held';
    end if;
  end if;
end;
$$;
