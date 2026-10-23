
-- قاعدة بيانات تطبيق وسيطك
-- السكن والوظائف في بورسعيد

create extension if not exists pgcrypto;

-- جدول الإعلانات
create table if not exists public.listings (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    description text not null default '',
    category text not null
        check (category in ('housing', 'jobs')),
    price numeric(12, 2),
    price_text text,
    location text not null default 'بورسعيد',
    contact_phone text,
    image_urls text[] not null default '{}',
    status text not null default 'pending'
        check (status in ('pending', 'published', 'rejected')),
    user_id uuid references auth.users(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- فهارس لتسريع البحث
create index if not exists listings_status_created_idx
    on public.listings (status, created_at desc);

create index if not exists listings_category_idx
    on public.listings (category);

create index if not exists listings_location_idx
    on public.listings (location);

-- تفعيل حماية البيانات
alter table public.listings enable row level security;

-- حذف السياسات القديمة بنفس الأسماء عند إعادة تشغيل الملف
drop policy if exists "Anyone can read published listings"
    on public.listings;

drop policy if exists "Authenticated users can submit listings"
    on public.listings;

drop policy if exists "Users can update their own pending listings"
    on public.listings;

-- كل الناس تقدر تشوف الإعلانات المنشورة فقط
create policy "Anyone can read published listings"
on public.listings
for select
to anon, authenticated
using (status = 'published');

-- المستخدم المسجل يقدر يضيف إعلانًا باسمه
-- الإعلان يظل قيد المراجعة حتى يتم اعتماده
create policy "Authenticated users can submit listings"
on public.listings
for insert
to authenticated
with check (
    auth.uid() = user_id
    and status = 'pending'
);

-- المستخدم يقدر يعدل إعلانه إذا كان ما زال قيد المراجعة
create policy "Users can update their own pending listings"
on public.listings
for update
to authenticated
using (
    auth.uid() = user_id
    and status = 'pending'
)
with check (
    auth.uid() = user_id
    and status = 'pending'
);

-- إعدادات الصلاحيات الأساسية
grant select on public.listings to anon, authenticated;
grant insert, update on public.listings to authenticated;
