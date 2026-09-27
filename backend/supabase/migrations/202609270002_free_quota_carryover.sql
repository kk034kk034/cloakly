create table public.free_quota_carryovers (
  email_hash text not null,
  usage_date date not null,
  reserved_seconds integer not null check (reserved_seconds between 1 and 1800),
  primary key (email_hash, usage_date)
);

alter table public.free_quota_carryovers enable row level security;

revoke all on public.free_quota_carryovers from public, anon, authenticated;
grant all on public.free_quota_carryovers to service_role;

create or replace function public.normalized_email_hash(p_email text)
returns text
language sql
immutable
as $$
  select case
    when p_email is null or length(trim(p_email)) = 0 then null
    else encode(
      extensions.digest(convert_to(lower(trim(p_email)), 'UTF8'), 'sha256'),
      'hex'
    )
  end;
$$;

revoke all on function public.normalized_email_hash(text) from public, anon, authenticated;

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
begin
  delete from public.free_quota_carryovers where usage_date < today;

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
  if used_today <= 0 then
    return;
  end if;

  insert into public.free_quota_carryovers(email_hash, usage_date, reserved_seconds)
  values (account_hash, today, used_today)
  on conflict (email_hash, usage_date) do update
    set reserved_seconds = excluded.reserved_seconds;
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
begin
  insert into public.profiles(id) values (new.id)
  on conflict (id) do nothing;

  account_hash := public.normalized_email_hash(new.email);
  if account_hash is null then
    return new;
  end if;

  delete from public.free_quota_carryovers where usage_date < today;

  select reserved_seconds
  into carried_seconds
  from public.free_quota_carryovers
  where email_hash = account_hash
    and usage_date = today;

  if carried_seconds is null or carried_seconds <= 0 then
    return new;
  end if;

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

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public;
