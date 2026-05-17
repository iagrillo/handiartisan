-- Add OTP columns to jobs table if they don't exist
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS arrival_otp VARCHAR(6);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS arrival_otp_expiry TIMESTAMPTZ;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS artisan_arrived BOOLEAN DEFAULT false;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS artisan_arrived_at TIMESTAMPTZ;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'jobs' 
AND column_name IN ('arrival_otp', 'arrival_otp_expiry', 'artisan_arrived', 'artisan_arrived_at', 'verified_at');
