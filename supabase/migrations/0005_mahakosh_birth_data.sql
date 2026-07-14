-- 0005: Mahakosh charts carry full birth details (product decision).
--
-- Research needs complete calculations — dashas require the birth
-- instant, so longitudes alone are not enough. Anonymization is now
-- defined as: the NAME is never stored or shown; birth date, time and
-- place ARE shared, and the consent copy in the app says so plainly.
-- (Legacy rows keep NULL birth columns; the app shows a limited view
-- for them until re-shared.)

alter table public.mahakosh_charts
  add column if not exists birth_utc timestamptz,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists timezone_name text,
  add column if not exists utc_offset_min integer,
  add column if not exists place_name text;

-- Replace the contribution RPC with the birth-data-aware signature.
drop function if exists public.contribute_chart(
  boolean, int, text, int, jsonb, boolean, text[], text, jsonb, text[], jsonb
);

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
      select v_chart.id, c from unnest(p_yoga_codes) as c;
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
