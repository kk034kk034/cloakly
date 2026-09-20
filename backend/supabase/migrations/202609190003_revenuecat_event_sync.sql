create or replace function public.apply_revenuecat_event(
  p_event_id text,
  p_event_type text,
  p_user_id uuid,
  p_entitlement_id text,
  p_status text,
  p_product_id text,
  p_expires_at timestamptz,
  p_event_timestamp_ms bigint,
  p_payload jsonb
)
returns boolean
language plpgsql
security definer set search_path = public
as $$
declare
  inserted integer;
  is_sync boolean := left(p_event_id, 5) = 'sync:';
begin
  if is_sync then
    insert into public.webhook_events(event_id, event_type, payload)
    values (p_event_id, p_event_type, p_payload)
    on conflict (event_id) do update set
      event_type = excluded.event_type,
      payload = excluded.payload,
      received_at = now();
  else
    insert into public.webhook_events(event_id, event_type, payload)
    values (p_event_id, p_event_type, p_payload)
    on conflict (event_id) do nothing;
    get diagnostics inserted = row_count;
    if inserted = 0 then return false; end if;
  end if;

  insert into public.entitlements(
    user_id, entitlement_id, status, product_id, expires_at,
    event_timestamp_ms, updated_at
  ) values (
    p_user_id, p_entitlement_id, p_status, p_product_id, p_expires_at,
    p_event_timestamp_ms, now()
  )
  on conflict (user_id) do update set
    entitlement_id = excluded.entitlement_id,
    status = excluded.status,
    product_id = excluded.product_id,
    expires_at = excluded.expires_at,
    event_timestamp_ms = excluded.event_timestamp_ms,
    updated_at = now()
  where public.entitlements.event_timestamp_ms <= excluded.event_timestamp_ms;

  return true;
end;
$$;
