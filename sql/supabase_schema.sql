-- MediShare Supabase Schema
-- Run these commands in Supabase SQL Editor

-- 1. Users Profile Table
CREATE TABLE IF NOT EXISTS users_profile (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  location_url TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  is_verified BOOLEAN DEFAULT FALSE,
  avatar_url TEXT,
  bio TEXT,
  password TEXT, -- For legacy/non-auth fallback only
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 2. Donations Table
CREATE TABLE IF NOT EXISTS donations (
  id TEXT PRIMARY KEY,
  donor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medicine_name TEXT NOT NULL,
  medicine_type TEXT NOT NULL CHECK (medicine_type IN ('Tablet', 'Capsule', 'Injection', 'Syrup', 'Cream', 'Other')),
  quantity INT NOT NULL CHECK (quantity > 0),
  expiry_date DATE NOT NULL,
  donor_location TEXT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  photo_url TEXT,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'claimed', 'expired', 'rejected')),
  claimed_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  admin_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  approved_at TIMESTAMP,
  claimed_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_donor_id (donor_id),
  INDEX idx_status (status),
  INDEX idx_expiry_date (expiry_date)
);

-- 3. Requests Table
CREATE TABLE IF NOT EXISTS requests (
  id TEXT PRIMARY KEY,
  requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medicine_name TEXT NOT NULL,
  medicine_type TEXT NOT NULL CHECK (medicine_type IN ('Tablet', 'Capsule', 'Injection', 'Syrup', 'Cream', 'Other')),
  quantity INT NOT NULL CHECK (quantity > 0),
  requester_location TEXT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  reason TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'fulfilled', 'cancelled')),
  assigned_donation_id TEXT REFERENCES donations(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  fulfilled_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_requester_id (requester_id),
  INDEX idx_status (status),
  INDEX idx_assigned_donation_id (assigned_donation_id)
);

-- 4. Reports Table
CREATE TABLE IF NOT EXISTS reports (
  id TEXT PRIMARY KEY,
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  donation_id TEXT NOT NULL REFERENCES donations(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN ('Expired Medicine', 'Damaged Packaging', 'Suspicious Content', 'Wrong Item', 'Other')),
  description TEXT,
  photo_urls TEXT[], -- Array of URLs
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'resolved', 'dismissed')),
  admin_notes TEXT,
  resolution TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  resolved_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_reporter_id (reporter_id),
  INDEX idx_donation_id (donation_id),
  INDEX idx_status (status)
);

-- 5. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('donation_approved', 'donation_claimed', 'expiry_warning', 'request_fulfilled', 'report_resolved')),
  title TEXT NOT NULL,
  message TEXT,
  related_donation_id TEXT REFERENCES donations(id) ON DELETE SET NULL,
  related_request_id TEXT REFERENCES requests(id) ON DELETE SET NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_user_id (user_id),
  INDEX idx_is_read (is_read)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users_profile(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users_profile(role);
CREATE INDEX IF NOT EXISTS idx_donations_status ON donations(status);
CREATE INDEX IF NOT EXISTS idx_donations_expiry ON donations(expiry_date);
CREATE INDEX IF NOT EXISTS idx_requests_status ON requests(status);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);

-- RLS (Row Level Security) - Optional but recommended
ALTER TABLE users_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view all profiles
CREATE POLICY "Users can view profiles" ON users_profile FOR SELECT USING (TRUE);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users_profile FOR UPDATE USING (id = auth.uid());

-- Donors can view/manage their donations
CREATE POLICY "Donors can view own donations" ON donations FOR SELECT USING (donor_id = auth.uid() OR status = 'approved');

-- Admins can view all donations
CREATE POLICY "Admins can view all donations" ON donations FOR SELECT USING (
  EXISTS (SELECT 1 FROM users_profile WHERE id = auth.uid() AND role = 'admin')
);

-- Users can create requests
CREATE POLICY "Users can create requests" ON requests FOR INSERT WITH CHECK (requester_id = auth.uid());

-- Users can view notifications
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
