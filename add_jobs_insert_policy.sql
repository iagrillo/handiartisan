-- Add INSERT policy for jobs table
-- Run this in Supabase SQL Editor

-- Allow public insert for jobs (anonymous users can create jobs)
CREATE POLICY "Allow public insert for jobs" ON jobs
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Verify the policy was created
SELECT 
    policyname, 
    cmd, 
    qual, 
    with_check 
FROM pg_policies 
WHERE tablename = 'jobs';
