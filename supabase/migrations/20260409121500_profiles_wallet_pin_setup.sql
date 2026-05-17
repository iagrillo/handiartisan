-- Create wallet PIN support on top of Supabase Auth sessions.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  wallet_pin_hash text,
  wallet_pin_set boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists email text,
  add column if not exists wallet_pin_hash text,
  add column if not exists wallet_pin_set boolean not null default false,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create or replace function public.set_updated_at_profiles()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at_profiles();

alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid());

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles
  for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create or replace function public.set_wallet_pin(pin_hash text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, wallet_pin_hash, wallet_pin_set)
  values (auth.uid(), auth.jwt()->>'email', pin_hash, true)
  on conflict (id) do update
    set email = coalesce(excluded.email, public.profiles.email),
        wallet_pin_hash = excluded.wallet_pin_hash,
        wallet_pin_set = true,
        updated_at = now();

  return true;
end;
$$;

grant execute on function public.set_wallet_pin(text) to authenticated;

create or replace function public.verify_wallet_pin(pin_hash text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and wallet_pin_set = true
      and wallet_pin_hash = pin_hash
  );
$$;

grant execute on function public.verify_wallet_pin(text) to authenticated;
