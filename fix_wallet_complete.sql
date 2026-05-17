-- ============================================
-- UNSAFE LEGACY SCRIPT - DO NOT RUN IN PRODUCTION
-- ============================================
-- This script creates overly permissive wallet access policies.
--
-- Use `fix_wallet_trigger.sql` for production-safe wallet trigger + RLS.
--
-- To run this only in a disposable local/dev sandbox,
-- remove the guard block below.
DO $$
BEGIN
  RAISE EXCEPTION 'Blocked: fix_wallet_complete.sql is unsafe for production. Use fix_wallet_trigger.sql.';
END
$$;

-- Complete wallet fix - Run in Supabase SQL Editor

-- 1. Add missing columns if they don't exist
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100);
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS account_number VARCHAR(20);
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS account_name VARCHAR(150);

-- 2. Drop all existing wallet policies
DROP POLICY IF EXISTS "Wallet owner can view" ON wallets;
DROP POLICY IF EXISTS "Users can view own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can insert own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can update own wallet" ON wallets;
DROP POLICY IF EXISTS "Service role manages wallets" ON wallets;

-- 3. Create simple permissive policies for now (can tighten later)
-- Allow all authenticated users to do everything with wallets
CREATE POLICY "Authenticated users full access" ON wallets
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- Service role can do everything
CREATE POLICY "Service role wallets" ON wallets
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- 4. Create wallets for artisans who don't have one
INSERT INTO wallets (artisan_id, pending_balance, available_balance)
SELECT id, 0, 0 FROM artisans
WHERE NOT EXISTS (SELECT 1 FROM wallets WHERE wallets.artisan_id = artisans.id);

-- 5. Show result
SELECT 
  a.id as artisan_id,
  a.full_name,
  w.id as wallet_id,
  w.is_verified,
  w.bank_name,
  w.account_number,
  w.available_balance,
  w.pending_balance
FROM artisans a
LEFT JOIN wallets w ON w.artisan_id = a.id
ORDER BY a.created_at DESC
LIMIT 10;