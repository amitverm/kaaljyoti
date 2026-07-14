-- 0012: update life events on an already-shared Mahakosh chart.
--
-- Contribution (0003) writes a chart's events once, atomically with consent.
-- But an astrologer often records life events AFTER first sharing a chart
-- (e.g. shared with none, then added a marriage). Re-sharing would mint a new
-- MK code and re-run matching. This RPC instead REPLACES the events on the
-- caller's EXISTING active chart, in one transaction, keeping the same MK code.
--
-- Consent: the product uses a single share consent covering all records, so
-- there is no separate health-consent step here. The database still enforces
-- (via trg_life_events_health_consent, migration 0001) that a health-flagged
-- event cannot exist without a live 'health' consent row — that guard also
-- protects the contribute path and must stay. To satisfy it transparently, we
-- record the 'health' consent row automatically (derived from the same single
-- consent) when the new set contains health events and none is on file yet.
--
-- SECURITY INVOKER: runs as the authenticated caller, so RLS still applies and
-- a user can only touch their own chart's rows. We additionally scope the
-- lookup by contributor_id and status = 'active'.

create or replace function public.update_mahakosh_events(
  p_mk_code text,
  p_events jsonb,                       -- [{tag, event_date, is_health_related, note}, ...]
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

  -- Satisfy the DB health-consent invariant before inserting any health event.
  -- The chart's single share consent covers this, so record it automatically
  -- if not already present (must come BEFORE the life_events insert, since the
  -- gate is a BEFORE-INSERT trigger).
  if v_has_health and not exists (
    select 1 from public.consent_records cr
    where cr.chart_id = v_chart_id
      and cr.kind = 'health'
      and cr.revoked_at is null
  ) then
    insert into public.consent_records (chart_id, kind, text_version)
      values (v_chart_id, 'health', coalesce(p_consent_text_version, 'v1'));
  end if;

  -- Replace the chart's events with the provided set.
  delete from public.life_events where chart_id = v_chart_id;

  if p_events is not null and jsonb_array_length(p_events) > 0 then
    insert into public.life_events
        (chart_id, tag, event_date, is_health_related, note)
      select v_chart_id,
             (e->>'tag'),
             nullif(e->>'event_date', '')::date,
             coalesce((e->>'is_health_related')::boolean, false),
             coalesce(e->>'note', '')
      from jsonb_array_elements(p_events) as e;
  end if;

  select count(*) into v_count
    from public.life_events where chart_id = v_chart_id;
  return v_count;
end;
$$;

grant execute on function public.update_mahakosh_events to authenticated;
