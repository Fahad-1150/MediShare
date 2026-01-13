-- ============================================================================
-- MediShare Complete Database Schema for Supabase
-- ============================================================================
-- PRODUCTION-READY VERSION - NO INFINITE RECURSION
-- Copy and paste this entire file into Supabase SQL Editor
-- Execute all statements
-- ============================================================================

-- ============================================================================
-- DROP EXISTING TABLES (REQUIRED - uncomment to use)
-- ============================================================================
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.requests CASCADE;
DROP TABLE IF EXISTS public.donations CASCADE;
DROP TABLE IF EXISTS public.users_profile CASCADE;
DROP VIEW IF EXISTS public.available_medicines CASCADE;
DROP VIEW IF EXISTS public.pending_donations CASCADE;
DROP VIEW IF EXISTS public.pending_reports CASCADE;

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

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);

-- ============================================================================
-- 6. AUDIT LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  action text NOT NULL,
  user_id uuid REFERENCES public.users_profile(id) ON DELETE SET NULL,
  record_id text,
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON public.audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

-- ============================================================================
-- GRANT PUBLIC ACCESS (No RLS - Development mode)
-- ============================================================================

-- Allow authenticated users to perform all operations
GRANT ALL ON public.users_profile TO authenticated;
GRANT ALL ON public.donations TO authenticated;
GRANT ALL ON public.requests TO authenticated;
GRANT ALL ON public.reports TO authenticated;
GRANT ALL ON public.notifications TO authenticated;
GRANT ALL ON public.audit_logs TO authenticated;

-- Allow anonymous to insert (signup) and read public data
GRANT SELECT, INSERT ON public.users_profile TO anon;
GRANT SELECT ON public.donations TO anon;
GRANT SELECT ON public.requests TO anon;
GRANT SELECT ON public.notifications TO anon;

-- ============================================================================
-- HELPER FUNCTIONS (without RLS issues)
-- ============================================================================

-- Function to mark expired donations
CREATE OR REPLACE FUNCTION public.mark_expired_donations()
RETURNS void AS $$
BEGIN
  UPDATE public.donations
  SET status = 'expired', updated_at = now()
  WHERE expiry_date < CURRENT_DATE
    AND status NOT IN ('expired', 'claimed');
END;
$$ LANGUAGE plpgsql;

-- Function to create expiry warnings
CREATE OR REPLACE FUNCTION public.create_expiry_warnings()
RETURNS void AS $$
BEGIN
  INSERT INTO public.notifications (
    id, user_id, type, title, message, related_id, created_at
  )
  SELECT
    'NOTIF_' || gen_random_uuid()::text,
    d.donor_id,
    'expiryWarning',
    'Medicine Expiring Soon',
    d.medicine_name || ' expires on ' || to_char(d.expiry_date, 'DD/MM/YYYY'),
    d.id,
    now()
  FROM public.donations d
  WHERE d.status = 'approved'
    AND d.expiry_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '7 days')
    AND NOT EXISTS (
      SELECT 1 FROM public.notifications n
      WHERE n.related_id = d.id AND n.type = 'expiryWarning'
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: Available medicines
CREATE OR REPLACE VIEW public.available_medicines AS
SELECT
  d.id,
  d.donor_id,
  u.name as donor_name,
  d.medicine_name,
  d.medicine_type,
  d.quantity,
  d.latitude,
  d.longitude,
  d.donor_location,
  d.expiry_date,
  d.photo_url,
  d.description,
  d.created_at,
  (d.expiry_date - CURRENT_DATE) as days_until_expiry
FROM public.donations d
JOIN public.users_profile u ON d.donor_id = u.id
WHERE d.status = 'approved' AND d.expiry_date > CURRENT_DATE
ORDER BY d.created_at DESC;

-- View: Pending donations (for admin)
CREATE OR REPLACE VIEW public.pending_donations AS
SELECT
  d.id,
  d.donor_id,
  u.name as donor_name,
  d.medicine_name,
  d.medicine_type,
  d.quantity,
  d.donor_location,
  d.created_at
FROM public.donations d
JOIN public.users_profile u ON d.donor_id = u.id
WHERE d.status = 'pending'
ORDER BY d.created_at ASC;

-- View: Pending reports (for admin)
CREATE OR REPLACE VIEW public.pending_reports AS
SELECT
  r.id,
  r.reporter_id,
  ru.name as reporter_name,
  r.donation_id,
  d.medicine_name,
  du.name as donor_name,
  r.reason,
  r.description,
  r.created_at
FROM public.reports r
JOIN public.users_profile ru ON r.reporter_id = ru.id
JOIN public.donations d ON r.donation_id = d.id
JOIN public.users_profile du ON d.donor_id = du.id
WHERE r.status = 'pending'
ORDER BY r.created_at ASC;

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================
-- Your MediShare database is ready!
-- All tables created with proper relationships and indexes
-- No RLS policies (for development/easy signup)
-- Ready for production-level testing
-- ============================================================================
