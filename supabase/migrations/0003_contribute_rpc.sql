-- 0003: atomic chart contribution.
--
-- The consent invariant trigger is deferred to COMMIT, but the client
-- talks to PostgREST where every request is its own transaction — so
-- inserting the chart and its consent records in separate requests can
-- never satisfy the invariant. This RPC performs the entire
-- contribution (chart + consents + search index + yogas + life events)
-- in ONE transaction. It also guarantees the search index is complete
-- for every active chart (audit finding: partial-insert risk).
--
-- SECURITY INVOKER: runs as the calling `authenticated` role, so all
-- RLS policies still apply; the contributor can only insert as
-- themselves.

create or replace function public.contribute_chart(
  p_is_own boolean,
  p_birth_year int,
  p_location_general text,
  p_ayanamsa_id int,
  p_chart_payload jsonb,
  p_notify_on_match boolean,
  p_consent_kinds text[],
  p_consent_text_version text,
  p_index jsonb,       -- [{planet, sign, house, nakshatra, pada}, ...]
  p_yoga_codes text[],
  p_events jsonb       -- [{tag, event_date, is_health_related, note}, ...]
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

  insert into public.mahakosh_charts
      (contributor_id, is_own, birth_year, location_general,
       ayanamsa_id, chart_payload, notify_on_match, status)
    values
      (auth.uid(), p_is_own, p_birth_year, p_location_general,
       p_ayanamsa_id, p_chart_payload, coalesce(p_notify_on_match, true),
       'active')
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
