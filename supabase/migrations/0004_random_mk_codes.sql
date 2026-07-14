-- 0004: random MK codes.
--
-- Sequential codes (MK-1001, MK-1002 …) leak the community's size and
-- each chart's contribution order. Switch to short random codes from
-- an unambiguous alphabet (no 0/O, 1/I/L) — e.g. 'MK-7K3F9'.
-- Existing codes are left untouched: codes must never change once
-- shared. 5 chars over a 31-char alphabet ≈ 28.6M combinations; the
-- retry loop plus the UNIQUE constraint on mk_code handle collisions.

create or replace function public.assign_mk_code()
returns trigger
language plpgsql
as $$
declare
  alphabet constant text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  candidate text;
  tries int := 0;
begin
  loop
    candidate := 'MK-' || (
      select string_agg(
        substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1), ''
      )
      from generate_series(1, 5)
    );
    exit when not exists (
      select 1 from public.mahakosh_charts c where c.mk_code = candidate
    );
    tries := tries + 1;
    if tries > 20 then
      raise exception 'could not generate a unique mk_code';
    end if;
  end loop;
  -- Always server-assigned; any client-supplied value is discarded
  -- (0002 hardening preserved).
  new.mk_code := candidate;
  return new;
end;
$$;

-- The sequence from 0001 is no longer used; keep it dropped for tidiness.
drop sequence if exists public.mahakosh_mk_code_seq;
