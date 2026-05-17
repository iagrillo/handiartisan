-- Run this in Supabase SQL Editor to allow job status updates

-- First, drop all existing UPDATE policies on jobs
DROP POLICY IF EXISTS "Allow authenticated update for jobs" ON jobs;
DROP POLICY IF EXISTS "Artisans can update arrival status" ON jobs;
DROP POLICY IF EXISTS "Artisan can update own jobs" ON jobs;
DROP POLICY IF EXISTS "Customer can update own jobs" ON jobs;

-- Create a completely permissive UPDATE policy for jobs
-- This allows anyone to update job status (needed because customers may be anonymous)
CREATE POLICY "Allow anyone to update jobs" ON jobs
    FOR UPDATE USING (true);

-- Also ensure SELECT is permissive so jobs can be read
DROP POLICY IF EXISTS "Allow public select for jobs" ON jobs;
DROP POLICY IF EXISTS "Customers can view own jobs by email" ON jobs;
DROP POLICY IF EXISTS "Customers can view own jobs by phone" ON jobs;
DROP POLICY IF EXISTS "Customers can view own jobs" ON jobs;
DROP POLICY IF EXISTS "Public can view all jobs" ON jobs;

CREATE POLICY "Allow anyone to view jobs" ON jobs
    FOR SELECT USING (true);
