-- ============================================================================
-- MediShare Database Schema - SIMPLE VERSION (No RLS)
-- ============================================================================
-- This version has NO row-level security policies
-- Use this for development - copy and paste entire file into Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. USERS PROFILE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.users_profile (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text NOT NULL,
  role text NOT NULL DEFAULT 'user',
  is_verified boolean DEFAULT false,
  location text DEFAULT '',
  latitude double precision DEFAULT 0.0,
  longitude double precision DEFAULT 0.0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_profile_role ON public.users_profile(role);
CREATE INDEX IF NOT EXISTS idx_users_profile_email ON public.users_profile(email);
CREATE INDEX IF NOT EXISTS idx_users_profile_created_at ON public.users_profile(created_at DESC);

-- ============================================================================
-- 2. DONATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.donations (
  id text PRIMARY KEY,
  donor_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  medicine_name text NOT NULL,
  medicine_type text NOT NULL,
  quantity integer NOT NULL,
  expiry_date date NOT NULL,
  donor_location text NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  photo_url text,
  status text NOT NULL DEFAULT 'pending',
  claimed_by_user_id uuid REFERENCES public.users_profile(id) ON DELETE SET NULL,
  admin_notes text,
  description text,
  created_at timestamptz DEFAULT now(),
  approved_at timestamptz,
  claimed_at timestamptz,
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_donations_donor_id ON public.donations(donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_status ON public.donations(status);
CREATE INDEX IF NOT EXISTS idx_donations_claimed_by_user_id ON public.donations(claimed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_donations_expiry_date ON public.donations(expiry_date);
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON public.donations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_donations_medicine_name ON public.donations(medicine_name);

-- ============================================================================
-- 3. REQUESTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.requests (
  id text PRIMARY KEY,
  requester_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  medicine_name text NOT NULL,
  medicine_type text NOT NULL,
  quantity integer NOT NULL,
  requester_location text NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  reason text,
  status text NOT NULL DEFAULT 'pending',
  assigned_donation_id text REFERENCES public.donations(id) ON DELETE SET NULL,
  admin_notes text,
  created_at timestamptz DEFAULT now(),
  fulfilled_at timestamptz,
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_requests_requester_id ON public.requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON public.requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_assigned_donation_id ON public.requests(assigned_donation_id);
CREATE INDEX IF NOT EXISTS idx_requests_created_at ON public.requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_requests_medicine_name ON public.requests(medicine_name);

-- ============================================================================
-- 4. REPORTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.reports (
  id text PRIMARY KEY,
  reporter_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  donation_id text NOT NULL REFERENCES public.donations(id) ON DELETE CASCADE,
  reason text NOT NULL,
  description text,
  photo_urls text[],
  status text NOT NULL DEFAULT 'pending',
  admin_notes text,
  resolution text,
  created_at timestamptz DEFAULT now(),
  resolved_at timestamptz,
  updated_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_donation_id ON public.reports(donation_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);

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
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);

-- ============================================================================
-- END - All tables created without RLS
-- ============================================================================
