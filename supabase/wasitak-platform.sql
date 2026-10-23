-- وسيطك: database setup for the new website/app
-- Run this in Supabase SQL Editor. Back up any existing data before applying changes.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.listings add column if not exists listing_type text;
alter table public.listings add column if not exists area numeric;
alter table public.listings add column if not exists bedrooms integer;
alter table public.listings add column if not exists bathrooms integer;
alter table public.listings add column if not exists updated_at timestamptz not null default now();

alter table public.listings enable row level security;
alter table public.admin_users enable row level security;

drop policy if exists "Anyone can read published listings" on public.listings;
create policy "Anyone can read published listings" on public.listings
for select to anon, authenticated using (status = 'published');

drop policy if exists "Users can submit own pending listings" on public.listings;
create policy "Users can submit own pending listings" on public.listings
for insert to authenticated with check (auth.uid() = user_id and status = 'pending');

drop policy if exists "Admins can read all listings" on public.listings;
create policy "Admins can read all listings" on public.listings
for select to authenticated using (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
);

drop policy if exists "Admins can moderate listings" on public.listings;
create policy "Admins can moderate listings" on public.listings
for update to authenticated using (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
) with check (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
);

drop policy if exists "Users can read own listings" on public.listings;
create policy "Users can read own listings" on public.listings
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "Admins can read admin list" on public.admin_users;
create policy "Admins can read admin list" on public.admin_users
for select to authenticated using (user_id = auth.uid());

grant select on public.listings to anon, authenticated;
grant insert, update on public.listings to authenticated;
grant select on public.admin_users to authenticated;

insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Authenticated users upload listing images" on storage.objects;
create policy "Authenticated users upload listing images" on storage.objects
for insert to authenticated with check (
  bucket_id = 'listing-images' and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Public can view listing images" on storage.objects;
create policy "Public can view listing images" on storage.objects
for select to anon, authenticated using (bucket_id = 'listing-images');

-- SECURITY: create the admin user's account first using Supabase Auth.
-- Then run the following separately after replacing UUID with that account's auth.users.id:
-- insert into public.admin_users (user_id) values ('YOUR-AUTH-USER-UUID');
