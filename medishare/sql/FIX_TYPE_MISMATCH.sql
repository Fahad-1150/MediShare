-- ============================================================================
-- MediShare - Type Mismatch Fix
-- ============================================================================
-- If you get: "foreign key constraint cannot be implemented"
-- "Key columns are of incompatible types: text and uuid"
-- 
-- Run this script FIRST, then run FINAL_SCHEMA.sql
-- ============================================================================

-- Step 1: Drop all views first
DROP VIEW IF EXISTS public.pending_reports CASCADE;
DROP VIEW IF EXISTS public.pending_donations CASCADE;
DROP VIEW IF EXISTS public.available_medicines CASCADE;

-- Step 2: Drop all tables with CASCADE
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.requests CASCADE;
DROP TABLE IF EXISTS public.donations CASCADE;
DROP TABLE IF EXISTS public.users_profile CASCADE;

-- ============================================================================
-- NOW RUN FINAL_SCHEMA.sql
-- ============================================================================
-- After running this cleanup script, copy and paste the entire FINAL_SCHEMA.sql
-- into a new SQL query and execute it
-- ============================================================================
