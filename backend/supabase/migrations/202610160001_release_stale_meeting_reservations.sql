-- Abandoned meeting reservations (app killed before finish) used to block the
-- next start for 35 minutes and surface as a generic 500 when the daily free
-- quota check fired. Release stale rows sooner, and always clear never-activated
-- "reserved" rows for the caller before creating a new session.

create or replace function public.reserve_meeting_session(p_device_id text)
returns table (
  session_id uuid,
  allowance text,
  duration_limit_seconds integer
)
language plpgsql
security definer set search_path = public
as $$
declare
  caller uuid := auth.uid();
  today date := (timezone('utc', now()))::date;
  is_pro boolean;
  new_session_id uuid;
  selected_allowance text;
  reserved_today integer;
  reserved_globally integer;
  remaining_seconds integer;
  pool_left integer;
begin
  if caller is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('free-pool:' || today::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(caller::text || ':' || today::text, 0));

  -- Never-activated reservations: always free for this caller.
  update public.meeting_sessions
  set status = 'failed'
  where user_id = caller
    and status = 'reserved';

  -- Active sessions abandoned without finish_meeting_session.
  update public.meeting_sessions
  set status = 'failed'
  where user_id = caller
    and status = 'active'
    and created_at < now() - interval '3 minutes';

  delete from public.usage_ledger u
  using public.meeting_sessions s
  where u.meeting_session_id = s.id
    and s.user_id = caller
    and s.status = 'failed';

  -- Global free-pool cleanup for abandoned free sessions.
  update public.meeting_sessions
  set status = 'failed'
  where allowance = 'free_daily'
    and status in ('reserved', 'active')
    and created_at < now() - interval '3 minutes';

  delete from public.usage_ledger u
  using public.meeting_sessions s
  where u.meeting_session_id = s.id
    and u.usage_date = today
    and s.allowance = 'free_daily'
    and s.status = 'failed';

  is_pro := public.caller_is_pro();
  perform public.claim_free_device(p_device_id);

  selected_allowance := case when is_pro then 'pro' else 'free_daily' end;

  if not is_pro then
    select coalesce(sum(u.reserved_seconds), 0)
    into reserved_today
    from public.usage_ledger u
    where u.user_id = caller
      and u.usage_date = today
      and u.allowance = 'free_daily';

    remaining_seconds := 1800 - reserved_today;
    if remaining_seconds <= 0 then
      raise exception using errcode = 'P0001', message = 'FREE_DAILY_LIMIT_REACHED';
    end if;

    select coalesce(sum(u.reserved_seconds), 0)
    into reserved_globally
    from public.usage_ledger u
    where u.usage_date = today
      and u.allowance = 'free_daily';

    pool_left := 86400 - reserved_globally;
    if pool_left <= 0 then
      raise exception using errcode = 'P0001', message = 'FREE_POOL_EXHAUSTED';
    end if;
    remaining_seconds := least(remaining_seconds, pool_left);
  else
    remaining_seconds := 1800;
  end if;

  insert into public.meeting_sessions(
    user_id, allowance, duration_limit_seconds
  ) values (
    caller, selected_allowance, remaining_seconds
  ) returning id into new_session_id;

  insert into public.usage_ledger(
    user_id, meeting_session_id, usage_date, allowance, reserved_seconds
  ) values (
    caller,
    new_session_id,
    today,
    selected_allowance,
    remaining_seconds
  );

  return query select new_session_id, selected_allowance, remaining_seconds;
end;
$$;

revoke all on function public.reserve_meeting_session(text) from public, anon;
grant execute on function public.reserve_meeting_session(text) to authenticated;
