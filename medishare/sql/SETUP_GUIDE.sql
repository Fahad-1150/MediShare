-- ============================================================================
-- SETUP INSTRUCTIONS FOR MEDISHARE
-- ============================================================================

-- STEP 1: CLEAR EXISTING DATABASE (if needed)
-- ============================================================================
-- Run this FIRST if you have errors from previous attempts:

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
-- STEP 2: CREATE ALL TABLES AND INDEXES
-- ============================================================================
-- Run the file: FINAL_SCHEMA.sql
-- Copy entire contents and execute in Supabase SQL Editor

-- ============================================================================
-- STEP 3: CREATE ADMIN USER (Optional)
-- ============================================================================
-- After creating tables, create admin user in Supabase Auth, then run:

-- Replace 'ADMIN_UUID_HERE' with actual user ID from Supabase Auth
INSERT INTO public.users_profile (id, name, email, phone, role, is_verified, location)
VALUES (
  'ADMIN_UUID_HERE',
  'Admin User',
  'admin@medishare.com',
  '+1234567890',
  'admin',
  true,
  'Admin Center'
);

-- ============================================================================
-- STEP 4: INSERT SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Create test user 1 (donor)
INSERT INTO public.users_profile (id, name, email, phone, role, is_verified, location, latitude, longitude)
VALUES (
  '550e8400-e29b-41d4-a716-446655440001',
  'Ali Donor',
  'ali@test.com',
  '+92300000001',
  'user',
  true,
  'Downtown Clinic',
  31.5204,
  74.3587
) ON CONFLICT DO NOTHING;

-- Create test user 2 (requester)
INSERT INTO public.users_profile (id, name, email, phone, role, is_verified, location, latitude, longitude)
VALUES (
  '550e8400-e29b-41d4-a716-446655440002',
  'Fatima Requester',
  'fatima@test.com',
  '+92300000002',
  'user',
  true,
  'Karachi Hospital',
  31.4504,
  74.2711
) ON CONFLICT DO NOTHING;

-- Create sample donation
INSERT INTO public.donations (
  id, donor_id, medicine_name, medicine_type, quantity, 
  expiry_date, donor_location, latitude, longitude, 
  status, created_at
)
VALUES (
  'DON_001',
  '550e8400-e29b-41d4-a716-446655440001',
  'Paracetamol',
  'Tablet',
  100,
  CURRENT_DATE + INTERVAL '30 days',
  'Downtown Clinic',
  31.5204,
  74.3587,
  'approved',
  now()
) ON CONFLICT DO NOTHING;

-- Create sample donation 2
INSERT INTO public.donations (
  id, donor_id, medicine_name, medicine_type, quantity,
  expiry_date, donor_location, latitude, longitude,
  status, created_at
)
VALUES (
  'DON_002',
  '550e8400-e29b-41d4-a716-446655440001',
  'Ibuprofen',
  'Capsule',
  50,
  CURRENT_DATE + INTERVAL '45 days',
  'Downtown Clinic',
  31.5204,
  74.3587,
  'approved',
  now()
) ON CONFLICT DO NOTHING;

-- Create sample request
INSERT INTO public.requests (
  id, requester_id, medicine_name, medicine_type, quantity,
  requester_location, latitude, longitude, reason, status, created_at
)
VALUES (
  'REQ_001',
  '550e8400-e29b-41d4-a716-446655440002',
  'Paracetamol',
  'Tablet',
  20,
  'Karachi Hospital',
  31.4504,
  74.2711,
  'For patient relief',
  'pending',
  now()
) ON CONFLICT DO NOTHING;

-- ============================================================================
-- STEP 5: VERIFY SETUP
-- ============================================================================
-- Run these queries to verify everything works:

-- Check users created
SELECT id, name, email, role FROM public.users_profile;

-- Check donations
SELECT id, medicine_name, quantity, status FROM public.donations;

-- Check available medicines view
SELECT * FROM public.available_medicines;

-- Check requests
SELECT id, medicine_name, quantity, status FROM public.requests;

-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================

-- If you get "infinite recursion" error:
-- - Use FINAL_SCHEMA.sql (this file has NO RLS policies)
-- - Make sure to drop old tables first

-- If signup/login fails:
-- - Check Supabase Auth is enabled
-- - Check users_profile table has correct permissions
-- - Make sure user has authenticated role assigned

-- If you can't see data:
-- - Check database hasn't been reset
-- - Verify you're using correct Supabase project URL and key
-- - Check main.dart has correct Supabase credentials

-- ============================================================================
-- USEFUL QUERIES
-- ============================================================================

-- Get all expired donations
SELECT id, medicine_name, expiry_date FROM public.donations 
WHERE expiry_date < CURRENT_DATE;

-- Get medicines expiring in 7 days
SELECT id, medicine_name, expiry_date FROM public.donations 
WHERE expiry_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '7 days');

-- Get donations by specific user
SELECT * FROM public.donations WHERE donor_id = 'USER_UUID_HERE';

-- Count pending reports
SELECT COUNT(*) as pending_reports FROM public.reports WHERE status = 'pending';

-- Get user notifications
SELECT * FROM public.notifications WHERE user_id = 'USER_UUID_HERE' ORDER BY created_at DESC;

-- ============================================================================
-- END SETUP GUIDE
-- ============================================================================
