-- ============================================
-- Add arrival OTP columns to jobs table
-- Run this in Supabase SQL Editor
-- ============================================

-- Add OTP columns for arrival verification
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS arrival_otp VARCHAR(6);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS arrival_otp_expiry TIMESTAMP WITH TIME ZONE;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS artisan_arrived BOOLEAN DEFAULT false;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS artisan_arrived_at TIMESTAMP WITH TIME ZONE;

-- Add customer OTP for job completion
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS completion_otp VARCHAR(6);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS completion_otp_expiry TIMESTAMP WITH TIME ZONE;

-- Add declined_by column
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS declined_by VARCHAR(20);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_requested_new_estimate BOOLEAN DEFAULT false;

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_jobs_arrival_otp ON jobs(arrival_otp);
CREATE INDEX IF NOT EXISTS idx_jobs_artisan_arrived ON jobs(artisan_arrived);
CREATE INDEX IF NOT EXISTS idx_jobs_job_reference ON jobs(job_reference);

DO $$
BEGIN
    RAISE NOTICE 'All required columns added successfully!';
END $$;
