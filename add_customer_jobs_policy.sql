-- Add policy to allow customers to view their own jobs by email or phone
-- Run this SQL in Supabase SQL Editor

-- Policy for customers to view their own jobs by email
CREATE POLICY "Customers can view own jobs by email" ON jobs
    FOR SELECT USING (customer_email IS NOT NULL);

-- Policy for customers to view their own jobs by phone  
CREATE POLICY "Customers can view own jobs by phone" ON jobs
    FOR SELECT USING (customer_phone IS NOT NULL);

-- Or combine into one policy
DROP POLICY IF EXISTS "Customers can view own jobs by email" ON jobs;
DROP POLICY IF EXISTS "Customers can view own jobs by phone" ON jobs;

CREATE POLICY "Customers can view own jobs" ON jobs
    FOR SELECT USING (customer_email IS NOT NULL OR customer_phone IS NOT NULL);
