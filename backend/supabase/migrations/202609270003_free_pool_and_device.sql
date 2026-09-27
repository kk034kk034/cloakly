-- Global free meeting pool is 24 hours (48 x 30 minutes) per UTC day.
-- One device may spend only one free account's quota that day: 1,800 meeting
-- seconds, 5 project questions, and 5 plan suggestions. Pro does not consume it.

create table public.free_device_claims (
  device_hash text not null,
  usage_date date not null,
  user_id uuid not null,
  primary key (device_hash, usage_date)
);

create table public.free_ai_usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  usage_date date not null,
  action text not null check (action in ('project_question', 'project_plan')),
  used_count integer not null check (used_count between 0 and 5),
  primary key (user_id, usage_date, action)
);

create table public.free_ai_carryovers (
  email_hash text not null,
  usage_date date not null,
  question_count integer not null default 0 check (question_count between 0 and 5),
  plan_count integer not null default 0 check (plan_count between 0 and 5),
  primary key (email_hash, usage_date),
  check (question_count > 0 or plan_count > 0)
);

alter table public.free_device_claims enable row level security;
alter table public.free_ai_usage enable row level security;
alter table public.free_ai_carryovers enable row level security;

revoke all on public.free_device_claims from public, anon, authenticated;
revoke all on public.free_ai_usage from public, anon, authenticated;
revoke all on public.free_ai_carryovers from public, anon, authenticated;
grant all on public.free_device_claims to service_role;
grant all on public.free_ai_usage to service_role;
grant all on public.free_ai_carryovers to service_role;

create or replace function public.free_device_hash(p_device_id text)
returns text
language sql
immutable
as $$
  select case
    when p_device_id is null or length(trim(p_device_id)) = 0 then null
    else encode(extensions.digest(convert_to(trim(p_device_id), 'UTF8'), 'sha256'), 'hex')
  end;
$$;

revoke all on function public.free_device_hash(text) from public, anon, authenticated;

create or replace function public.caller_is_pro()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.entitlements e
    where e.user_id = auth.uid()
      and e.status = 'active'
      and (e.expires_at is null or e.expires_at > now())
  );
$$;

revoke all on function public.caller_is_pro() from public, anon;
grant execute on function public.caller_is_pro() to authenticated;

create or replace function public.claim_free_device(p_device_id text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  caller uuid := auth.uid();
  today date := (timezone('utc', now()))::date;
  device_hash text;
  claimed_user uuid;
begin
  if caller is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;
  if public.caller_is_pro() then
    return;
  end if;

  device_hash := public.free_device_hash(p_device_id);
  if device_hash is null then
    raise exception using errcode = 'P0001', message = 'DEVICE_REQUIRED';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(caller::text || ':' || today::text, 0));
  perform pg_advisory_xact_lock(hashtextextended('free-device:' || device_hash || ':' || today::text, 0));

  select user_id
  into claimed_user
  from public.free_device_claims
  where free_device_claims.device_hash = device_hash
    and usage_date = today
  for update;

  if claimed_user is null then
    insert into public.free_device_claims(device_hash, usage_date, user_id)
    values (device_hash, today, caller);
    return;
  end if;

  if claimed_user <> caller then
    raise exception using errcode = 'P0001', message = 'DEVICE_FREE_ACCOUNT_IN_USE';
  end if;
end;
$$;

revoke all on function public.claim_free_device(text) from public, anon;
grant execute on function public.claim_free_device(text) to authenticated;

create or replace function public.consume_free_ai(p_device_id text, p_action text)
returns boolean
language plpgsql
security definer set search_path = public
as $$
declare
  caller uuid := auth.uid();
  today date := (timezone('utc', now()))::date;
  new_count integer;
begin
  if caller is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;
  if p_action not in ('project_question', 'project_plan') then
    raise exception using errcode = 'P0001', message = 'INVALID_AI_ACTION';
  end if;
  if public.caller_is_pro() then
    return false;
  end if;

  perform public.claim_free_device(p_device_id);
  perform pg_advisory_xact_lock(hashtextextended(caller::text || ':' || today::text, 0));

  with upsert as (
    insert into public.free_ai_usage(user_id, usage_date, action, used_count)
    values (caller, today, p_action, 1)
    on conflict (user_id, usage_date, action)
    do update set used_count = public.free_ai_usage.used_count + 1
    where public.free_ai_usage.used_count < 5
    returning used_count
  )
  select used_count into new_count from upsert;

  if new_count is null then
    if p_action = 'project_question' then
      raise exception using errcode = 'P0001', message = 'FREE_QUESTION_LIMIT_REACHED';
    end if;
    raise exception using errcode = 'P0001', message = 'FREE_PLAN_LIMIT_REACHED';
  end if;
  return true;
end;
$$;

revoke all on function public.consume_free_ai(text, text) from public, anon;
grant execute on function public.consume_free_ai(text, text) to authenticated;

