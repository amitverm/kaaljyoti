-- 0017: 24-hour edit window on discussion comments.
--
-- Editing your own comment is a typo/second-thoughts affordance, not a
-- revision mechanism: once replies exist, silently rewriting what they
-- responded to is a bait-and-switch. After 24 hours the comment is
-- locked (the UI hides Edit; this server check is the boundary).
--
-- DELETE deliberately has NO window: a user must always be able to
-- remove their own content ("deleted data must not linger" — same
-- stance as chart withdrawal), and thread integrity is preserved by
-- the deleted-placeholder row either way.

create or replace function public.edit_chart_comment(
  p_comment_id uuid,
  p_body text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication required';
  end if;
  if p_body is null or char_length(btrim(p_body)) = 0 then
    raise exception 'comment cannot be empty';
  end if;
  if char_length(p_body) > 2000 then
    raise exception 'comment too long (max 2000 characters)';
  end if;

  update public.chart_comments
    set body = btrim(p_body), edited_at = now()
    where id = p_comment_id
      and author_id = auth.uid()
      and status = 'visible'
      and created_at > now() - interval '24 hours';
  if not found then
    raise exception 'comment not found or no longer editable';
  end if;
end;
$$;
