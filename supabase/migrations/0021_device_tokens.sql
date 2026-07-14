-- 0021: Device tokens for push notifications.
--
-- One row per (user, device). The app upserts on sign-in and on FCM
-- token rotation, and deletes its token on sign-out so a shared device
-- stops receiving the previous user's pushes. The send-notification
-- edge function (triggered by a database webhook on
-- public.notifications inserts) reads these to fan out via FCM.
--
-- Owner-only RLS on every verb: tokens are push credentials — another
-- user being able to read one could direct pushes to themselves.

create table public.device_tokens (
  token      text primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  platform   text not null check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now()
);

create index idx_device_tokens_user on public.device_tokens (user_id);

comment on table public.device_tokens is
  'FCM registration tokens per signed-in device. Upserted by the app on sign-in/token rotation, deleted on sign-out; read by the send-notification edge function.';

alter table public.device_tokens enable row level security;

create policy device_tokens_select_own on public.device_tokens
  for select to authenticated using (user_id = auth.uid());

create policy device_tokens_insert_own on public.device_tokens
  for insert to authenticated with check (user_id = auth.uid());

create policy device_tokens_update_own on public.device_tokens
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy device_tokens_delete_own on public.device_tokens
  for delete to authenticated using (user_id = auth.uid());
