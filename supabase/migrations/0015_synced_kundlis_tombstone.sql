-- Tombstone deletions for synced_kundlis.
--
-- Hard-deleting a synced kundli's row meant other devices never learned
-- about the deletion: pullAll only inserts/updates rows that still exist,
-- and realtime DELETE events don't reliably reach filtered subscribers
-- (the old row isn't replicated without REPLICA IDENTITY FULL). The stale
-- device would then re-upload the kundli on its next push, resurrecting
-- it everywhere.
--
-- Instead, deletion now keeps the row, clears the payload (deleted data
-- must not linger server-side) and stamps deleted_at. Devices apply the
-- deletion locally via last-write-wins against the kundli's updated_at.
-- Toggling sync OFF for a kundli still hard-deletes the row — that means
-- "remove from server", not "delete on my other devices".

alter table public.synced_kundlis
  add column if not exists deleted_at timestamptz;
