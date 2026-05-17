-- ============================================
-- SQL Fix for Estimate Submission
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Fix RLS policies to allow job status updates
-- Drop existing policies first (ignore errors if they don't exist)
DROP POLICY IF EXISTS "Allow authenticated update for jobs" ON jobs;
DROP POLICY IF EXISTS "Artisans can update arrival status" ON jobs;
DROP POLICY IF EXISTS "Artisan can update own jobs" ON jobs;
DROP POLICY IF EXISTS "Customer can update own jobs" ON jobs;
DROP POLICY IF EXISTS "Allow anyone to update jobs" ON jobs;
DROP POLICY IF EXISTS "Allow anyone to view jobs" ON jobs;

-- Create permissive UPDATE policy
CREATE POLICY "Allow anyone to update jobs" ON jobs
    FOR UPDATE USING (true);

-- Create permissive SELECT policy  
CREATE POLICY "Allow anyone to view jobs" ON jobs
    FOR SELECT USING (true);

-- 2. Verify jobs table status column
SELECT job_reference, status, created_at 
FROM jobs 
ORDER BY created_at DESC 
LIMIT 10;

-- 3. Check current RLS policies on jobs table
SELECT 
    policyname, 
    cmd, 
    qual, 
    with_check 
FROM pg_policies 
WHERE tablename = 'jobs';
