-- 0006: "Hide from my view" — per-user Mahakosh content filter.
--
-- App Store Guideline 1.2 (User-Generated Content) requires apps with UGC
-- to give users a way to filter out content they don't want to see, in
-- addition to reporting objectionable content for moderation (the existing
-- research_requests moderation queue, §2.7). This is that filter.
--
-- Distinct from reporting/moderation:
--   * Hiding is instant, personal, and silent — it never touches the chart's
--     public status and never involves a moderator.
--   * It only affects what the hiding user sees; every other user's view of
--     the chart (search, browse, request matches) is unchanged.
--   * It is reversible from a "Hidden charts" management screen.

create table public.hidden_mahakosh_charts (
  user_id   uuid not null references auth.users (id) on delete cascade,
  chart_id  uuid not null references public.mahakosh_charts (id) on delete cascade,
  hidden_at timestamptz not null default now(),
  primary key (user_id, chart_id)
);

comment on table public.hidden_mahakosh_charts is
  'Per-user "hide from my view" list for Mahakosh charts (App Store Guideline 1.2 content filtering). Not moderation — purely a personal, reversible filter.';

-- Composite PK already gives an efficient index for
-- "where chart_id = X and user_id = Y" (both directions of equality lookup),
-- which is exactly what the RLS predicate below and the edge-function
-- exclusion clause need.

alter table public.hidden_mahakosh_charts enable row level security;

-- Owner-only, all operations — a user can only see/add/remove their own
-- hidden entries. Inserts/deletes go through the RPCs below (which resolve
-- mk_code -> chart_id), but a direct policy is still useful/defensive.
create policy hidden_mahakosh_charts_owner_all on public.hidden_mahakosh_charts
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================================================
-- Fold the filter into the existing mahakosh_charts SELECT policy so every
-- RLS-governed read (recent(), fetchChart(), the mahakosh_charts(...) embed
-- in request_matches) transparently excludes charts the caller has hidden —
-- no call site needs to know about hiding.
-- ============================================================================
drop policy if exists mahakosh_charts_select on public.mahakosh_charts;

create policy mahakosh_charts_select on public.mahakosh_charts
  for select to authenticated
  using (
    (status = 'active' or contributor_id = auth.uid())
    and not exists (
      select 1 from public.hidden_mahakosh_charts h
      where h.chart_id = mahakosh_charts.id and h.user_id = auth.uid()
    )
  );

-- ============================================================================
-- hide_mahakosh_chart / unhide_mahakosh_chart — mk_code-based RPCs, mirroring
-- the withdraw() pattern (the client only ever handles mk_code, never the
-- internal chart_id).
--
-- SECURITY DEFINER (not invoker): once a chart is hidden, the caller's own
-- mahakosh_charts_select RLS would otherwise block the mk_code -> id lookup
-- inside unhide, permanently locking the user out of un-hiding. Running as
-- definer bypasses that self-referential lock; auth.uid() is still checked
-- explicitly, so a caller can only ever affect their own hidden-list rows.
-- ============================================================================
create or replace function public.hide_mahakosh_chart(p_mk_code text)
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

  select id into v_chart_id
    from public.mahakosh_charts
    where mk_code = p_mk_code;

  if v_chart_id is null then
    raise exception 'chart not found';
  end if;

  insert into public.hidden_mahakosh_charts (user_id, chart_id)
    values (auth.uid(), v_chart_id)
    on conflict (user_id, chart_id) do nothing;
end;
$$;

grant execute on function public.hide_mahakosh_chart(text) to authenticated;

create or replace function public.unhide_mahakosh_chart(p_mk_code text)
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

  select id into v_chart_id
    from public.mahakosh_charts
    where mk_code = p_mk_code;

  if v_chart_id is null then
    raise exception 'chart not found';
  end if;

  delete from public.hidden_mahakosh_charts
    where user_id = auth.uid() and chart_id = v_chart_id;
end;
$$;

grant execute on function public.unhide_mahakosh_chart(text) to authenticated;

-- ============================================================================
-- list_hidden_mahakosh_charts — the caller's own hidden list, for the
-- "Hidden charts" management/unhide screen. SECURITY DEFINER for the same
-- reason as above (the plain SELECT RLS policy hides these rows by design);
-- explicitly scoped to `h.user_id = auth.uid()` so it can never return
-- anyone else's hidden list.
-- ============================================================================
create or replace function public.list_hidden_mahakosh_charts()
returns table (
  mk_code           text,
  birth_year        int,
  location_general  text,
  ayanamsa_id       int,
  created_at        timestamptz,
  hidden_at         timestamptz
)
language sql
security definer
set search_path = public
stable
as $$
  select c.mk_code, c.birth_year, c.location_general, c.ayanamsa_id,
         c.created_at, h.hidden_at
  from public.hidden_mahakosh_charts h
  join public.mahakosh_charts c on c.id = h.chart_id
  where h.user_id = auth.uid()
  order by h.hidden_at desc;
$$;

grant execute on function public.list_hidden_mahakosh_charts() to authenticated;
