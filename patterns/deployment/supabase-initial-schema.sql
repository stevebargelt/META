/*
 * Supabase Initial Schema: profiles + todos
 *
 * Creates:
 * - public.profiles (synced from auth.users)
 * - public.todos with status/priority, assignment, timestamps
 * - triggers for profile creation and updated_at
 * - RLS policies for profiles and todos
 *
 * Usage: copy to supabase/migrations/YYYYMMDD_initial_schema.sql
 * Source: test-app-2 (2026-01)
 * Pattern: profiles table synced to auth.users + todos table with RLS
 */

-- =============================================================================
-- Initial schema: profiles + todos tables, triggers, and RLS policies
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Profiles table (synced from auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  email text not null,
  created_at timestamptz not null default now()
);

-- Trigger: auto-create profile on new auth.users signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- RLS for profiles
alter table public.profiles enable row level security;

create policy "Authenticated users can view all profiles"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- Todos table
-- ---------------------------------------------------------------------------
create table public.todos (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) <= 200),
  description text check (char_length(description) <= 2000),
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'done')),
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  due_date date,
  assigned_to uuid references public.profiles (id) on delete set null,
  created_by uuid not null references auth.users (id) on delete cascade default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigger: auto-update updated_at on row change
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger on_todo_updated
  before update on public.todos
  for each row execute function public.handle_updated_at();

-- Indexes
create index todos_assigned_to_idx on public.todos (assigned_to);
create index todos_created_by_idx on public.todos (created_by);
create index todos_status_idx on public.todos (status);
create index todos_due_date_idx on public.todos (due_date);

-- RLS for todos
alter table public.todos enable row level security;

create policy "Authenticated users can view all todos"
  on public.todos for select
  to authenticated
  using (true);

create policy "Authenticated users can create todos"
  on public.todos for insert
  to authenticated
  with check (true);

create policy "Creators can update own todos"
  on public.todos for update
  to authenticated
  using (created_by = auth.uid())
  with check (created_by = auth.uid());

create policy "Creators can delete own todos"
  on public.todos for delete
  to authenticated
  using (created_by = auth.uid());
