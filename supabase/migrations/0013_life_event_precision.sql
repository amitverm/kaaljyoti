-- 0013: preserve life-event date precision on Mahakosh.
--
-- Life events are recorded with a precision the native actually knows —
-- an exact date, a month, just a year, or only an age. Contribution and the
-- events update flattened everything to a single date column, so the community
-- card could only honestly show a year. This carries the precision through, so
-- a shared chart shows the date exactly as entered ("2019", "Apr 2019",
-- "12 Apr 2019", or "Age 27"). Consent already covers sharing these events;
-- notes remain withheld from display.
--
-- Additive columns (default 'exact') — existing rows keep rendering as before.

alter table public.life_events
  add column if not exists date_precision text not null default 'exact'
    check (date_precision in ('exact', 'month', 'year', 'age')),
  add column if not exists age_years int;

-- Defensive: an earlier draft of this migration briefly recreated the OLD
-- 11-arg contribute_chart (pre-birth-data, 0003). The live function is the
-- 17-arg birth-data-aware version from migration 0005. Drop the stale 11-arg
-- overload if it exists so the name resolves uniquely.
drop function if exists public.contribute_chart(
  boolean, int, text, int, jsonb, boolean, text[], text, jsonb, text[], jsonb
);

-- --------------------------------------------------------------------------
-- Re-create the real (17-arg, birth-data-aware) contribute_chart to also store
-- precision + age. Same signature as 0005; only the life_events insert changes.
-- --------------------------------------------------------------------------
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
  p_events jsonb,       -- [{tag, event_date, date_precision, age_years, is_health_related, note}, ...]
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
      select v_chart.id, c from unnest(p_yoga_codes) as c;
  end if;

  if p_events is not null and jsonb_array_length(p_events) > 0 then
    insert into public.life_events
        (chart_id, tag, event_date, is_health_related, note,
         date_precision, age_years)
      select v_chart.id,
             (e->>'tag'),
             nullif(e->>'event_date', '')::date,
             coalesce((e->>'is_health_related')::boolean, false),
             coalesce(e->>'note', ''),
             coalesce(nullif(e->>'date_precision', ''), 'exact'),
             nullif(e->>'age_years', '')::int
      from jsonb_array_elements(p_events) as e;
  end if;

  return query select v_chart.id, v_chart.mk_code;
end;
$$;

grant execute on function public.contribute_chart(
  boolean, int, text, int, jsonb, boolean, text[], text, jsonb, text[], jsonb,
  timestamptz, double precision, double precision, text, integer, text
) to authenticated;

-- --------------------------------------------------------------------------
-- Re-create update_mahakosh_events (unchanged 3-arg signature) to also store
-- precision + age.
-- --------------------------------------------------------------------------
create or replace function public.update_mahakosh_events(
  p_mk_code text,
  p_events jsonb,
  p_consent_text_version text default 'v1'
)
returns integer
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_chart_id uuid;
  v_has_health boolean;
  v_count integer;
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;

  select id into v_chart_id
  from public.mahakosh_charts
  where mk_code = p_mk_code
    and contributor_id = auth.uid()
    and status = 'active';
  if v_chart_id is null then
    raise exception 'no active chart % owned by you', p_mk_code;
  end if;

  v_has_health := coalesce(
    (select bool_or(coalesce((e->>'is_health_related')::boolean, false))
       from jsonb_array_elements(coalesce(p_events, '[]'::jsonb)) as e),
    false);

  if v_has_health and not exists (
    select 1 from public.consent_records cr
    where cr.chart_id = v_chart_id
      and cr.kind = 'health'
      and cr.revoked_at is null
  ) then
    insert into public.consent_records (chart_id, kind, text_version)
      values (v_chart_id, 'health', coalesce(p_consent_text_version, 'v1'));
  end if;

  delete from public.life_events where chart_id = v_chart_id;

  if p_events is not null and jsonb_array_length(p_events) > 0 then
    insert into public.life_events
        (chart_id, tag, event_date, is_health_related, note,
         date_precision, age_years)
      select v_chart_id,
             (e->>'tag'),
             nullif(e->>'event_date', '')::date,
             coalesce((e->>'is_health_related')::boolean, false),
             coalesce(e->>'note', ''),
             coalesce(nullif(e->>'date_precision', ''), 'exact'),
             nullif(e->>'age_years', '')::int
      from jsonb_array_elements(p_events) as e;
  end if;

  select count(*) into v_count
    from public.life_events where chart_id = v_chart_id;
  return v_count;
end;
$$;

grant execute on function public.update_mahakosh_events(text, jsonb, text)
  to authenticated;
