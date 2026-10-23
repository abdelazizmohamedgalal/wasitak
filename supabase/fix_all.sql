-- وسيطك: إصلاح وتجهيز قاعدة البيانات بشكل آمن وقابل لإعادة التشغيل
-- شغّل هذا الملف مرة واحدة من Supabase > SQL Editor.
-- لا يحذف الإعلانات أو المستخدمين الموجودين.
begin;

create extension if not exists pgcrypto;

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  category text not null check (category in ('housing','jobs')),
  price numeric(12,2),
  price_text text,
  location text not null default 'بورسعيد',
  contact_phone text,
  image_urls text[] not null default '{}',
  status text not null default 'pending' check (status in ('pending','published','rejected')),
  user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.listings add column if not exists description text not null default '';
alter table public.listings add column if not exists category text;
alter table public.listings add column if not exists price numeric(12,2);
alter table public.listings add column if not exists price_text text;
alter table public.listings add column if not exists location text not null default 'بورسعيد';
alter table public.listings add column if not exists contact_phone text;
alter table public.listings add column if not exists image_urls text[] not null default '{}';
alter table public.listings add column if not exists status text not null default 'pending';
alter table public.listings add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.listings add column if not exists created_at timestamptz not null default now();
alter table public.listings add column if not exists updated_at timestamptz not null default now();
alter table public.listings add column if not exists listing_type text;
alter table public.listings add column if not exists area numeric;
alter table public.listings add column if not exists bedrooms integer;
alter table public.listings add column if not exists bathrooms integer;

create index if not exists listings_status_created_idx on public.listings(status, created_at desc);
create index if not exists listings_category_idx on public.listings(category);
create index if not exists listings_location_idx on public.listings(location);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.listings enable row level security;
alter table public.admin_users enable row level security;

drop policy if exists "Anyone can read published listings" on public.listings;
create policy "Anyone can read published listings" on public.listings
  for select to anon, authenticated using (status = 'published');

drop policy if exists "Users can submit own pending listings" on public.listings;
drop policy if exists "Authenticated users can submit listings" on public.listings;
create policy "Users can submit own pending listings" on public.listings
  for insert to authenticated
  with check (auth.uid() = user_id and status = 'pending');

drop policy if exists "Users can read own listings" on public.listings;
create policy "Users can read own listings" on public.listings
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "Users can update their own pending listings" on public.listings;
create policy "Users can update their own pending listings" on public.listings
  for update to authenticated
  using (auth.uid() = user_id and status = 'pending')
  with check (auth.uid() = user_id and status = 'pending');

drop policy if exists "Admins can read all listings" on public.listings;
create policy "Admins can read all listings" on public.listings
  for select to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "Admins can moderate listings" on public.listings;
create policy "Admins can moderate listings" on public.listings
  for update to authenticated
  using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
  with check (
    exists (select 1 from public.admin_users a where a.user_id = auth.uid())
    and status in ('pending','published','rejected')
  );

drop policy if exists "Admins can read their own admin record" on public.admin_users;
drop policy if exists "Admins can read admin list" on public.admin_users;
create policy "Admins can read their own admin record" on public.admin_users
  for select to authenticated using (user_id = auth.uid());

grant select on public.listings to anon, authenticated;
grant insert, update on public.listings to authenticated;
grant select on public.admin_users to authenticated;

insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Public can view listing images" on storage.objects;
create policy "Public can view listing images" on storage.objects
  for select to anon, authenticated using (bucket_id = 'listing-images');

drop policy if exists "Users upload images to their own folder" on storage.objects;
drop policy if exists "Authenticated users upload listing images" on storage.objects;
create policy "Users upload images to their own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'listing-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Users delete images in their own folder" on storage.objects;
create policy "Users delete images in their own folder" on storage.objects
  for delete to authenticated
  using (bucket_id = 'listing-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- يسجل المدير المحدد فقط إذا كان حسابه موجودًا بالفعل في Auth.
-- إذا لم يوجد، أنشئ الحساب أولًا ثم أعد تشغيل هذا الجزء بعد ذلك.
insert into public.admin_users (user_id)
select id from auth.users
where lower(email) = lower('abdelazizmohamedgalal@gmail.com')
on conflict (user_id) do nothing;

commit;

-- فحص بعد التنفيذ: يجب أن يظهر الجدولان listings و admin_users.
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('listings','admin_users')
order by table_name;
