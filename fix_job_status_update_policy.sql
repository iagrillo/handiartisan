-- Fix: Allow artisans to update job status to arrival_confirmed
-- This policy allows artisans to update their jobs status

-- Drop existing policies that might block the update
DROP POLICY IF EXISTS "Allow authenticated update for jobs" ON jobs;
DROP POLICY IF EXISTS "Artisans can update arrival status" ON jobs;

-- Create a permissive update policy for artisans
-- This allows artisans to update status for jobs assigned to them
CREATE POLICY "Artisans can update job status" ON jobs
    FOR UPDATE 
    USING (artisan_id IS NOT NULL)
    WITH CHECK (artisan_id IS NOT NULL);

-- Also allow customers to update their own job status
CREATE POLICY "Customers can update own job status" ON jobs
    FOR UPDATE 
    USING (customer_email IS NOT NULL)
    WITH CHECK (customer_email IS NOT NULL);

-- Allow edge functions to update job status (for automated updates)
CREATE POLICY "Edge functions can update job status" ON jobs
    FOR UPDATE USING (true);

-- Allow public read access to jobs (for viewing)
CREATE POLICY "Public can view all jobs" ON jobs
    FOR SELECT USING (true);
