-- ============================================
-- Complete fix for artisan insert issues
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. First, let's check and drop any problematic triggers
-- List all triggers on artisans table
SELECT 
    tgname AS trigger_name,
    proname AS function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE NOT t.tgisinternal
AND tgrelid = 'artisans'::regclass;

-- 2. Drop any trigger that might be causing the ON CONFLICT issue
-- (Uncomment if needed after checking above)
-- DROP TRIGGER IF EXISTS some_trigger ON artisans;

-- 3. Add INSERT policy for artisans table
DROP POLICY IF EXISTS "Anyone can insert artisans" ON artisans;
CREATE POLICY "Anyone can insert artisans" ON artisans
    FOR INSERT WITH CHECK (true);

-- 4. Add SELECT policy
DROP POLICY IF EXISTS "Anyone can select artisans" ON artisans;
CREATE POLICY "Anyone can select artisans" ON artisans
    FOR SELECT USING (true);

-- 5. If there's no unique constraint on phone, add one to prevent duplicates
-- This also helps if there's any ON CONFLICT logic somewhere
ALTER TABLE artisans ADD CONSTRAINT artisans_phone_unique UNIQUE (phone);

-- 6. Also add unique constraint on email (if not exists)
ALTER TABLE artisans ADD CONSTRAINT artisans_email_unique UNIQUE (email);

-- 7. Verify all policies
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

-- 8. Test insert (will show error if there's still an issue)
-- INSERT INTO artisans (full_name, phone, email, status) 
-- VALUES ('Test Artisan', '08000000000', 'test@test.com', 'active');
