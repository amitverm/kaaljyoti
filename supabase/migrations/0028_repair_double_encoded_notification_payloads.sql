-- ============================================================================
-- 0028 — repair double-encoded notifications.payload rows
-- ============================================================================
-- notifications.payload is jsonb, but moderate-chart-report and
-- moderate-request inserted `${JSON.stringify(payload)}` without a cast.
-- The driver bound that string as a json parameter and encoded it a
-- SECOND time, so those rows hold a jsonb STRING —
--   "{\"mk_code\":\"MK-1\"}"
-- — instead of an object. The SQL triggers use jsonb_build_object and
-- were never affected, which is why only some notifications are wrong.
--
-- Why this matters more than it looks: the app maps the whole result set
-- in one pass, so a SINGLE bad row threw on its `as Map` cast and took
-- down the entire notifications screen. Repairing the data fixes that
-- for users on the ALREADY-RELEASED build, who otherwise stay broken
-- until they update.
--
-- The edge functions are fixed separately (::jsonb) so no new bad rows
-- are written; this is the backfill for the ones already stored.
--
-- Safe to re-run: after the first pass no row matches jsonb_typeof =
-- 'string' any more, so a repeat is a no-op.

update public.notifications
set payload = (payload #>> '{}')::jsonb
where jsonb_typeof(payload) = 'string'
  -- Only strings that actually encode an object. A jsonb string holding
  -- ordinary text is left exactly as it is rather than failing the cast
  -- and aborting the whole statement.
  and left(ltrim(payload #>> '{}'), 1) = '{';
