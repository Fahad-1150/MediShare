-- ============================================================================
-- MediShare Complete Database Schema for Supabase
-- ============================================================================
-- Execute all SQL statements in order in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. USERS PROFILE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.users_profile (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text,
  location_url text,
  role text NOT NULL DEFAULT 'user',
  is_verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- RLS: Users can read their own profile
ALTER TABLE public.users_profile ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.users_profile
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users_profile
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admin can view all profiles" ON public.users_profile
  FOR SELECT USING ((SELECT role FROM public.users_profile WHERE id = auth.uid()) = 'admin');

-- ============================================================================
-- 2. DONATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.donations (
  id text PRIMARY KEY,
  donor_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  medicine_name text NOT NULL,
  quantity integer NOT NULL,
  dosage text,
  expiry_date date NOT NULL,
  location_url text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  approved_by uuid REFERENCES public.users_profile(id) ON DELETE SET NULL,
  claimed_by_user_id uuid REFERENCES public.users_profile(id) ON DELETE SET NULL,
  claimed_at timestamptz,
  admin_notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_donations_status ON public.donations(status);
CREATE INDEX IF NOT EXISTS idx_donations_donor_id ON public.donations(donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_claimed_by ON public.donations(claimed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_donations_expiry_date ON public.donations(expiry_date);
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON public.donations(created_at DESC);

-- RLS: Users can view all donations, create their own
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view approved donations" ON public.donations
  FOR SELECT USING (status = 'approved' OR auth.uid() = donor_id);

CREATE POLICY "Users can create donations" ON public.donations
  FOR INSERT WITH CHECK (auth.uid() = donor_id);

CREATE POLICY "Users can update own donations" ON public.donations
  FOR UPDATE USING (auth.uid() = donor_id);

CREATE POLICY "Admin can view all donations" ON public.donations
  FOR SELECT USING ((SELECT role FROM public.users_profile WHERE id = auth.uid()) = 'admin');

-- ============================================================================
-- 3. REQUESTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.requests (
  id text PRIMARY KEY,
  requester_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  medicine_name text NOT NULL,
  quantity integer NOT NULL,
  reason text NOT NULL,
  location_url text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  fulfilled_by_donation_id text REFERENCES public.donations(id) ON DELETE SET NULL,
  fulfilled_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_requests_status ON public.requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_requester_id ON public.requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_requests_created_at ON public.requests(created_at DESC);

-- RLS: Users can view their own requests and all open requests
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own requests" ON public.requests
  FOR SELECT USING (auth.uid() = requester_id);

CREATE POLICY "Anyone can view open requests" ON public.requests
  FOR SELECT USING (status = 'open');

CREATE POLICY "Users can create requests" ON public.requests
  FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Users can update own requests" ON public.requests
  FOR UPDATE USING (auth.uid() = requester_id);

-- ============================================================================
-- 4. REPORTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.reports (
  id text PRIMARY KEY,
  reporter_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  donation_id text NOT NULL REFERENCES public.donations(id) ON DELETE CASCADE,
  reason text NOT NULL,
  description text,
  photo_urls text[] DEFAULT ARRAY[]::text[],
  status text NOT NULL DEFAULT 'pending',
  admin_notes text,
  resolution text,
  created_at timestamptz DEFAULT now(),
  resolved_at timestamptz,
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_donation_id ON public.reports(donation_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);

-- RLS: Users can view their own reports, admins can view all
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own reports" ON public.reports
  FOR SELECT USING (auth.uid() = reporter_id);

CREATE POLICY "Users can create reports" ON public.reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Admin can view all reports" ON public.reports
  FOR SELECT USING ((SELECT role FROM public.users_profile WHERE id = auth.uid()) = 'admin');

-- ============================================================================
-- 5. NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  related_id text,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- RLS: Users can view their own notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================
-- After creating the above tables, insert sample data:

-- Create admin user via Supabase Auth first, then run:
-- INSERT INTO public.users_profile (id, full_name, email, phone, role)
-- VALUES (
--   'admin-uuid-here',
--   'Admin User',
--   'admin@medishare.com',
--   '+1234567890',
--   'admin'
-- );

-- ============================================================================
-- CLEANUP (Optional - removes old mock data)
-- ============================================================================
-- DELETE FROM public.users_profile WHERE email IN (
--   'nfahad066@gmail.com',
--   'fahad@gmail.com',
--   'jane@example.com',
--   'ahmed@example.com'
-- );
