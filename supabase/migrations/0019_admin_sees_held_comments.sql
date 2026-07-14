-- 0019: Admins must see held comments (queue-join fix).
--
-- 0018 hid held rows from everyone but their author, on the theory that
-- the moderation queue carries body_snapshot and doesn't need the live
-- row. Wrong in practice: the queue's PostgREST embed
-- comment_reports -> chart_comments -> mahakosh_charts returns NULL for
-- a held comment (the reviewing admin isn't its author), which broke
-- the admin queue exactly when auto-hold fired. Let admins see held
-- rows; end users' visibility is unchanged.

drop policy chart_comments_select on public.chart_comments;
create policy chart_comments_select on public.chart_comments
  for select to authenticated
  using (
    (status <> 'held' or author_id = auth.uid() or public.is_admin())
    and exists (
      select 1 from public.mahakosh_charts c
      where c.id = chart_comments.chart_id
    )
    and not exists (
      select 1 from public.user_blocks b
      where b.blocker_id = auth.uid()
        and b.blocked_id = chart_comments.author_id
    )
  );
