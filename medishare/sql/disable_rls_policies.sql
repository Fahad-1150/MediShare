-- ============================================================================
-- MediShare Database Schema WITHOUT RLS POLICIES
-- ============================================================================
-- Use this if you want to disable all row-level security for development
-- Copy and paste into Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- DISABLE ALL RLS POLICIES
-- ============================================================================

-- Disable RLS on users_profile
ALTER TABLE IF EXISTS public.users_profile DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users_profile;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users_profile;
DROP POLICY IF EXISTS "Anyone can view profiles" ON public.users_profile;
DROP POLICY IF EXISTS "Admin can view all profiles" ON public.users_profile;

-- Disable RLS on donations
ALTER TABLE IF EXISTS public.donations DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view approved donations" ON public.donations;
DROP POLICY IF EXISTS "Users can create donations" ON public.donations;
DROP POLICY IF EXISTS "Users can update own donations" ON public.donations;
DROP POLICY IF EXISTS "Admin can view all donations" ON public.donations;

-- Disable RLS on requests
ALTER TABLE IF EXISTS public.requests DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own requests" ON public.requests;
DROP POLICY IF EXISTS "Anyone can view open requests" ON public.requests;
DROP POLICY IF EXISTS "Users can create requests" ON public.requests;
DROP POLICY IF EXISTS "Users can update own requests" ON public.requests;
DROP POLICY IF EXISTS "Admin can view all requests" ON public.requests;

-- Disable RLS on reports
ALTER TABLE IF EXISTS public.reports DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own reports" ON public.reports;
DROP POLICY IF EXISTS "Users can create reports" ON public.reports;
DROP POLICY IF EXISTS "Admin can view all reports" ON public.reports;
DROP POLICY IF EXISTS "Admin can update reports" ON public.reports;

-- Disable RLS on notifications
ALTER TABLE IF EXISTS public.notifications DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;

-- Disable RLS on audit_logs
ALTER TABLE IF EXISTS public.audit_logs DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- GRANT PUBLIC ACCESS TO ALL TABLES
-- ============================================================================

GRANT ALL PRIVILEGES ON public.users_profile TO authenticated, anon;
GRANT ALL PRIVILEGES ON public.donations TO authenticated, anon;
GRANT ALL PRIVILEGES ON public.requests TO authenticated, anon;
GRANT ALL PRIVILEGES ON public.reports TO authenticated, anon;
GRANT ALL PRIVILEGES ON public.notifications TO authenticated, anon;
GRANT ALL PRIVILEGES ON public.audit_logs TO authenticated, anon;

-- ============================================================================
-- Enable anonymous access for signup/login
-- ============================================================================

GRANT INSERT ON public.users_profile TO anon;
GRANT SELECT ON public.users_profile TO anon;

-- ============================================================================
-- DONE - All RLS policies removed
-- ============================================================================
