-- 0016: Discussion on Mahakosh charts — per-chart comment threads.
--
-- Any signed-in user can comment on an active community chart and reply
-- to another comment (flat list + reply-to reference; no deep nesting).
-- Comments display the author's chosen profiles.display_name — picked on
-- first comment (profiles has existed since 0001 but was unused so far).
--
-- UGC obligations (App Store Guideline 1.2 / Play UGC policy — same
-- reasoning as 0006/0007 for charts) are built in from day one:
--   * report a comment for moderator review  (comment_reports + RPC)
--   * block a user — one-way: their comments vanish from MY view only
--     (user_blocks, enforced inside the chart_comments SELECT policy)
--   * moderator removal via moderate_comment_report (is_admin-gated RPC;
--     see the "why not an edge function" note at the bottom)
--
-- Lifecycle: rows are never hard-deleted while replies may reference
-- them. status transitions clear the body so deleted/removed content
-- does not linger:
--   visible  --author delete-->  deleted  (body wiped)
--   visible  --moderator------>  removed  (body wiped; body_snapshot on
--                                          the report keeps the evidence)
-- The UI renders deleted/removed rows as placeholders so reply context
-- stays coherent.
--
-- All writes go through SECURITY DEFINER RPCs (no direct INSERT/UPDATE
-- policies): transitions stay server-controlled and add_chart_comment
-- can rate-limit (spam is otherwise free through raw PostgREST inserts).

-- ============================================================================
-- chart_comments
-- ============================================================================
create table public.chart_comments (
  id         uuid primary key default gen_random_uuid(),
  chart_id   uuid not null references public.mahakosh_charts (id) on delete cascade,
  -- References profiles (not auth.users) so PostgREST can embed the
  -- author's display_name in one select; add_chart_comment guarantees
  -- the profile row exists.
  author_id  uuid not null references public.profiles (id) on delete cascade,
  -- Reply-to (flat + quote, not a tree). NULL = top-level comment.
  parent_id  uuid references public.chart_comments (id) on delete set null,
  -- Visible comments carry text; deleted/removed rows have the body
  -- wiped to '' (the transitions in delete_chart_comment /
  -- moderate_comment_report), which the constraint must permit.
  body       text not null check (
               case when status = 'visible'
                 then char_length(body) between 1 and 2000
                 else char_length(body) <= 2000
               end),
  status     text not null default 'visible'
               check (status in ('visible', 'deleted', 'removed')),
  created_at timestamptz not null default now(),
  edited_at  timestamptz
);

create index idx_chart_comments_chart on public.chart_comments (chart_id, created_at);
create index idx_chart_comments_author on public.chart_comments (author_id);

comment on table public.chart_comments is
  'Per-chart discussion on Mahakosh community charts. Flat list with reply-to references. Author shown via profiles.display_name. Writes only via RPCs (rate limit + controlled transitions); deleted/removed rows stay for thread structure with the body wiped.';

alter table public.chart_comments enable row level security;

-- SELECT policy is defined after user_blocks below (it references that
-- table, which must exist first). No INSERT/UPDATE/DELETE policies:
-- writes happen only through the SECURITY DEFINER RPCs below.

