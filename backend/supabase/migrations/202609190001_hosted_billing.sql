create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  entitlement_id text not null default 'pro',
  status text not null check (status in ('active', 'expired')),
  product_id text,
  expires_at timestamptz,
  event_timestamp_ms bigint not null default 0,
  updated_at timestamptz not null default now()
);

create table public.meeting_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  allowance text not null check (allowance in ('free_daily', 'pro')),
  duration_limit_seconds integer not null default 1800
    check (duration_limit_seconds between 1 and 1800),
  status text not null default 'reserved'
    check (status in ('reserved', 'active', 'completed', 'failed')),
  created_at timestamptz not null default now(),
  ended_at timestamptz
);

create table public.usage_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  meeting_session_id uuid not null unique
    references public.meeting_sessions(id) on delete cascade,
  usage_date date not null default (timezone('utc', now()))::date,
  allowance text not null check (allowance in ('free_daily', 'pro')),
  created_at timestamptz not null default now()
);

create unique index usage_one_free_meeting_per_utc_day
  on public.usage_ledger(user_id, usage_date)
  where allowance = 'free_daily';

create table public.webhook_events (
  event_id text primary key,
  event_type text not null,
  payload jsonb not null,
  received_at timestamptz not null default now()
);

create index meeting_sessions_user_created_idx
  on public.meeting_sessions(user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.entitlements enable row level security;
alter table public.meeting_sessions enable row level security;
alter table public.usage_ledger enable row level security;
alter table public.webhook_events enable row level security;

grant usage on schema public to authenticated, service_role;
grant select on public.profiles to authenticated;
grant select on public.entitlements to authenticated;
grant select on public.meeting_sessions to authenticated;
grant select on public.usage_ledger to authenticated;
grant all on public.profiles to service_role;
grant all on public.entitlements to service_role;
grant all on public.meeting_sessions to service_role;
grant all on public.usage_ledger to service_role;
grant all on public.webhook_events to service_role;
grant usage, select on sequence public.usage_ledger_id_seq to service_role;

create policy "users read own profile"
  on public.profiles for select
  using (id = auth.uid());

create policy "users read own entitlement"
  on public.entitlements for select
  using (user_id = auth.uid());

create policy "users read own meeting sessions"
  on public.meeting_sessions for select
  using (user_id = auth.uid());

create policy "users read own usage"
  on public.usage_ledger for select
  using (user_id = auth.uid());

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles(id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

insert into public.profiles(id)
select id from auth.users
on conflict (id) do nothing;

revoke all on function public.handle_new_user() from public;

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
begin
  if caller is null then
    raise exception using errcode = '28000', message = 'AUTH_REQUIRED';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(caller::text || ':' || (timezone('utc', now()))::date::text, 0)
  );

  update public.meeting_sessions
  set status = 'failed'
  where user_id = caller
    and status = 'reserved'
    and created_at < now() - interval '5 minutes';

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

  if not is_pro and exists (
    select 1 from public.usage_ledger u
    where u.user_id = caller
      and u.usage_date = (timezone('utc', now()))::date
      and u.allowance = 'free_daily'
  ) then
    raise exception using errcode = 'P0001', message = 'FREE_DAILY_LIMIT_REACHED';
  end if;

  insert into public.meeting_sessions(user_id, allowance)
  values (caller, selected_allowance)
  returning id into new_session_id;

  insert into public.usage_ledger(
    user_id, meeting_session_id, usage_date, allowance
  ) values (
    caller,
    new_session_id,
    (timezone('utc', now()))::date,
    selected_allowance
  );

  return query select new_session_id, selected_allowance, 1800;
end;
$$;

create or replace function public.has_hosted_ai_access()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select auth.uid() is not null and (
    exists (
      select 1 from public.entitlements e
      where e.user_id = auth.uid()
        and e.status = 'active'
        and (e.expires_at is null or e.expires_at > now())
    )
    or exists (
      select 1 from public.usage_ledger u
      where u.user_id = auth.uid()
        and u.usage_date = (timezone('utc', now()))::date
    )
  );
$$;

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
begin
  insert into public.webhook_events(event_id, event_type, payload)
  values (p_event_id, p_event_type, p_payload)
  on conflict (event_id) do nothing;
  get diagnostics inserted = row_count;
  if inserted = 0 then return false; end if;

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

revoke all on function public.reserve_meeting_session() from public;
revoke all on function public.has_hosted_ai_access() from public;
revoke all on function public.apply_revenuecat_event(
  text, text, uuid, text, text, text, timestamptz, bigint, jsonb
) from public;

grant execute on function public.reserve_meeting_session() to authenticated;
grant execute on function public.has_hosted_ai_access() to authenticated;
grant execute on function public.apply_revenuecat_event(
  text, text, uuid, text, text, text, timestamptz, bigint, jsonb
) to service_role;
