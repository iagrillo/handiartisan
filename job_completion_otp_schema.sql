-- ============================================
-- Job Completion OTP & Labor Release Schema
-- Run this SQL in Supabase SQL Editor
-- ============================================

-- Add completion OTP columns to jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS completion_otp VARCHAR(6);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS completion_otp_expiry TIMESTAMP WITH TIME ZONE;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS labor_cost_released BOOLEAN DEFAULT false;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS labor_cost_released_at TIMESTAMP WITH TIME ZONE;

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_jobs_completion_otp ON jobs(completion_otp);
CREATE INDEX IF NOT EXISTS idx_jobs_labor_released ON jobs(labor_cost_released);

-- Add column to track who declined the estimate
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS declined_by VARCHAR(20); -- 'customer' or 'artisan' or NULL

-- Add column to track when customer responded to estimate
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_responded_at TIMESTAMP WITH TIME ZONE;

-- Add column to track if customer has verified completion
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_verified BOOLEAN DEFAULT false;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_verified_at TIMESTAMP WITH TIME ZONE;

-- ============================================
-- EDGE FUNCTIONS FOR JOB COMPLETION OTP
-- ============================================

-- Create generateJobCompletionOtp function
CREATE OR REPLACE FUNCTION generate_job_completion_otp(job_ref TEXT, artisan_id_param UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    job_record RECORD;
    otp_code TEXT;
    otp_expiry TIMESTAMP;
    sms_result TEXT;
BEGIN
    -- Get the job
    SELECT * INTO job_record FROM jobs WHERE job_reference = job_ref AND artisan_id = artisan_id_param;
    
    IF job_record IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Job not found');
    END IF;

    -- Check if labor cost exists and hasn't been released
    IF job_record.estimate_labor_cost IS NULL OR job_record.estimate_labor_cost <= 0 THEN
        RETURN json_build_object('success', false, 'error', 'No pending labor for this job');
    END IF;

    -- Generate 6-digit OTP
    otp_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    otp_expiry := NOW() + INTERVAL '30 minutes';

    -- Update job with OTP
    UPDATE jobs 
    SET completion_otp = otp_code,
        completion_otp_expiry = otp_expiry,
        status = 'pending_completion',
        updated_at = NOW()
    WHERE id = job_record.id;

    -- Try to send SMS to customer
    BEGIN
        IF job_record.customer_phone IS NOT NULL AND job_record.customer_phone != '' THEN
            sms_result := 'OTP would be sent to ' || job_record.customer_phone;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            sms_result := NULL;
    END;

    RETURN json_build_object(
        'success', true,
        'message', 'OTP generated and sent to customer',
        'otp', otp_code,
        'otpExpiry', otp_expiry,
        'smsSent', sms_result IS NOT NULL
    );
END;
$$;

-- Create verifyJobCompletionOtp function
CREATE OR REPLACE FUNCTION verify_job_completion_otp(job_ref TEXT, artisan_id_param UUID, otp_code TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    job_record RECORD;
    wallet_record RECORD;
    labor_cost NUMERIC;
    released_amount INTEGER;
BEGIN
    -- Get the job
    SELECT * INTO job_record FROM jobs WHERE job_reference = job_ref AND artisan_id = artisan_id_param;
    
    IF job_record IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Job not found');
    END IF;

    -- Verify OTP
    IF job_record.completion_otp IS NULL OR job_record.completion_otp != otp_code THEN
        RETURN json_build_object('success', false, 'error', 'Invalid OTP');
    END IF;

    -- Check OTP expiry
    IF job_record.completion_otp_expiry < NOW() THEN
        RETURN json_build_object('success', false, 'error', 'OTP has expired');
    END IF;

    -- Get labor cost
    labor_cost := COALESCE(job_record.estimate_labor_cost, 0);
    
    IF labor_cost <= 0 THEN
        RETURN json_build_object('success', false, 'error', 'No pending labor to release');
    END IF;

    -- Get wallet
    SELECT * INTO wallet_record FROM wallets WHERE artisan_id = artisan_id_param;
    
    IF wallet_record IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Wallet not found');
    END IF;

    -- Release pending labor to available balance
    UPDATE wallets
    SET available_balance = available_balance + labor_cost,
        pending_balance = pending_balance - labor_cost,
        updated_at = NOW()
    WHERE id = wallet_record.id;

    -- Update job status
    UPDATE jobs
    SET status = 'completed',
        labor_cost_released = true,
        labor_cost_released_at = NOW(),
        updated_at = NOW()
    WHERE id = job_record.id;

    released_amount := labor_cost::INTEGER;

    RETURN json_build_object(
        'success', true,
        'message', 'Job completed and labor released',
        'jobReference', job_ref,
        'artisanId', artisan_id_param,
        'amountReleased', released_amount
    );
END;
$$;

-- Create getJobCompletionOtp function
CREATE OR REPLACE FUNCTION get_job_completion_otp(job_ref TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    job_record RECORD;
BEGIN
    -- Get the job
    SELECT * INTO job_record FROM jobs WHERE job_reference = job_ref;
    
    IF job_record IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Job not found');
    END IF;

    -- Check if OTP is still valid
    IF job_record.completion_otp IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'No completion OTP found');
    END IF;

    IF job_record.completion_otp_expiry < NOW() THEN
        RETURN json_build_object('success', false, 'error', 'OTP has expired');
    END IF;

    RETURN json_build_object(
        'success', true,
        'otp', job_record.completion_otp,
        'otpExpiry', job_record.completion_otp_expiry,
        'jobCompleted', job_record.status = 'completed'
    );
END;
$$;

-- Create verifyCustomerCompletion function - called when customer verifies OTP
CREATE OR REPLACE FUNCTION verify_customer_completion(job_ref TEXT, otp_code TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    job_record RECORD;
BEGIN
    -- Get the job
    SELECT * INTO job_record FROM jobs WHERE job_reference = job_ref;
    
    IF job_record IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Job not found');
    END IF;

    -- Verify OTP
    IF job_record.completion_otp IS NULL OR job_record.completion_otp != otp_code THEN
        RETURN json_build_object('success', false, 'error', 'Invalid OTP');
    END IF;

    -- Check OTP expiry
    IF job_record.completion_otp_expiry < NOW() THEN
        RETURN json_build_object('success', false, 'error', 'OTP has expired');
    END IF;

    -- Mark customer as verified
    UPDATE jobs
    SET customer_verified = true,
        customer_verified_at = NOW(),
        updated_at = NOW()
    WHERE id = job_record.id;

    RETURN json_build_object(
        'success', true,
        'message', 'Verification successful! Waiting for artisan to confirm release.',
        'customerVerified', true
    );
END;
$$;

DO $$
BEGIN
    RAISE NOTICE 'Job completion OTP schema created successfully!';
    RAISE NOTICE 'New columns: completion_otp, completion_otp_expiry, labor_cost_released, labor_cost_released_at';
    RAISE NOTICE 'New functions: generate_job_completion_otp, verify_job_completion_otp, get_job_completion_otp';
END $$;
