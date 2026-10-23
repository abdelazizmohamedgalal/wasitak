-- Wasitak secure admin + listing image storage setup
-- Create the permanent account in the app first using the admin email, then run this file in Supabase SQL Editor.
-- The final INSERT registers that exact email as the first admin if the account already exists.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
drop policy if exists "Admins can read their own admin record" on public.admin_users;
create policy "Admins can read their own admin record"
  on public.admin_users for select to authenticated
  using (user_id = auth.uid());
grant select on public.admin_users to authenticated;

-- Allows an authorized admin to view all listings, including pending/rejected.
drop policy if exists "Admins can read all listings" on public.listings;
create policy "Admins can read all listings"
  on public.listings for select to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- Only admin accounts can change listing status. Restrict to moderation states.
drop policy if exists "Admins can moderate listings" on public.listings;
create policy "Admins can moderate listings"
  on public.listings for update to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
  with check (
    exists (select 1 from public.admin_users a where a.user_id = auth.uid())
    and status in ('pending', 'published', 'rejected')
  );

-- Public bucket: listing images are intentionally public when URLs are shared.
insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can view listing images" on storage.objects;
create policy "Public can view listing images"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'listing-images');

drop policy if exists "Users upload images to their own folder" on storage.objects;
create policy "Users upload images to their own folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users delete images in their own folder" on storage.objects;
create policy "Users delete images in their own folder"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'listing-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Register the designated admin account. If the account has not been created yet, create it in the app and rerun this final INSERT.
insert into public.admin_users (user_id)
select id from auth.users
where lower(email) = lower('abdelazizmohamedgalal@gmail.com')
on conflict (user_id) do nothing;
