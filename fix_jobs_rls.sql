-- Fix RLS policies for jobs table
-- Run this in Supabase SQL Editor

-- Enable RLS
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view own jobs" ON jobs;
DROP POLICY IF EXISTS "Service role can manage jobs" ON jobs;
DROP POLICY IF EXISTS "Public can view completed jobs" ON jobs;

-- Allow anyone to create jobs (customers booking)
CREATE POLICY "Public can create jobs" ON jobs
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

-- Allow public to view jobs
CREATE POLICY "Public can view jobs" ON jobs
  FOR SELECT TO anon, authenticated
  USING (true);

-- Allow authenticated users to update own jobs
CREATE POLICY "Users can update own jobs" ON jobs
  FOR UPDATE TO authenticated
  USING (
    artisan_id = auth.uid()::uuid
    OR customer_email = auth.jwt()->>'email'
  )
  WITH CHECK (
    artisan_id = auth.uid()::uuid
    OR customer_email = auth.jwt()->>'email'
  );

-- Service role can do everything
CREATE POLICY "Service role manages jobs" ON jobs
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- Verify
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'jobs';
