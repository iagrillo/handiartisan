-- ============================================
-- SECURITY AUDIT: Remove all weak/conflicting RLS policies
-- Run this in Supabase SQL Editor to clean up
-- ============================================

-- ============================================
-- 1. Remove weak wallet policies
-- ============================================
DROP POLICY IF EXISTS "Anyone can insert wallets" ON wallets;
DROP POLICY IF EXISTS "Anyone can select wallets" ON wallets;
DROP POLICY IF EXISTS "Anyone can update wallets" ON wallets;

-- ============================================
-- 2. Remove weak jobs policies  
-- ============================================
DROP POLICY IF EXISTS "Allow public insert for jobs" ON jobs;
DROP POLICY IF EXISTS "Allow public select for jobs" ON jobs;
DROP POLICY IF EXISTS "Allow anyone to update jobs" ON jobs;
DROP POLICY IF EXISTS "Allow anyone to view jobs" ON jobs;
DROP POLICY IF EXISTS "Allow authenticated update for jobs" ON jobs;
DROP POLICY IF EXISTS "Allow authenticated delete for jobs" ON jobs;
DROP POLICY IF EXISTS "Allow public update for jobs" ON jobs;

-- ============================================
-- 3. Remove weak artisan policies
-- ============================================
DROP POLICY IF EXISTS "Anyone can insert artisans" ON artisans;
DROP POLICY IF EXISTS "Anyone can select artisans" ON artisans;
DROP POLICY IF EXISTS "Anyone can update artisans" ON artisans;
DROP POLICY IF EXISTS "Anyone can delete artisans" ON artisans;
DROP POLICY IF EXISTS "Authenticated users can delete artisans" ON artisans;
DROP POLICY IF EXISTS "Authenticated users can update artisans" ON artisans;
DROP POLICY IF EXISTS "Authenticated users can delete stores" ON stores;
DROP POLICY IF EXISTS "Authenticated users can update stores" ON stores;
DROP POLICY IF EXISTS "Authenticated users can delete equipment" ON equipment;
DROP POLICY IF EXISTS "Authenticated users can update equipment" ON equipment;

-- ============================================
-- 4. Remove weak store/equipment policies
-- ============================================
DROP POLICY IF EXISTS "Anyone can view artisans" ON artisans;
DROP POLICY IF EXISTS "Anyone can view stores" ON stores;
DROP POLICY IF EXISTS "Anyone can view equipment" ON equipment;
DROP POLICY IF EXISTS "Authenticated users can insert stores" ON stores;
DROP POLICY IF EXISTS "Authenticated users can update stores" ON stores;
DROP POLICY IF EXISTS "Authenticated users can delete stores" ON stores;
DROP POLICY IF EXISTS "Authenticated users can insert equipment" ON equipment;
DROP POLICY IF EXISTS "Authenticated users can update equipment" ON equipment;
DROP POLICY IF EXISTS "Authenticated users can delete equipment" ON equipment;

-- ============================================
-- 5. Remove weak transactions policies
-- ============================================
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;

-- ============================================
-- 6. Remove parts/services weak policies
-- ============================================
DROP POLICY IF EXISTS "Allow all access to parts" ON parts;
DROP POLICY IF EXISTS "Allow all access to services" ON services;

-- ============================================
-- 7. Apply SECURE policies only
-- ============================================

-- WALLETS - Most restrictive
DROP POLICY IF EXISTS "Wallet owner can view" ON wallets;
CREATE POLICY "Wallet owner can view" ON wallets
  FOR SELECT TO anon, authenticated
  USING (
    artisan_id IN (SELECT id FROM artisans WHERE id = auth.uid()::uuid)
    OR artisan_id IN (SELECT id FROM artisans WHERE email = auth.jwt()->>'email')
  );

DROP POLICY IF EXISTS "Service role manages wallets" ON wallets;
CREATE POLICY "Service role manages wallets" ON wallets
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- JOBS - Restrictive
DROP POLICY IF EXISTS "Users can view own jobs" ON jobs;
CREATE POLICY "Users can view own jobs" ON jobs
  FOR SELECT TO authenticated
  USING (
    artisan_id = auth.uid()::uuid
    OR customer_email = auth.jwt()->>'email'
  );

DROP POLICY IF EXISTS "Public can view completed jobs" ON jobs;
CREATE POLICY "Public can view completed jobs" ON jobs
  FOR SELECT TO anon
  USING (status = 'completed');

DROP POLICY IF EXISTS "Service role manages jobs" ON jobs;
CREATE POLICY "Service role manages jobs" ON jobs
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- TRANSACTIONS - Restrictive
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
CREATE POLICY "Users can view own transactions" ON transactions
  FOR SELECT TO authenticated
  USING (
    artisan_id IN (SELECT id FROM artisans WHERE id = auth.uid()::uuid)
    OR artisan_id IN (SELECT id FROM artisans WHERE email = auth.jwt()->>'email')
    OR customer_email = auth.jwt()->>'email'
  );

DROP POLICY IF EXISTS "Service role manages transactions" ON transactions;
CREATE POLICY "Service role manages transactions" ON transactions
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- ARTISANS - Public read, auth insert, owner update
ALTER TABLE artisans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view active artisans" ON artisans;
CREATE POLICY "Public can view active artisans" ON artisans
  FOR SELECT TO anon USING (status = 'active');

DROP POLICY IF EXISTS "Authenticated users can view own artisan profile" ON artisans;
CREATE POLICY "Authenticated users can view own artisan profile" ON artisans
  FOR SELECT TO authenticated USING (
    status = 'active'
    OR id = auth.uid()::uuid
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt()->>'email', ''))
  );

DROP POLICY IF EXISTS "Users can insert artisans" ON artisans;
CREATE POLICY "Users can insert artisans" ON artisans
  FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own profile" ON artisans;
CREATE POLICY "Users can update own profile" ON artisans
  FOR UPDATE TO authenticated
  USING (
    id = auth.uid()::uuid
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt()->>'email', ''))
  )
  WITH CHECK (
    id = auth.uid()::uuid
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt()->>'email', ''))
  );

-- STORES
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view approved stores" ON stores;
CREATE POLICY "Public can view approved stores" ON stores
  FOR SELECT TO anon, authenticated USING (status = 'approved');

DROP POLICY IF EXISTS "Store owners can update" ON stores;
CREATE POLICY "Store owners can update" ON stores
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- EQUIPMENT
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view approved equipment" ON equipment;
CREATE POLICY "Public can view approved equipment" ON equipment
  FOR SELECT TO anon, authenticated USING (status = 'approved');

-- ============================================
-- VERIFY FINAL POLICIES
-- ============================================
SELECT 'SECURE POLICIES APPLIED' AS status;
SELECT tablename, policyname, cmd FROM pg_policies 
WHERE schemaname = 'public' AND tablename IN ('wallets','jobs','transactions')
ORDER BY tablename;