-- ============================================================================
-- user_blocks — one-way personal mute (App Store Guideline 1.2 "block
-- abusive users"). Blocking hides the blocked user's comments from the
-- blocker's view only; the blocked user is never notified and their
-- content is untouched for everyone else. Mirrors the philosophy of
-- hidden_mahakosh_charts (0006): personal, silent, reversible.
-- ============================================================================
create table public.user_blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

comment on table public.user_blocks is
  'One-way personal blocks: blocker no longer sees blocked user''s comments (enforced in chart_comments SELECT policy). Silent and reversible; owner-only rows.';

alter table public.user_blocks enable row level security;

create policy user_blocks_select_own on public.user_blocks
  for select to authenticated
  using (blocker_id = auth.uid());

create policy user_blocks_insert_own on public.user_blocks
  for insert to authenticated
  with check (blocker_id = auth.uid());

create policy user_blocks_delete_own on public.user_blocks
  for delete to authenticated
  using (blocker_id = auth.uid());

-- chart_comments SELECT (deferred from above — needs user_blocks): any
-- signed-in user, on charts they can see, minus authors they have
-- personally blocked. deleted/removed rows are selectable (body is
-- already wiped) so reply references keep rendering. The mahakosh_charts
-- subquery rides on ITS select policy (active, not hidden, or admin).
create policy chart_comments_select on public.chart_comments
  for select to authenticated
  using (
    exists (
      select 1 from public.mahakosh_charts c
      where c.id = chart_comments.chart_id
    )
    and not exists (
      select 1 from public.user_blocks b
      where b.blocker_id = auth.uid()
        and b.blocked_id = chart_comments.author_id
    )
  );

-- ============================================================================
-- comment_reports — mirrors chart_reports (0007) for individual comments.
-- body_snapshot preserves what was reported even if the author edits or
-- deletes the comment afterwards (the comment body is wiped on removal,
-- so the report row is the moderation evidence).
-- ============================================================================
create table public.comment_reports (
  id            uuid primary key default gen_random_uuid(),
  comment_id    uuid not null references public.chart_comments (id) on delete cascade,
  reporter_id   uuid not null references auth.users (id) on delete cascade,
  reason        text not null check (reason in (
                  'deanonymization',  -- comment tries to identify the chart's real person
                  'health_privacy',   -- exposes sensitive health details
                  'harassment',       -- harassing, hateful, or abusive content
                  'spam',             -- spam / advertising / fake content
                  'other'
                )),
  details       text not null default '',
  body_snapshot text not null,
  status        text not null default 'pending_review'
                  check (status in ('pending_review', 'actioned', 'dismissed')),
  created_at    timestamptz not null default now(),
  reviewed_at   timestamptz,
  review_note   text,
  -- One open report per (user, comment); resubmit updates in place
  -- (same anti-pileup reasoning as chart_reports).
  unique (comment_id, reporter_id)
);

create index idx_comment_reports_status on public.comment_reports (status);

comment on table public.comment_reports is
  'User reports of discussion comments for moderator review (Guideline 1.2). body_snapshot keeps the reported text through later edits/deletions.';

alter table public.comment_reports enable row level security;

-- Reporters see their own; admins see the pending queue (0008 pattern).
create policy comment_reports_select on public.comment_reports
  for select to authenticated
  using (
    reporter_id = auth.uid()
    or (status = 'pending_review' and public.is_admin())
  );

-- INSERT via report_chart_comment RPC only (needs the body snapshot).

-- ============================================================================
-- add_chart_comment — the only way to create a comment.
--   * requires a display name: creates/keeps the caller's profiles row
--     (p_display_name is used only when the profile has no name yet —
--     changing the name is a separate client update on profiles).
--   * rate limit: >=10s between comments, max 30 per rolling hour.
--   * chart must be active; parent (if any) must belong to same chart.
-- Returns the new comment id.
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
  v_name text;
  v_last timestamptz;
  v_hour_count int;
  v_id uuid;
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

  select id into v_chart_id
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
    insert into public.profiles (id, display_name)
      values (v_uid, btrim(p_display_name))
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
    if not exists (
      select 1 from public.chart_comments
      where id = p_parent_id and chart_id = v_chart_id
    ) then
      raise exception 'reply target not found on this chart';
    end if;
  end if;

  insert into public.chart_comments (chart_id, author_id, parent_id, body)
    values (v_chart_id, v_uid, p_parent_id, btrim(p_body))
    returning id into v_id;
  return v_id;
end;
$$;

grant execute on function public.add_chart_comment(text, text, uuid, text) to authenticated;

-- ============================================================================
-- edit_chart_comment — author edits their own visible comment.
-- ============================================================================
create or replace function public.edit_chart_comment(
  p_comment_id uuid,
  p_body text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  if p_body is null or char_length(btrim(p_body)) = 0 then
    raise exception 'comment cannot be empty';
  end if;
  if char_length(p_body) > 2000 then
    raise exception 'comment too long (max 2000 characters)';
  end if;

  update public.chart_comments
    set body = btrim(p_body), edited_at = now()
    where id = p_comment_id
      and author_id = auth.uid()
      and status = 'visible';
  if not found then
    raise exception 'comment not found or not editable';
  end if;
end;
$$;

grant execute on function public.edit_chart_comment(uuid, text) to authenticated;

-- ============================================================================
-- delete_chart_comment — author deletes their own comment: the row stays
-- (replies may reference it) with the body wiped.
-- ============================================================================
create or replace function public.delete_chart_comment(p_comment_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  update public.chart_comments
    set status = 'deleted', body = ''
    where id = p_comment_id
      and author_id = auth.uid()
      and status = 'visible';
  if not found then
    raise exception 'comment not found or not deletable';
  end if;
end;
$$;

grant execute on function public.delete_chart_comment(uuid) to authenticated;

-- ============================================================================
-- report_chart_comment — file (or refresh) a report; snapshots the body.
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
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  if p_reason not in ('deanonymization', 'health_privacy', 'harassment', 'spam', 'other') then
    raise exception 'invalid report reason: %', p_reason;
  end if;

  select body into v_body
    from public.chart_comments
    where id = p_comment_id and status = 'visible';
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
end;
$$;

grant execute on function public.report_chart_comment(uuid, text, text) to authenticated;

-- ============================================================================
-- moderate_comment_report — admin resolves a report.
--   action = 'remove'  : comment removed for everyone (body wiped) and
--                        every pending report on it is closed as actioned.
--   action = 'dismiss' : comment stays; just this report is dismissed.
--
-- Why an is_admin()-gated RPC instead of an edge function (the
-- moderate-request / moderate-chart-report pattern): those predate the
-- in-app admin role and also serve INTERNAL_TOKEN ops tooling. The
-- security boundary is identical — is_admin() evaluated server-side
-- against the caller's JWT — without a TypeScript function to deploy.
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
    -- Close every pending report on this comment, not just this one.
    update public.comment_reports
      set status = 'actioned', reviewed_at = now(), review_note = p_note
      where comment_id = v_comment_id and status = 'pending_review';
  else
    update public.comment_reports
      set status = 'dismissed', reviewed_at = now(), review_note = p_note
      where id = p_report_id;
  end if;
end;
$$;

grant execute on function public.moderate_comment_report(uuid, text, text) to authenticated;
