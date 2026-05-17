-- ============================================
-- Add INSERT policy for artisans table
-- Run this in Supabase SQL Editor
-- ============================================

-- Drop existing insert policy if it exists
DROP POLICY IF EXISTS "Anyone can insert artisans" ON artisans;
DROP POLICY IF EXISTS "Authenticated can insert artisans" ON artisans;

-- Create an insert policy that allows anyone (including anon) to create new artisans
-- This is needed for new artisan registration
CREATE POLICY "Anyone can insert artisans" ON artisans
    FOR INSERT WITH CHECK (true);

-- Also add a SELECT policy so new artisans can be read back
DROP POLICY IF EXISTS "Anyone can select artisans" ON artisans;
CREATE POLICY "Anyone can select artisans" ON artisans
    FOR SELECT USING (true);

-- ============================================
-- Check for unique constraints on artisans table
-- If there's a unique constraint on phone/email, we need to handle it
-- ============================================

-- List all unique constraints on artisans table
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'artisans'
    AND tc.constraint_type = 'UNIQUE';

-- Verify the policies
SELECT 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual 
FROM pg_policies 
WHERE tablename = 'artisans'
ORDER BY policyname;
