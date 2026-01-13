-- Create users_profile table for MediShare
-- Run this in Supabase SQL editor (or via a migration)

create table if not exists public.users_profile (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  phone text,
  location_url text,
  role text not null default 'user',
  is_verified boolean default false,
  created_at timestamptz default now()
);

-- Remove mock/demo rows (run after seeding if you had demo data inserted)
delete from public.users_profile
where email in (
  'nfahad066@gmail.com',
  'fahad@gmail.com',
  'jane@example.com',
  'ahmed@example.com'
);

-- Optional: create admin user in Supabase Auth, then set role:
-- 1) Create the user via Supabase Auth (Auth > Users or sign up with the app)
-- 2) Set role in DB:
-- update public.users_profile set role = 'admin' where email = 'nfahad066@gmail.com';
