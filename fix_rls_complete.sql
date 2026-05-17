-- Complete RLS fix - run in Supabase SQL Editor
-- Drop existing policies
DROP POLICY IF EXISTS "Public can view artisans" ON artisans;
DROP POLICY IF EXISTS "Public can view approved stores" ON stores;
DROP POLICY IF EXISTS "Public can view approved equipment" ON equipment;
DROP POLICY IF EXISTS "Owners can update own artisans" ON artisans;

-- Create new policies that allow full access
CREATE POLICY "Anyone can view artisans" ON artisans FOR SELECT USING (true);
CREATE POLICY "Anyone can update artisans" ON artisans FOR UPDATE USING (true);
CREATE POLICY "Anyone can insert artisans" ON artisans FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can view stores" ON stores FOR SELECT USING (true);
CREATE POLICY "Anyone can view equipment" ON equipment FOR SELECT USING (true);

-- Update status values
UPDATE artisans SET status = 'active' WHERE status IS NULL;
UPDATE stores SET status = 'approved' WHERE status IS NULL;
UPDATE equipment SET status = 'approved' WHERE status IS NULL;
