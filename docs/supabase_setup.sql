-- Run this once in Supabase Dashboard > SQL Editor.
-- It enables authenticated users to read and publish posts, and lets authors
-- remove their own posts. Configure post-images storage policies separately.

-- Required dashboard configuration (cannot be set by SQL in this project):
-- 1. Authentication > URL Configuration > Additional Redirect URLs:
--    add equiharmony://reset-password
-- 2. Storage > post-images: create policies that allow authenticated users
--    to insert objects and public users to read objects.

-- Chat replies and forwarding.
alter table public.messages add column if not exists reply_to_id uuid;
alter table public.messages add column if not exists reply_to_text text;
alter table public.messages add column if not exists reply_to_sender_name text;

-- User presence: each active session has an entry time and an exit time.
create table if not exists public.user_presence_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entered_at timestamptz not null default now(),
  exited_at timestamptz
);

alter table public.user_presence_sessions enable row level security;
drop policy if exists "Users manage their own presence" on public.user_presence_sessions;
create policy "Users manage their own presence"
on public.user_presence_sessions for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

-- FCM device registration. Each user may register more than one phone.
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

alter table public.device_tokens enable row level security;
drop policy if exists "Users manage their device tokens" on public.device_tokens;
create policy "Users manage their device tokens"
on public.device_tokens for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table public.posts enable row level security;

drop policy if exists "Authenticated users read posts" on public.posts;
create policy "Authenticated users read posts"
on public.posts for select to authenticated using (true);

drop policy if exists "Users create their own posts" on public.posts;
create policy "Users create their own posts"
on public.posts for insert to authenticated
with check (author_id = auth.uid());

drop policy if exists "Users delete their own posts" on public.posts;
create policy "Users delete their own posts"
on public.posts for delete to authenticated
using (author_id = auth.uid());

-- Post-specific comments and replies.
create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  author_name text not null,
  text text not null check (char_length(trim(text)) > 0),
  parent_id uuid references public.post_comments(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.post_comments enable row level security;

drop policy if exists "Authenticated users read post comments" on public.post_comments;
create policy "Authenticated users read post comments"
on public.post_comments for select to authenticated using (true);

drop policy if exists "Users create their own post comments" on public.post_comments;
create policy "Users create their own post comments"
on public.post_comments for insert to authenticated
with check (author_id = auth.uid());

drop policy if exists "Users delete their own post comments" on public.post_comments;
create policy "Users delete their own post comments"
on public.post_comments for delete to authenticated
using (author_id = auth.uid());

-- Shared care plans. owner_id receives completion notifications;
-- caregiver_id is the user responsible for administering the task.
create table if not exists public.shared_care_tasks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  caregiver_id uuid not null references auth.users(id) on delete cascade,
  horse_name text not null,
  item_name text not null,
  category text not null check (category in ('medication', 'food', 'supplement')),
  scheduled_for timestamptz not null,
  notes text not null default '',
  completed_at timestamptz,
  completed_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

alter table public.shared_care_tasks enable row level security;

drop policy if exists "Participants read shared care" on public.shared_care_tasks;
create policy "Participants read shared care"
on public.shared_care_tasks for select to authenticated
using (owner_id = auth.uid() or caregiver_id = auth.uid());

drop policy if exists "Participants schedule shared care" on public.shared_care_tasks;
drop policy if exists "Owners schedule shared care" on public.shared_care_tasks;
create policy "Participants schedule shared care"
on public.shared_care_tasks for insert to authenticated
with check (owner_id = auth.uid() or caregiver_id = auth.uid());

drop policy if exists "Caregivers complete shared care" on public.shared_care_tasks;
create policy "Caregivers complete shared care"
on public.shared_care_tasks for update to authenticated
using (caregiver_id = auth.uid())
with check (caregiver_id = auth.uid());

-- In Database > Replication, enable Realtime for shared_care_tasks.
-- For an alert on another phone, deploy an Edge Function or Firebase Cloud
-- Function triggered after completed_at changes. It must read the owner's
-- saved FCM token and send the push notification using server credentials.