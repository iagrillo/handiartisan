-- Fix RLS policies for jobs table
-- Run this in Supabase SQL Editor to allow job creation

-- First, disable RLS temporarily to check the current state
ALTER TABLE jobs DISABLE ROW LEVEL SECURITY;

-- Enable RLS back with proper policies
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Allow anyone to INSERT jobs (for customers creating jobs)
CREATE POLICY "Allow public insert for jobs" ON jobs
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Allow anyone to SELECT jobs (for viewing job status)
CREATE POLICY "Allow public select for jobs" ON jobs
FOR SELECT
TO anon, authenticated
USING (true);

-- Allow updates only for authenticated users
CREATE POLICY "Allow authenticated update for jobs" ON jobs
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow delete only for service role or authenticated users
CREATE POLICY "Allow authenticated delete for jobs" ON jobs
FOR DELETE
TO authenticated
USING (true);

-- Verify the policies were created
SELECT 
    policyname, 
    cmd, 
    qual, 
    with_check 
FROM pg_policies 
WHERE tablename = 'jobs';

-- Check if RLS is enabled
SELECT 
    relname, 
    relrowsecurity 
FROM pg_class 
WHERE relname = 'jobs';
