-- ============================================
-- Fix: Add DELETE and UPDATE policies for artisans and stores tables
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- ADD DELETE POLICY FOR ARTISANS TABLE
-- ============================================

-- Drop existing delete policy if it exists (to recreate with correct settings)
DROP POLICY IF EXISTS "Users can delete artisans" ON artisans;
DROP POLICY IF EXISTS "Authenticated can delete artisans" ON artisans;
DROP POLICY IF EXISTS "Admins can delete artisans" ON artisans;

-- Create a delete policy that allows authenticated users to delete artisans
-- This policy applies to ALL authenticated users (admins can also delete)
CREATE POLICY "Authenticated users can delete artisans" ON artisans
    FOR DELETE USING (true);

-- ============================================
-- ADD UPDATE POLICY FOR ARTISANS TABLE
-- ============================================

DROP POLICY IF EXISTS "Users can update artisans" ON artisans;
DROP POLICY IF EXISTS "Authenticated can update artisans" ON artisans;

CREATE POLICY "Authenticated users can update artisans" ON artisans
    FOR UPDATE USING (true);

-- ============================================
-- ADD DELETE POLICY FOR STORES TABLE
-- ============================================

-- Drop existing delete policy if it exists (to recreate with correct settings)
DROP POLICY IF EXISTS "Users can delete stores" ON stores;
DROP POLICY IF EXISTS "Authenticated can delete stores" ON stores;
DROP POLICY IF EXISTS "Admins can delete stores" ON stores;

-- Create a delete policy that allows authenticated users to delete stores
-- This policy applies to ALL authenticated users (admins can also delete)
CREATE POLICY "Authenticated users can delete stores" ON stores
    FOR DELETE USING (true);

-- ============================================
-- ADD UPDATE POLICY FOR STORES TABLE
-- ============================================

DROP POLICY IF EXISTS "Users can update stores" ON stores;
DROP POLICY IF EXISTS "Authenticated can update stores" ON stores;

CREATE POLICY "Authenticated users can update stores" ON stores
    FOR UPDATE USING (true);

-- ============================================
-- ADD DELETE POLICY FOR EQUIPMENT TABLE
-- ============================================

-- Drop existing delete policy if it exists (to recreate with correct settings)
DROP POLICY IF EXISTS "Users can delete equipment" ON equipment;
DROP POLICY IF EXISTS "Authenticated can delete equipment" ON equipment;

-- Create a delete policy that allows authenticated users to delete equipment
CREATE POLICY "Authenticated users can delete equipment" ON equipment
    FOR DELETE USING (true);

-- ============================================
-- ADD UPDATE POLICY FOR EQUIPMENT TABLE
-- ============================================

DROP POLICY IF EXISTS "Users can update equipment" ON equipment;
DROP POLICY IF EXISTS "Authenticated can update equipment" ON equipment;

CREATE POLICY "Authenticated users can update equipment" ON equipment
    FOR UPDATE USING (true);

-- ============================================
-- VERIFICATION: Check if policies are created
-- ============================================

SELECT 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual 
FROM pg_policies 
WHERE tablename IN ('artisans', 'stores', 'equipment')
ORDER BY tablename, policyname;
