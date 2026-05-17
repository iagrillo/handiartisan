-- ============================================
-- Test: Disable RLS temporarily to debug
-- Run this in Supabase SQL Editor
-- ============================================

-- Disable RLS on artisans table (for testing)
ALTER TABLE artisans DISABLE ROW LEVEL SECURITY;

-- Now try to insert (this should work)
-- INSERT INTO artisans (full_name, phone, email, status) 
-- VALUES ('Test Artisan', '08099999999', 'test@test.com', 'active');

-- If insert works, re-enable RLS with proper policies
ALTER TABLE artisans ENABLE ROW LEVEL SECURITY;

-- Create proper policies
DROP POLICY IF EXISTS "Anyone can insert artisans" ON artisans;
CREATE POLICY "Anyone can insert artisans" ON artisans FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can select artisans" ON artisans;
CREATE POLICY "Anyone can select artisans" ON artisans FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can update artisans" ON artisans;
CREATE POLICY "Anyone can update artisans" ON artisans FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Anyone can delete artisans" ON artisans;
CREATE POLICY "Anyone can delete artisans" ON artisans FOR DELETE USING (true);
