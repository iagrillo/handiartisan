-- ============================================
-- Fix duplicate records and add unique constraints
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. First, let's see the duplicate records
SELECT phone, COUNT(*) as count 
FROM artisans 
WHERE phone IS NOT NULL AND phone != ''
GROUP BY phone 
HAVING COUNT(*) > 1;

-- 2. Delete duplicates, keeping only the first record for each phone
-- Run this to see which records will be deleted (optional)
SELECT id, phone, full_name, created_at
FROM artisans
WHERE phone IN (
    SELECT phone 
    FROM artisans 
    WHERE phone IS NOT NULL AND phone != ''
    GROUP BY phone 
    HAVING COUNT(*) > 1
)
ORDER BY phone, created_at;

-- 3. Delete duplicates, keeping the oldest record
-- For UUID type, we need to cast to text or use a different approach
DELETE FROM artisans
WHERE id NOT IN (
    SELECT DISTINCT ON (phone) id
    FROM artisans
    WHERE phone IS NOT NULL AND phone != ''
    ORDER BY phone, created_at ASC
);

-- 4. Now add unique constraints (should work after duplicates are removed)
ALTER TABLE artisans ADD CONSTRAINT artisans_phone_unique UNIQUE (phone);
ALTER TABLE artisans ADD CONSTRAINT artisans_email_unique UNIQUE (email);

-- 5. Add INSERT policy for artisans table
DROP POLICY IF EXISTS "Anyone can insert artisans" ON artisans;
CREATE POLICY "Anyone can insert artisans" ON artisans
    FOR INSERT WITH CHECK (true);

-- 6. Add SELECT policy
DROP POLICY IF EXISTS "Anyone can select artisans" ON artisans;
CREATE POLICY "Anyone can select artisans" ON artisans
    FOR SELECT USING (true);

-- 7. Verify everything
SELECT 
    tablename, 
    policyname, 
    cmd
FROM pg_policies 
WHERE tablename = 'artisans'
ORDER BY policyname;
