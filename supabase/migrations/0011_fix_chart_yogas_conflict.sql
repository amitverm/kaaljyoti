-- 0011: Fix ambiguous column reference in contribute_chart's yoga insert.
--
-- 0009 added `on conflict (chart_id, yoga_code) do nothing` to the yoga
-- insert. But contribute_chart is declared `returns table (chart_id uuid,
-- mk_code text)`, so `chart_id` is also a PL/pgSQL OUT variable. In the
-- conflict-target column list Postgres can't tell the OUT variable from
-- the chart_yogas.chart_id column and raises:
--   column reference "chart_id" is ambiguous (42702)
--
-- A conflict target cannot be table-qualified, so instead we name the
-- constraint directly (chart_yogas_pkey = the (chart_id, yoga_code)
-- primary key from 0001), which is unambiguous. `select distinct` still
-- dedupes within the incoming array; the on-conflict clause is defensive.
-- Otherwise identical to the 0005/0009 birth-data-aware function.

create or replace function public.contribute_chart(
  p_is_own boolean,
  p_birth_year int,
  p_location_general text,
  p_ayanamsa_id int,
  p_chart_payload jsonb,
  p_notify_on_match boolean,
  p_consent_kinds text[],
  p_consent_text_version text,
  p_index jsonb,
  p_yoga_codes text[],
  p_events jsonb,
  p_birth_utc timestamptz,
  p_latitude double precision,
  p_longitude double precision,
  p_timezone_name text,
  p_utc_offset_min integer,
  p_place_name text
)
returns table (chart_id uuid, mk_code text)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_chart public.mahakosh_charts%rowtype;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  if p_consent_kinds is null or array_length(p_consent_kinds, 1) is null then
    raise exception 'at least one consent record is required';
  end if;
  if p_index is null or jsonb_array_length(p_index) < 9 then
    raise exception 'a complete chart index (9 grahas) is required';
  end if;
  if p_birth_utc is null then
    raise exception 'birth details are required for full calculations';
  end if;

  insert into public.mahakosh_charts
      (contributor_id, is_own, birth_year, location_general,
       ayanamsa_id, chart_payload, notify_on_match, status,
       birth_utc, latitude, longitude, timezone_name,
       utc_offset_min, place_name)
    values
      (auth.uid(), p_is_own, p_birth_year, p_location_general,
       p_ayanamsa_id, p_chart_payload, coalesce(p_notify_on_match, true),
       'active',
       p_birth_utc, p_latitude, p_longitude, p_timezone_name,
       p_utc_offset_min, p_place_name)
    returning * into v_chart;

  insert into public.consent_records (chart_id, kind, text_version)
    select v_chart.id, k, coalesce(p_consent_text_version, 'v1')
    from unnest(p_consent_kinds) as k;

  insert into public.chart_index (chart_id, planet, sign, house, nakshatra, pada)
    select v_chart.id,
           (e->>'planet'),
           (e->>'sign')::int,
           (e->>'house')::int,
           (e->>'nakshatra')::int,
           (e->>'pada')::int
    from jsonb_array_elements(p_index) as e;

  if p_yoga_codes is not null and array_length(p_yoga_codes, 1) is not null then
    insert into public.chart_yogas (chart_id, yoga_code)
      select distinct v_chart.id, c from unnest(p_yoga_codes) as c
      on conflict on constraint chart_yogas_pkey do nothing;
  end if;

  if p_events is not null and jsonb_array_length(p_events) > 0 then
    insert into public.life_events
        (chart_id, tag, event_date, is_health_related, note)
      select v_chart.id,
             (e->>'tag'),
             nullif(e->>'event_date', '')::date,
             coalesce((e->>'is_health_related')::boolean, false),
             coalesce(e->>'note', '')
      from jsonb_array_elements(p_events) as e;
  end if;

  return query select v_chart.id, v_chart.mk_code;
end;
$$;

grant execute on function public.contribute_chart to authenticated;
