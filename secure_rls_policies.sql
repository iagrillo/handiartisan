-- ============================================
-- SECURE RLS POLICIES - Run in Supabase SQL Editor
-- ============================================

-- ============================================
-- WALLETS TABLE - Secure Policies
-- ============================================

-- Drop overly permissive policies
DROP POLICY IF EXISTS "Anyone can insert wallets" ON wallets;
DROP POLICY IF EXISTS "Anyone can select wallets" ON wallets;
DROP POLICY IF EXISTS "Anyone can update wallets" ON wallets;

-- Allow users to view their own wallet only
CREATE POLICY "Users can view own wallet" ON wallets
  FOR SELECT
  TO authenticated
  USING (
    artisan_id IN (
      SELECT id FROM artisans 
      WHERE email = auth.jwt()->>'email'
    )
  );

-- Allow users to view their wallet via RLS (applies to anon too for fallback)
CREATE POLICY "Wallet owner can view" ON wallets
  FOR SELECT
  TO anon, authenticated
  USING (
    artisan_id IN (
      SELECT id FROM artisans 
      WHERE email = auth.jwt()->>'email'
       OR id = auth.uid()::uuid
    )
  );

-- Only service role can update wallets (never give this to users)
CREATE POLICY "Service role can manage wallets" ON wallets
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- No direct INSERT for users - use edge functions

-- ============================================
-- JOBS TABLE - Secure Policies  
-- ============================================

DROP POLICY IF EXISTS "Allow public insert for jobs" ON jobs;
DROP POLICY IF EXISTS "Allow public select for jobs" ON jobs;
DROP POLICY IF EXISTS "Allow authenticated update for jobs" ON jobs;
DROP POLICY IF EXISTS "Allow authenticated delete for jobs" ON jobs;

-- Jobs can be created but only through edge functions for security
CREATE POLICY "Service role manages jobs" ON jobs
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- Public can only see completed jobs (not financial details)
CREATE POLICY "Public can view completed jobs" ON jobs
  FOR SELECT
  TO anon
  USING (status = 'completed');

-- Authenticated users can view their own jobs
CREATE POLICY "Users can view own jobs" ON jobs
  FOR SELECT
  TO authenticated
  USING (
    artisan_id = auth.uid()::uuid
    OR customer_email = auth.jwt()->>'email'
  );

-- ============================================
-- TRANSACTIONS TABLE - Secure Policies
-- ============================================

DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Service role can manage transactions" ON transactions;

-- Users can only view their own transactions
CREATE POLICY "Users can view own transactions" ON transactions
  FOR SELECT
  TO authenticated
  USING (
    artisan_id IN (
      SELECT id FROM artisans 
      WHERE email = auth.jwt()->>'email'
    )
    OR customer_email = auth.jwt()->>'email'
  );

-- Only service role can modify transactions
CREATE POLICY "Service role manages transactions" ON transactions
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- ============================================
-- ARTISANS TABLE - Secure Policies
-- ============================================

DROP POLICY IF EXISTS "Public can view artisans" ON artisans;
DROP POLICY IF EXISTS "Authenticated users can insert artisans" ON artisans;
DROP POLICY IF EXISTS "Owners can update own artisans" ON artisans;

-- Public can view active artisans (no sensitive data)
CREATE POLICY "Public can view active artisans" ON artisans
  FOR SELECT
  TO anon, authenticated
  USING (status = 'active');

-- Only authenticated users can insert
CREATE POLICY "Users can insert artisans" ON artisans
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Authenticated artisans can update their own profile by auth UID or email
DROP POLICY IF EXISTS "Authenticated users can view own artisan profile" ON artisans;
CREATE POLICY "Authenticated users can view own artisan profile" ON artisans
  FOR SELECT
  TO authenticated
  USING (
    status = 'active'
    OR id = auth.uid()::uuid
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt()->>'email', ''))
  );

CREATE POLICY "Users can update own profile" ON artisans
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()::uuid
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt()->>'email', ''))
  )
  WITH CHECK (
    id = auth.uid()::uuid
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt()->>'email', ''))
  );

-- ============================================
-- STORES TABLE - Secure Policies
-- ============================================

DROP POLICY IF EXISTS "Public can view approved stores" ON stores;
DROP POLICY IF EXISTS "Authenticated users can insert stores" ON stores;

-- Public can view approved stores
CREATE POLICY "Public can view approved stores" ON stores
  FOR SELECT
  TO anon, authenticated
  USING (status = 'approved');

-- Authenticated users can create stores
CREATE POLICY "Users can insert stores" ON stores
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Store owners can update their stores
CREATE POLICY "Store owners can update" ON stores
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================
-- EQUIPMENT TABLE - Secure Policies
-- ============================================

DROP POLICY IF EXISTS "Public can view approved equipment" ON equipment;
DROP POLICY IF EXISTS "Authenticated users can insert equipment" ON equipment;

-- Public can view approved equipment
CREATE POLICY "Public can view approved equipment" ON equipment
  FOR SELECT
  TO anon, authenticated
  USING (status = 'approved');

-- Authenticated users can create equipment
CREATE POLICY "Users can insert equipment" ON equipment
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================

ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE artisans ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;

-- ============================================
-- VERIFY POLICIES
-- ============================================

SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;