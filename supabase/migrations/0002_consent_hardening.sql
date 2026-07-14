-- 0002: consent & integrity hardening (audit findings)
--
-- (1) CRITICAL: revoking the last live consent record used to leave the
--     chart active and searchable. Now revocation auto-withdraws the
--     chart when no live consent remains.
-- (2) The consent ledger is append-only in practice: the only mutation
--     allowed is revoked_at NULL -> timestamp; every other column is
--     immutable after insert.
-- (3) mk_code is always server-assigned; client-supplied values are
--     ignored (prevents spoofed/pre-claimed codes).

-- --------------------------------------------------------------------
-- (2) Consent records: immutable except revocation.
-- --------------------------------------------------------------------
create or replace function public.enforce_consent_immutability()
returns trigger
language plpgsql
as $$
begin
  if new.chart_id  is distinct from old.chart_id
     or new.kind        is distinct from old.kind
     or new.text_version is distinct from old.text_version
     or new.granted_at  is distinct from old.granted_at then
    raise exception 'consent records are append-only; only revocation is allowed';
  end if;
  -- revoked_at may only transition NULL -> non-NULL (no un-revoking).
  if old.revoked_at is not null
     and new.revoked_at is distinct from old.revoked_at then
    raise exception 'a revoked consent record cannot be modified';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_consent_immutability on public.consent_records;
create trigger trg_consent_immutability
  before update on public.consent_records
  for each row execute function public.enforce_consent_immutability();

-- --------------------------------------------------------------------
-- (1) Revoking the last live consent withdraws the chart.
-- --------------------------------------------------------------------
create or replace function public.withdraw_chart_without_consent()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.revoked_at is not null and old.revoked_at is null then
    if not exists (
      select 1 from public.consent_records cr
      where cr.chart_id = new.chart_id
        and cr.revoked_at is null
    ) then
      update public.mahakosh_charts
        set status = 'withdrawn',
            withdrawn_at = now()
        where id = new.chart_id
          and status = 'active';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_withdraw_on_consent_revocation on public.consent_records;
create trigger trg_withdraw_on_consent_revocation
  after update on public.consent_records
  for each row execute function public.withdraw_chart_without_consent();

-- --------------------------------------------------------------------
-- (3) mk_code is always server-assigned.
-- --------------------------------------------------------------------
create or replace function public.assign_mk_code()
returns trigger
language plpgsql
as $$
begin
  -- Unconditional: any client-supplied value is discarded.
  new.mk_code := 'MK-' || nextval('public.mahakosh_mk_code_seq');
  return new;
end;
$$;
