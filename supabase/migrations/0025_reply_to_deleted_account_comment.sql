-- ============================================================================
-- 0025 — fix: replying to a deleted-account comment
-- ============================================================================
-- 0024 keeps a departed user's comments visible with author_id NULL.
-- add_chart_comment (0020) used the parent's author_id as its existence
-- check ("select author_id ... if v_parent_author is null then 'reply
-- target not found'"), so replying to such a comment — which the UI
-- happily offers — raised a bogus error. Check existence by id instead;
-- the notification guards below already treat a NULL parent author
-- correctly (no reply notification, contributor notification intact).
-- Full function body otherwise identical to 0020.

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
  v_parent_id uuid;
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

  -- Reply target must be a comment on the same chart. Existence is
  -- checked by id — the author may be NULL (deleted account, 0024).
  if p_parent_id is not null then
    select id, author_id into v_parent_id, v_parent_author
      from public.chart_comments
      where id = p_parent_id and chart_id = v_chart_id;
    if v_parent_id is null then
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
