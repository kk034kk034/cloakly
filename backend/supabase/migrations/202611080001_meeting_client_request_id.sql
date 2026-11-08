-- Lets a client release a reservation after its own request timed out, before
-- it learned the server session id. Old clients keep sending sessionId only.

alter table public.meeting_sessions
  add column if not exists client_request_id text;

create unique index if not exists meeting_sessions_user_client_request_idx
  on public.meeting_sessions (user_id, client_request_id)
  where client_request_id is not null;
