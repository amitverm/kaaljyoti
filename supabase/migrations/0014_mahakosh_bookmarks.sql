-- 0014: per-user bookmarks of community charts.
--
-- With thousands of contributed charts, a jyotish studying or tracking a
-- specific chart needs quick access to it. Bookmarks are private to the user
-- and sync across their devices (server-owned, owner-only RLS). We key on the
-- public mk_code rather than the internal chart id — no FK, so a bookmark
-- survives even if the chart is temporarily unavailable; the app filters to
-- active charts when listing.

create table if not exists public.mahakosh_bookmarks (
  user_id    uuid not null references auth.users (id) on delete cascade,
  mk_code    text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, mk_code)
);

create index if not exists idx_mahakosh_bookmarks_user
  on public.mahakosh_bookmarks (user_id, created_at desc);

alter table public.mahakosh_bookmarks enable row level security;

-- Owner-only: a user sees and manages only their own bookmarks.
create policy mahakosh_bookmarks_owner_all on public.mahakosh_bookmarks
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
