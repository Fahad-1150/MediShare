-- Create reports table for both donors and receivers to report issues/feedback
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- User who filed the report
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- User IDs involved in the transaction
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  donor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Related donation/request
  request_id VARCHAR(255) NOT NULL,
  donation_id VARCHAR(255) NOT NULL,
  
  -- Report details
  report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('complaint', 'feedback', 'issue', 'quality')),
  
  -- Comments/description
  comment TEXT NOT NULL,
  
  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'closed')),
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Optional fields
  admin_notes TEXT,
  resolved_at TIMESTAMP
);

-- Create indexes for faster queries
CREATE INDEX idx_reports_receiver_id ON reports(receiver_id);
CREATE INDEX idx_reports_donor_id ON reports(donor_id);
CREATE INDEX idx_reports_request_id ON reports(request_id);
CREATE INDEX idx_reports_donation_id ON reports(donation_id);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);

-- Enable RLS (Row Level Security)
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Policy: Receiver and Donor can view reports about their transaction
CREATE POLICY "Receiver and Donor can view reports"
  ON reports
  FOR SELECT
  USING (
    auth.uid() = receiver_id OR
    auth.uid() = donor_id OR
    auth.uid() = reporter_id OR
    (SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin'
  );

-- Policy: Anyone can create reports (no restriction)
CREATE POLICY "Anyone can create reports"
  ON reports
  FOR INSERT
  WITH CHECK (true);

-- Policy: Receiver, Donor, and Reporter can update reports
CREATE POLICY "Users can update reports"
  ON reports
  FOR UPDATE
  USING (
    auth.uid() = receiver_id OR
    auth.uid() = donor_id OR
    auth.uid() = reporter_id OR
    (SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin'
  )
  WITH CHECK (
    auth.uid() = receiver_id OR
    auth.uid() = donor_id OR
    auth.uid() = reporter_id OR
    (SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin'
  );

-- Policy: Only admins can delete reports
CREATE POLICY "Admins can delete reports"
  ON reports
  FOR DELETE
  USING ((SELECT role FROM users_profile WHERE id = auth.uid()) = 'admin');
