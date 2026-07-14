-- 0022: synced_kundlis keyed by (id, user_id), not id alone.
--
-- Found in release QA: a kundli that account A once synced could never
-- be synced by account B on the same device. The kundli's UUID was the
-- table's PRIMARY KEY, so B's upsert hit A's row — which owner-only
-- RLS forbids B from updating — and pushAll failed silently. Toggling
-- sync off was equally powerless (B deletes B's row; B has none).
--
-- Composite key = each account owns its own copy of a chart id. A's
-- original row is untouched; B gets their own. All client reads/writes
-- are already scoped by owner-only RLS, so nothing else changes —
-- the client upserts just name the conflict target explicitly
-- (onConflict: 'id,user_id').

alter table public.synced_kundlis
  drop constraint synced_kundlis_pkey;
alter table public.synced_kundlis
  add primary key (id, user_id);
