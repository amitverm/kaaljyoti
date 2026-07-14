-- ============================================================================
-- 0024 — discussion comments survive account deletion as placeholders
-- ============================================================================
-- The author_id FK cascaded from profiles, so deleting an ACCOUNT
-- hard-deleted every comment the user ever wrote and punched holes in
-- discussions. With SET NULL the comments outlive the profile: they
-- stay visible with their text intact, and only the identity link is
-- removed (the client renders a NULL author as "Deleted account").
-- Users who want a comment's text gone delete it in the app — no time
-- window — before deleting the account.

alter table public.chart_comments
  alter column author_id drop not null;

alter table public.chart_comments
  drop constraint chart_comments_author_id_fkey;

alter table public.chart_comments
  add constraint chart_comments_author_id_fkey
  foreign key (author_id) references public.profiles (id) on delete set null;

comment on column public.chart_comments.author_id is
  'Comment author; NULL after the author deleted their account (the comment stays visible, shown as from a deleted account).';