create or replace function public.release_free_ai(p_action text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null or p_action not in ('project_question', 'project_plan') then
    return;
  end if;

  update public.free_ai_usage
  set used_count = used_count - 1
  where user_id = caller
    and usage_date = (timezone('utc', now()))::date
    and action = p_action
    and used_count > 0;
end;
$$;

revoke all on function public.release_free_ai(text) from public, anon;
grant execute on function public.release_free_ai(text) to authenticated;

drop function if exists public.reserve_meeting_session();

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

  update public.meeting_sessions
  set status = 'failed'
  where allowance = 'free_daily'
    and status in ('reserved', 'active')
    and created_at < now() - interval '35 minutes';

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

create or replace function public.remember_deleted_free_usage(p_user_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  account_email text;
  account_hash text;
  today date := (timezone('utc', now()))::date;
  used_today integer;
  prior_seconds integer;
  question_count integer := 0;
  plan_count integer := 0;
  prior_questions integer := 0;
  prior_plans integer := 0;
begin
  delete from public.free_quota_carryovers where usage_date < today;
  delete from public.free_ai_carryovers where usage_date < today;

  select email into account_email from auth.users where id = p_user_id;
  account_hash := public.normalized_email_hash(account_email);
  if account_hash is null then
    return;
  end if;

  select coalesce(sum(reserved_seconds), 0)
  into used_today
  from public.usage_ledger
  where user_id = p_user_id
    and usage_date = today
    and allowance = 'free_daily';

  select reserved_seconds
  into prior_seconds
  from public.free_quota_carryovers
  where email_hash = account_hash
    and usage_date = today;

  used_today := least(1800, greatest(used_today, coalesce(prior_seconds, 0)));
  if used_today > 0 then
    insert into public.free_quota_carryovers(email_hash, usage_date, reserved_seconds)
    values (account_hash, today, used_today)
    on conflict (email_hash, usage_date) do update
      set reserved_seconds = excluded.reserved_seconds;
  end if;

  select coalesce(max(used_count) filter (where action = 'project_question'), 0),
         coalesce(max(used_count) filter (where action = 'project_plan'), 0)
  into question_count, plan_count
  from public.free_ai_usage
  where user_id = p_user_id
    and usage_date = today;

  select coalesce(max(c.question_count), 0), coalesce(max(c.plan_count), 0)
  into prior_questions, prior_plans
  from public.free_ai_carryovers c
  where c.email_hash = account_hash
    and c.usage_date = today;

  question_count := greatest(question_count, prior_questions);
  plan_count := greatest(plan_count, prior_plans);

  if question_count > 0 or plan_count > 0 then
    insert into public.free_ai_carryovers(email_hash, usage_date, question_count, plan_count)
    values (account_hash, today, question_count, plan_count)
    on conflict (email_hash, usage_date) do update
      set question_count = excluded.question_count,
          plan_count = excluded.plan_count;
  end if;
end;
$$;

revoke all on function public.remember_deleted_free_usage(uuid) from public, anon, authenticated;
grant execute on function public.remember_deleted_free_usage(uuid) to service_role;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  account_hash text;
  today date := (timezone('utc', now()))::date;
  carried_seconds integer;
  carried_session_id uuid;
  carried_questions integer := 0;
  carried_plans integer := 0;
begin
  insert into public.profiles(id) values (new.id)
  on conflict (id) do nothing;

  account_hash := public.normalized_email_hash(new.email);
  if account_hash is null then
    return new;
  end if;

  delete from public.free_quota_carryovers where usage_date < today;
  delete from public.free_ai_carryovers where usage_date < today;

  select reserved_seconds
  into carried_seconds
  from public.free_quota_carryovers
  where email_hash = account_hash
    and usage_date = today;

  if carried_seconds is not null and carried_seconds > 0 then
    insert into public.meeting_sessions(
      user_id,
      allowance,
      duration_limit_seconds,
      status,
      actual_duration_seconds,
      ended_at
    ) values (
      new.id,
      'free_daily',
      carried_seconds,
      'completed',
      carried_seconds,
      now()
    )
    returning id into carried_session_id;

    insert into public.usage_ledger(
      user_id,
      meeting_session_id,
      usage_date,
      allowance,
      reserved_seconds,
      used_seconds
    ) values (
      new.id,
      carried_session_id,
      today,
      'free_daily',
      carried_seconds,
      carried_seconds
    );
  end if;

  select coalesce(max(c.question_count), 0), coalesce(max(c.plan_count), 0)
  into carried_questions, carried_plans
  from public.free_ai_carryovers c
  where c.email_hash = account_hash
    and c.usage_date = today;

  if carried_questions > 0 then
    insert into public.free_ai_usage(user_id, usage_date, action, used_count)
    values (new.id, today, 'project_question', carried_questions);
  end if;
  if carried_plans > 0 then
    insert into public.free_ai_usage(user_id, usage_date, action, used_count)
    values (new.id, today, 'project_plan', carried_plans);
  end if;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public;
