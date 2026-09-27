create or replace function public.purge_account_references(p_user_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  delete from public.webhook_events
  where event_id = 'sync:' || p_user_id::text
     or position(p_user_id::text in payload::text) > 0;
end;
$$;

revoke all on function public.purge_account_references(uuid) from public;
grant execute on function public.purge_account_references(uuid) to service_role;
