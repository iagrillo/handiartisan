-- Fix RLS - run in Supabase SQL Editor
DROP POLICY IF EXISTS "Public can view artisans" ON artisans;
DROP POLICY IF EXISTS "Public can view approved stores" ON stores;
DROP POLICY IF EXISTS "Public can view approved equipment" ON equipment;

CREATE POLICY "Anyone can view artisans" ON artisans FOR SELECT USING (true);
CREATE POLICY "Anyone can view stores" ON stores FOR SELECT USING (true);
CREATE POLICY "Anyone can view equipment" ON equipment FOR SELECT USING (true);

UPDATE artisans SET status = 'active' WHERE status IS NULL;
UPDATE stores SET status = 'approved' WHERE status IS NULL;
UPDATE equipment SET status = 'approved' WHERE status IS NULL;
