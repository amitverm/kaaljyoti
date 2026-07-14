-- 0020: Notifications for discussion touch points.
--
-- The discussion feature (0016-0019) created events users care about
-- but never hear of: replies to their comments, comments on their
-- contributed charts, and moderation outcomes on their own comments.
-- Emit rows into public.notifications (same table the research/report
-- flows use) from inside the SECURITY DEFINER RPCs — the existing bell
-- UI picks them up immediately, and the push pipeline (device_tokens +
-- send-notification webhook, coming separately) will fan them out.
--
-- Types added (payload keys follow the moderate-* conventions):
--   comment_reply     -> parent-comment author   {mk_code, comment_id, author_name, snippet}
--   chart_comment     -> chart contributor       {mk_code, comment_id, author_name, snippet}
--   comment_held      -> comment author          {mk_code, snippet}
--   comment_removed   -> comment author          {mk_code, snippet, review_note?}
--   comment_restored  -> comment author          {mk_code, snippet}
--
-- Notifying the contributor never de-anonymizes anyone: the recipient
-- learns only that "your chart MK-x got a comment" — contributor_id
-- stays server-side, exactly as in the your_chart_matched flow.

-- ============================================================================
-- add_chart_comment: notify parent author (reply) + chart contributor.
-- ============================================================================
create or replace function public.add_chart_comment(
  p_mk_code text,
  p_body text,
  p_parent_id uuid default null,
  p_display_name text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_chart_id uuid;
  v_contributor uuid;
  v_name text;
  v_last timestamptz;
  v_hour_count int;
  v_id uuid;
  v_parent_author uuid;
  v_snippet text;
begin
  if v_uid is null then
    raise exception 'authentication required';
  end if;

  if p_body is null or char_length(btrim(p_body)) = 0 then
    raise exception 'comment cannot be empty';
  end if;
  if char_length(p_body) > 2000 then
    raise exception 'comment too long (max 2000 characters)';
  end if;

  select id, contributor_id into v_chart_id, v_contributor
    from public.mahakosh_charts
    where mk_code = p_mk_code and status = 'active';
  if v_chart_id is null then
    raise exception 'chart not found or not active';
  end if;

  -- Display name: ensure the caller has a profile with a name.
  select display_name into v_name from public.profiles where id = v_uid;
  if v_name is null or btrim(v_name) = '' then
    if p_display_name is null or char_length(btrim(p_display_name)) = 0 then
      raise exception 'display name required';
    end if;
    if char_length(btrim(p_display_name)) > 40 then
      raise exception 'display name too long (max 40 characters)';
    end if;
    v_name := btrim(p_display_name);
    insert into public.profiles (id, display_name)
      values (v_uid, v_name)
      on conflict (id) do update set display_name = excluded.display_name
        where profiles.display_name is null or btrim(profiles.display_name) = '';
  end if;

  -- Rate limit: 10s cooldown, 30 comments per rolling hour.
  select max(created_at) into v_last
    from public.chart_comments where author_id = v_uid;
  if v_last is not null and v_last > now() - interval '10 seconds' then
    raise exception 'you are commenting too quickly — wait a few seconds';
  end if;
  select count(*) into v_hour_count
    from public.chart_comments
    where author_id = v_uid and created_at > now() - interval '1 hour';
  if v_hour_count >= 30 then
    raise exception 'hourly comment limit reached — try again later';
  end if;

  -- Reply target must be a comment on the same chart.
  if p_parent_id is not null then
    select author_id into v_parent_author
      from public.chart_comments
      where id = p_parent_id and chart_id = v_chart_id;
    if v_parent_author is null then
      raise exception 'reply target not found on this chart';
    end if;
  end if;

  insert into public.chart_comments (chart_id, author_id, parent_id, body)
    values (v_chart_id, v_uid, p_parent_id, btrim(p_body))
    returning id into v_id;

  -- Touch points (never notify the actor about their own action, and
  -- don't double-notify someone who is both parent author and
  -- contributor).
  v_snippet := left(btrim(p_body), 120);
  if v_parent_author is not null and v_parent_author <> v_uid then
    insert into public.notifications (user_id, type, payload)
      values (v_parent_author, 'comment_reply', jsonb_build_object(
        'mk_code', p_mk_code, 'comment_id', v_id,
        'author_name', v_name, 'snippet', v_snippet));
  end if;
  if v_contributor <> v_uid
     and (v_parent_author is null or v_contributor <> v_parent_author) then
    insert into public.notifications (user_id, type, payload)
      values (v_contributor, 'chart_comment', jsonb_build_object(
        'mk_code', p_mk_code, 'comment_id', v_id,
        'author_name', v_name, 'snippet', v_snippet));
  end if;

  return v_id;
end;
$$;

-- ============================================================================
-- report_chart_comment: on auto-hold, tell the author their comment is
-- hidden pending review (they already see the placeholder; this
-- explains it).
-- ============================================================================
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
  v_author uuid;
  v_mk text;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  if p_reason not in ('deanonymization', 'health_privacy', 'harassment', 'spam', 'other') then
    raise exception 'invalid report reason: %', p_reason;
  end if;

  select c.body, c.author_id, m.mk_code into v_body, v_author, v_mk
    from public.chart_comments c
    join public.mahakosh_charts m on m.id = c.chart_id
    where c.id = p_comment_id and c.status in ('visible', 'held');
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

  select count(distinct reporter_id) into v_reporters
    from public.comment_reports
    where comment_id = p_comment_id and status = 'pending_review';
  if v_reporters >= 2 then
    update public.chart_comments
      set status = 'held'
      where id = p_comment_id and status = 'visible';
    if found then
      insert into public.notifications (user_id, type, payload)
        values (v_author, 'comment_held', jsonb_build_object(
          'mk_code', v_mk, 'snippet', left(v_body, 120)));
    end if;
  end if;
end;
$$;

-- ============================================================================
-- moderate_comment_report: notify the author of the outcome.
-- ============================================================================
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
  v_author uuid;
  v_mk text;
  v_snippet text;
begin
  if not public.is_admin() then
    raise exception 'admin required';
  end if;
  if p_action not in ('remove', 'dismiss') then
    raise exception 'invalid action: %', p_action;
  end if;

  select r.comment_id, c.author_id, m.mk_code, left(r.body_snapshot, 120)
      into v_comment_id, v_author, v_mk, v_snippet
    from public.comment_reports r
    join public.chart_comments c on c.id = r.comment_id
    join public.mahakosh_charts m on m.id = c.chart_id
    where r.id = p_report_id and r.status = 'pending_review';
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
    insert into public.notifications (user_id, type, payload)
      values (v_author, 'comment_removed', jsonb_build_object(
        'mk_code', v_mk, 'snippet', v_snippet)
        || case when p_note is not null and p_note <> ''
             then jsonb_build_object('review_note', p_note)
             else '{}'::jsonb end);
  else
    update public.comment_reports
      set status = 'dismissed', reviewed_at = now(), review_note = p_note
      where id = p_report_id;
    select count(*) into v_pending
      from public.comment_reports
      where comment_id = v_comment_id and status = 'pending_review';
    if v_pending = 0 then
      update public.chart_comments
        set status = 'visible'
        where id = v_comment_id and status = 'held';
      if found then
        insert into public.notifications (user_id, type, payload)
          values (v_author, 'comment_restored', jsonb_build_object(
            'mk_code', v_mk, 'snippet', v_snippet));
      end if;
    end if;
  end if;
end;
$$;
