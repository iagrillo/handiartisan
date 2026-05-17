-- Add columns for artisan arrival OTP verification
-- Run this in Supabase SQL Editor

-- Add arrival OTP columns to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS arrival_otp TEXT,
ADD COLUMN IF NOT EXISTS arrival_otp_expiry TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS artisan_arrived BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS artisan_arrived_at TIMESTAMPTZ;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_jobs_arrival_otp ON jobs(job_reference) WHERE arrival_otp IS NOT NULL;

-- RLS policies for OTP access (using customer_email, not customer_id)
-- Allow edge functions to update arrival OTP
CREATE POLICY "Edge functions can update arrival OTP" ON jobs
    FOR UPDATE USING (true);

-- Allow customers to view their job OTP via email
CREATE POLICY "Customers can view own job OTP" ON jobs
    FOR SELECT USING (customer_email = auth.jwt()->>'email');

-- Allow artisans to update arrival status for their jobs
CREATE POLICY "Artisans can update arrival status" ON jobs
    FOR UPDATE USING (artisan_id IN (SELECT id FROM artisans WHERE email = auth.jwt()->>'email'));

-- Done!
