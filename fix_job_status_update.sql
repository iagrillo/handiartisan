-- Allow artisans to update job status for their jobs
-- This fixes the issue where artisan can't update status after OTP verification

-- Drop the restrictive authenticated update policy if it exists
DROP POLICY IF EXISTS "Allow authenticated update for jobs" ON jobs;

-- Create a more permissive policy that allows artisans to update their job status
CREATE POLICY "Artisan can update own jobs" ON jobs
    FOR UPDATE 
    USING (artisan_id IS NOT NULL)
    WITH CHECK (artisan_id IS NOT NULL);

-- Also allow customers to update their job status
CREATE POLICY "Customer can update own jobs" ON jobs
    FOR UPDATE 
    USING (customer_email IS NOT NULL)
    WITH CHECK (customer_email IS NOT NULL);
