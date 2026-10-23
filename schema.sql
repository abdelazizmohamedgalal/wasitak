-- وسيطك: Supabase starter schema
-- Run this in Supabase Dashboard > SQL Editor.
-- This starter intentionally lets unauthenticated users submit pending listings,
-- but only published listings are publicly readable. Add authentication and
-- stricter anti-spam controls before public production launch.

create extension if not exists pgcrypto;

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 4 and 120),
  description text not null check (char_length(description) between 10 and 5000),
  category text not null check (category in ('housing', 'jobs')),
  area text not null default 'بورسعيد',
  price numeric(12,2),
  contact_phone text,
  image_url text,
  status text not null default 'pending'
    check (status in ('pending', 'published', 'rejected', 'expired')),
  created_at timestamptz not null default now()
);

alter table public.listings enable row level security;

drop policy if exists "Anyone can read published listings" on public.listings;
create policy "Anyone can read published listings"
on public.listings for select
to anon, authenticated
using (status = 'published');

drop policy if exists "Anyone can submit pending listings" on public.listings;
create policy "Anyone can submit pending listings"
on public.listings for insert
to anon, authenticated
with check (status = 'pending');

-- Do not create public UPDATE or DELETE policies.
-- Admin publishing should be done through a trusted server/admin workflow,
-- never by exposing the Supabase service_role key in the mobile app.
