-- WhatsApp password recovery request storage
-- Run this in the Supabase SQL Editor before using the inbound WhatsApp flow.

create table if not exists public.whatsapp_password_recoveries (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  phone text not null,
  token text not null unique,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'used', 'expired')),
  inbound_phone text,
  inbound_message text,
  recovery_link text,
  verified_at timestamptz,
  replied_at timestamptz,
  used_at timestamptz,
  expires_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_whatsapp_password_recoveries_lookup
  on public.whatsapp_password_recoveries (email, phone, token);

create index if not exists idx_whatsapp_password_recoveries_status
  on public.whatsapp_password_recoveries (status, expires_at desc);

alter table public.whatsapp_password_recoveries enable row level security;

revoke all on public.whatsapp_password_recoveries from anon, authenticated;

create or replace function public.set_updated_at_whatsapp_password_recoveries()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_whatsapp_password_recoveries_updated_at
on public.whatsapp_password_recoveries;

create trigger trg_whatsapp_password_recoveries_updated_at
before update on public.whatsapp_password_recoveries
for each row
execute function public.set_updated_at_whatsapp_password_recoveries();
