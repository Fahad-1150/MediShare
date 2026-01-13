-- ============================================================================
-- MediShare Complete Database Schema for Supabase
-- ============================================================================
-- Copy and paste ALL of this into Supabase SQL Editor to create all tables
-- Execute in this exact order
-- ============================================================================

-- ============================================================================
-- 1. USERS PROFILE TABLE (auth.users reference)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.users_profile (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text NOT NULL,
  role text NOT NULL DEFAULT 'user', -- 'user' or 'admin'
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

-- RLS: Row Level Security
ALTER TABLE public.users_profile ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.users_profile
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users_profile
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Anyone can view profiles" ON public.users_profile
  FOR SELECT USING (true);
CREATE POLICY "Admin can view all profiles" ON public.users_profile
  FOR SELECT USING ((SELECT role FROM public.users_profile WHERE id = auth.uid()) = 'admin');

-- ============================================================================
-- 2. DONATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.donations (
  id text PRIMARY KEY,
  donor_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  medicine_name text NOT NULL,
  medicine_type text NOT NULL, -- Tablet, Capsule, Injection, etc.
  quantity integer NOT NULL,
  expiry_date date NOT NULL,
  donor_location text NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  photo_url text,
  status text NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'claimed', 'expired', 'rejected'
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

-- RLS
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view approved donations" ON public.donations
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
  medicine_type text NOT NULL,
  quantity integer NOT NULL,
  requester_location text NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  reason text,
  status text NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'fulfilled', 'rejected', 'cancelled'
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

-- RLS
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own requests" ON public.requests
  FOR SELECT USING (auth.uid() = requester_id);
CREATE POLICY "Anyone can view open requests" ON public.requests
  FOR SELECT USING (status = 'pending' OR status = 'approved');
CREATE POLICY "Users can create requests" ON public.requests
  FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Users can update own requests" ON public.requests
  FOR UPDATE USING (auth.uid() = requester_id);
CREATE POLICY "Admin can view all requests" ON public.requests
  FOR SELECT USING ((SELECT role FROM public.users_profile WHERE id = auth.uid()) = 'admin');

-- ============================================================================
-- 4. REPORTS TABLE (Safety Reports for donations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.reports (
  id text PRIMARY KEY,
  reporter_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  donation_id text NOT NULL REFERENCES public.donations(id) ON DELETE CASCADE,
  reason text NOT NULL,
  description text,
  photo_urls text[], -- Array of URLs
  status text NOT NULL DEFAULT 'pending', -- 'pending', 'reviewing', 'resolved', 'dismissed'
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

-- RLS
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own reports" ON public.reports
  FOR SELECT USING (auth.uid() = reporter_id);
CREATE POLICY "Users can create reports" ON public.reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Admin can view all reports" ON public.reports
  FOR SELECT USING ((SELECT role FROM public.users_profile WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Admin can update reports" ON public.reports
  FOR UPDATE USING ((SELECT role FROM public.users_profile WHERE id = auth.uid()) = 'admin');

-- ============================================================================
-- 5. NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users_profile(id) ON DELETE CASCADE,
  type text NOT NULL, -- 'donationApproved', 'donationClaimed', 'donationRejected', 'requestFulfilled', 'expiryWarning', 'reportResolved', 'reportSubmitted'
  title text NOT NULL,
  message text NOT NULL,
  related_id text, -- Can reference donationId, requestId, reportId
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);

-- RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================================================
-- 6. AUDIT LOG TABLE (Optional - for tracking all changes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  action text NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
  user_id uuid REFERENCES public.users_profile(id) ON DELETE SET NULL,
  record_id text,
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON public.audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

-- ============================================================================
-- STORED PROCEDURES & FUNCTIONS
-- ============================================================================

-- Function to automatically mark donations as expired
CREATE OR REPLACE FUNCTION public.mark_expired_donations()
RETURNS void AS $$
BEGIN
  UPDATE public.donations
  SET status = 'expired'
  WHERE expiry_date < CURRENT_DATE
    AND status != 'expired'
    AND status != 'claimed';
END;
$$ LANGUAGE plpgsql;

-- Function to create expiry warning notifications
CREATE OR REPLACE FUNCTION public.create_expiry_warnings()
RETURNS void AS $$
DECLARE
  donation RECORD;
BEGIN
  FOR donation IN
    SELECT id, donor_id, medicine_name, expiry_date
    FROM public.donations
    WHERE status = 'approved'
      AND expiry_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '7 days')
      AND (SELECT COUNT(*) FROM public.notifications
           WHERE related_id = donations.id
           AND type = 'expiryWarning') = 0
  LOOP
    INSERT INTO public.notifications (
      id, user_id, type, title, message, related_id, created_at
    ) VALUES (
      'NOTIF_' || gen_random_uuid()::text,
      donation.donor_id,
      'expiryWarning',
      'Medicine Expiring Soon',
      donation.medicine_name || ' expires on ' || to_char(donation.expiry_date, 'DD/MM/YYYY'),
      donation.id,
      now()
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS (for common queries)
-- ============================================================================

-- View for available medicines (approved donations not claimed)
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
  EXTRACT(DAY FROM (d.expiry_date - CURRENT_DATE)) as days_until_expiry
FROM public.donations d
JOIN public.users_profile u ON d.donor_id = u.id
WHERE d.status = 'approved'
  AND d.expiry_date > CURRENT_DATE
ORDER BY d.created_at DESC;

-- View for pending approval donations
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

-- View for pending reports
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
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================
-- Uncomment and modify these to add test data:

-- INSERT INTO public.users_profile (id, name, email, phone, role, is_verified, location, latitude, longitude)
-- VALUES (
--   'user-uuid-1',
--   'John Donor',
--   'john@medishare.com',
--   '+1234567890',
--   'user',
--   true,
--   'Downtown Clinic',
--   31.5204,
--   74.3587
-- );

-- INSERT INTO public.donations (id, donor_id, medicine_name, medicine_type, quantity, expiry_date, donor_location, latitude, longitude, status, created_at)
-- VALUES (
--   'DON_001',
--   'user-uuid-1',
--   'Paracetamol',
--   'Tablet',
--   100,
--   CURRENT_DATE + INTERVAL '30 days',
--   'Downtown Clinic',
--   31.5204,
--   74.3587,
--   'approved',
--   now()
-- );

-- ============================================================================
-- CLEANUP & RESET (Optional)
-- ============================================================================
-- To reset the database, run these in order:
-- DELETE FROM public.notifications;
-- DELETE FROM public.audit_logs;
-- DELETE FROM public.reports;
-- DELETE FROM public.requests;
-- DELETE FROM public.donations;
-- DELETE FROM public.users_profile;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
