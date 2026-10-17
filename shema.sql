-- Trend Traffic Exchange database schema for Supabase
-- Run this whole file in Supabase Dashboard > SQL Editor > New query.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  credits integer not null default 20 check (credits >= 0),
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.campaigns (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 4 and 80),
  kind text not null check (kind in ('website','facebook','youtube')),
  url text not null check (url ~ '^https://'),
  description text not null default '' check (char_length(description) <= 180),
  status text not null default 'active' check (status in ('active','paused','deactivated')),
  created_at timestamptz not null default now()
);

create table if not exists public.task_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  campaign_id uuid not null references public.campaigns(id) on delete cascade,
  credits_awarded integer not null default 1 check (credits_awarded = 1),
  completed_at timestamptz not null default now(),
  unique(user_id, campaign_id)
);

alter table public.profiles enable row level security;
alter table public.campaigns enable row level security;
alter table public.task_completions enable row level security;

drop policy if exists "Read own profile" on public.profiles;
create policy "Read own profile" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "Read active campaigns and own campaigns" on public.campaigns;
create policy "Read active campaigns and own campaigns" on public.campaigns for select to authenticated using (status = 'active' or user_id = auth.uid() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_admin));
drop policy if exists "Read own completions" on public.task_completions;
create policy "Read own completions" on public.task_completions for select to authenticated using (user_id = auth.uid());

-- New accounts receive 20 starter credits. Credits cannot be edited directly by browser clients.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id,email,credits) values(new.id,new.email,20)
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.create_campaign(p_title text,p_kind text,p_url text,p_description text default '')
returns uuid language plpgsql security definer set search_path = public
as $$
declare new_id uuid;
begin
  if auth.uid() is null then raise exception 'Please sign in first'; end if;
  if char_length(trim(p_title)) < 4 or char_length(trim(p_title)) > 80 then raise exception 'Title must be 4–80 characters'; end if;
  if p_kind not in ('website','facebook','youtube') then raise exception 'Invalid campaign type'; end if;
  if p_url !~ '^https://' then raise exception 'Use a valid HTTPS URL'; end if;
  if char_length(coalesce(p_description,'')) > 180 then raise exception 'Description is too long'; end if;
  update public.profiles set credits=credits-20 where id=auth.uid() and credits>=20;
  if not found then raise exception 'Not enough credits (20 required)'; end if;
  insert into public.campaigns(user_id,title,kind,url,description)
  values(auth.uid(),trim(p_title),p_kind,p_url,coalesce(trim(p_description),'')) returning id into new_id;
  return new_id;
end;
$$;

create or replace function public.complete_task(p_campaign_id uuid)
returns integer language plpgsql security definer set search_path = public
as $$
declare owner_id uuid;
begin
  if auth.uid() is null then raise exception 'Please sign in first'; end if;
  select user_id into owner_id from public.campaigns where id=p_campaign_id and status='active';
  if owner_id is null then raise exception 'Campaign is unavailable'; end if;
  if owner_id=auth.uid() then raise exception 'You cannot complete your own campaign'; end if;
  insert into public.task_completions(user_id,campaign_id) values(auth.uid(),p_campaign_id)
  on conflict(user_id,campaign_id) do nothing;
  if not found then raise exception 'You already completed this task'; end if;
  update public.profiles set credits=credits+1 where id=auth.uid();
  return 1;
end;
$$;

create or replace function public.admin_deactivate_campaign(p_campaign_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and is_admin=true) then
    raise exception 'Admin access required';
  end if;
  update public.campaigns set status='deactivated' where id=p_campaign_id;
end;
$$;

revoke all on function public.create_campaign(text,text,text,text) from public;
revoke all on function public.complete_task(uuid) from public;
revoke all on function public.admin_deactivate_campaign(uuid) from public;
grant execute on function public.create_campaign(text,text,text,text) to authenticated;
grant execute on function public.complete_task(uuid) to authenticated;
grant execute on function public.admin_deactivate_campaign(uuid) to authenticated;

grant select on public.profiles, public.campaigns, public.task_completions to authenticated;
-- Do not expose service_role keys in the website. The anon key is intended for browser use with RLS enabled.
