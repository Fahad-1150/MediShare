-- ============================================================================
-- MEDISHARE - SIMPLE CLEAN SCHEMA (No RLS, No Issues)
-- ============================================================================
-- Use this if FINAL_SCHEMA.sql still has issues
-- Copy entire file into Supabase SQL Editor and execute
-- ============================================================================

-- Drop everything first
DROP VIEW IF EXISTS public.pending_reports CASCADE;
DROP VIEW IF EXISTS public.pending_donations CASCADE;
DROP VIEW IF EXISTS public.available_medicines CASCADE;
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.requests CASCADE;
DROP TABLE IF EXISTS public.donations CASCADE;
DROP TABLE IF EXISTS public.users_profile CASCADE;

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================
CREATE TABLE public.users_profile (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text NOT NULL,
  role text DEFAULT 'user',
  is_verified boolean DEFAULT false,
  location text DEFAULT '',
  latitude double precision DEFAULT 0,
  longitude double precision DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_users_role ON public.users_profile(role);
CREATE INDEX idx_users_email ON public.users_profile(email);

-- ============================================================================
-- 2. DONATIONS TABLE
-- ============================================================================
CREATE TABLE public.donations (
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
  status text DEFAULT 'pending',
  claimed_by_user_id uuid REFERENCES public.users_profile(id) ON DELETE SET NULL,
  admin_notes text,
  description text,
  created_at timestamptz DEFAULT now(),
  approved_at timestamptz,
  claimed_at timestamptz,
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_donations_donor ON public.donations(donor_id);
CREATE INDEX idx_donations_status ON public.donations(status);
CREATE INDEX idx_donations_expiry ON public.donations(expiry_date);
CREATE INDEX idx_donations_claimed ON public.donations(claimed_by_user_id);

-- ============================================================================
-- 3. REQUESTS TABLE
-- ============================================================================
CREATE TABLE public.requests (
  id text PRIMARY KEY,
  requester_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  medicine_name text NOT NULL,
  medicine_type text NOT NULL,
  quantity integer NOT NULL,
  requester_location text NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  reason text,
  status text DEFAULT 'pending',
  assigned_donation_id text REFERENCES public.donations(id) ON DELETE SET NULL,
  admin_notes text,
  created_at timestamptz DEFAULT now(),
  fulfilled_at timestamptz,
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_requests_requester ON public.requests(requester_id);
CREATE INDEX idx_requests_status ON public.requests(status);
CREATE INDEX idx_requests_assigned ON public.requests(assigned_donation_id);

-- ============================================================================
-- 4. REPORTS TABLE
-- ============================================================================
CREATE TABLE public.reports (
  id text PRIMARY KEY,
  reporter_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  donation_id text NOT NULL REFERENCES public.donations(id) ON DELETE CASCADE,
  reason text NOT NULL,
  description text,
  photo_urls text[],
  status text DEFAULT 'pending',
  admin_notes text,
  resolution text,
  created_at timestamptz DEFAULT now(),
  resolved_at timestamptz,
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX idx_reports_reporter ON public.reports(reporter_id);
CREATE INDEX idx_reports_donation ON public.reports(donation_id);
CREATE INDEX idx_reports_status ON public.reports(status);

-- ============================================================================
-- 5. NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE public.notifications (
  id text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  related_id text,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_read ON public.notifications(is_read);

-- ============================================================================
-- 6. AUDIT LOGS
-- ============================================================================
CREATE TABLE public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  action text NOT NULL,
  user_id uuid REFERENCES public.users_profile(id) ON DELETE SET NULL,
  record_id text,
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_audit_user ON public.audit_logs(user_id);

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
GRANT ALL ON public.users_profile TO authenticated;
GRANT ALL ON public.donations TO authenticated;
GRANT ALL ON public.requests TO authenticated;
GRANT ALL ON public.reports TO authenticated;
GRANT ALL ON public.notifications TO authenticated;
GRANT ALL ON public.audit_logs TO authenticated;

GRANT SELECT, INSERT ON public.users_profile TO anon;
GRANT SELECT ON public.donations TO anon;
GRANT SELECT ON public.requests TO anon;

-- ============================================================================
-- VIEWS
-- ============================================================================
CREATE VIEW public.available_medicines AS
SELECT
  d.id, d.donor_id, u.name as donor_name,
  d.medicine_name, d.medicine_type, d.quantity,
  d.latitude, d.longitude, d.donor_location,
  d.expiry_date, d.photo_url, d.description, d.created_at
FROM public.donations d
JOIN public.users_profile u ON d.donor_id = u.id
WHERE d.status = 'approved' AND d.expiry_date > CURRENT_DATE;

-- ============================================================================
-- COMPLETE
-- ============================================================================
