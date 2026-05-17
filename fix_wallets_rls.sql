-- Fix wallets RLS for user self-insertion (for auto-created wallets)
-- Run in Supabase SQL Editor

-- ============================================
-- UNSAFE FOR PRODUCTION (financial integrity risk)
-- ============================================
-- This script allows direct client UPDATE on wallets which can enable
-- user-side balance tampering in legacy/custom-auth flows.
--
-- Use `fix_wallet_trigger.sql` for production.
--
-- To use this script only in a throwaway test environment,
-- remove the guard block below.
DO $$
BEGIN
  RAISE EXCEPTION 'Blocked: fix_wallets_rls.sql is unsafe for production. Use fix_wallet_trigger.sql.';
END
$$;

-- Allow users to insert their own wallet (for trigger-created wallets)
CREATE POLICY "Users can insert own wallet" ON wallets
  FOR INSERT TO authenticated
  WITH CHECK (artisan_id = auth.uid()::uuid);

-- Allow users to view own wallet
CREATE POLICY "Users can view own wallet" ON wallets
  FOR SELECT TO authenticated
  USING (artisan_id = auth.uid()::uuid);

-- Allow users to update own wallet
CREATE POLICY "Users can update own wallet" ON wallets
  FOR UPDATE TO authenticated
  USING (artisan_id = auth.uid()::uuid)
  WITH CHECK (artisan_id = auth.uid()::uuid);

-- Keep service role policy for admin operations
DROP POLICY IF EXISTS "Service role manages wallets" ON wallets;
CREATE POLICY "Service role manages wallets" ON wallets
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

SELECT 'Wallets RLS policies updated' AS status;