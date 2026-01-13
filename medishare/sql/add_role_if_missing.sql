-- Safely add 'role' and 'is_verified' columns if they are missing
-- Run this in Supabase SQL editor

ALTER TABLE IF EXISTS public.users_profile
  ADD COLUMN IF NOT EXISTS role text NOT NULL DEFAULT 'user';

ALTER TABLE IF EXISTS public.users_profile
  ADD COLUMN IF NOT EXISTS is_verified boolean DEFAULT false;

-- Optionally set admin role for the known admin email
UPDATE public.users_profile SET role = 'admin' WHERE email = 'nfahad066@gmail.com';

-- Safely add 'password' column for legacy fallback
ALTER TABLE IF EXISTS public.users_profile
  ADD COLUMN IF NOT EXISTS password text;

-- Optionally set admin password for quick login (legacy)
UPDATE public.users_profile SET password = '12345678' WHERE email = 'nfahad066@gmail.com';
