alter table public.meeting_sessions
  add column if not exists actual_duration_seconds integer not null default 0
    check (actual_duration_seconds between 0 and 1800);

alter table public.usage_ledger
  add column if not exists reserved_seconds integer not null default 1800
    check (reserved_seconds between 0 and 1800),
  add column if not exists used_seconds integer not null default 0
    check (used_seconds between 0 and 1800);

-- Rows created by the first version represented a full daily reservation.
-- Keep them conservative when upgrading an already-used project.
update public.usage_ledger
set reserved_seconds = 1800,
    used_seconds = 1800
where reserved_seconds = 1800 and used_seconds = 0;

drop index if exists public.usage_one_free_meeting_per_utc_day;

create or replace function public.reserve_meeting_session()
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
  is_pro boolean;
  new_session_id uuid;
  selected_allowance text;
  reserved_today integer;
  remaining_seconds integer;
begin
  if caller is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(caller::text || ':' || (timezone('utc', now()))::date::text, 0)
  );

  -- Abandoned reservations cannot consume a user's next day of testing.
  update public.meeting_sessions
  set status = 'failed'
  where user_id = caller
    and status in ('reserved', 'active')
    and created_at < now() - interval '35 minutes';

  delete from public.usage_ledger u
  using public.meeting_sessions s
  where u.meeting_session_id = s.id
    and s.user_id = caller
    and s.status = 'failed';

  select exists (
    select 1 from public.entitlements e
    where e.user_id = caller
      and e.status = 'active'
      and (e.expires_at is null or e.expires_at > now())
  ) into is_pro;

  selected_allowance := case when is_pro then 'pro' else 'free_daily' end;

  if not is_pro then
    select coalesce(sum(u.reserved_seconds), 0)
    into reserved_today
    from public.usage_ledger u
    where u.user_id = caller
      and u.usage_date = (timezone('utc', now()))::date
      and u.allowance = 'free_daily';

    remaining_seconds := 1800 - reserved_today;
    if remaining_seconds <= 0 then
      raise exception using errcode = 'P0001', message = 'FREE_DAILY_LIMIT_REACHED';
    end if;
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
    (timezone('utc', now()))::date,
    selected_allowance,
    remaining_seconds
  );

  return query select new_session_id, selected_allowance, remaining_seconds;
end;
$$;

create or replace function public.finish_meeting_session(
  p_session_id uuid,
  p_duration_seconds integer default 0
)
returns boolean
language plpgsql
security definer set search_path = public
as $$
declare
  caller uuid := auth.uid();
  session_row public.meeting_sessions%rowtype;
  actual_seconds integer;
begin
  if caller is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  select * into session_row
  from public.meeting_sessions
  where id = p_session_id and user_id = caller
  for update;

  if not found then return false; end if;
  if session_row.status in ('completed', 'failed') then return true; end if;

  actual_seconds := least(
    session_row.duration_limit_seconds,
    greatest(
      1,
      coalesce(p_duration_seconds, 0),
      ceil(extract(epoch from (now() - session_row.created_at)))::integer
    )
  );

  update public.meeting_sessions
  set status = 'completed',
      actual_duration_seconds = actual_seconds,
      ended_at = now()
  where id = p_session_id;

  update public.usage_ledger
  set reserved_seconds = actual_seconds,
      used_seconds = actual_seconds
  where meeting_session_id = p_session_id;

  return true;
end;
$$;

revoke all on function public.finish_meeting_session(uuid, integer) from public;
grant execute on function public.finish_meeting_session(uuid, integer) to authenticated;
