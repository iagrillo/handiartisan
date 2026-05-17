-- ============================================
-- UNSAFE LEGACY SCRIPT - DO NOT RUN IN PRODUCTION
-- ============================================
-- This script grants broad wallet access (insert/select/update using true)
-- and can expose/tamper with financial balances.
--
-- Use `fix_wallet_trigger.sql` instead for hardened production policies.
--
-- To intentionally run this legacy script in a non-production sandbox,
-- remove the DO block below.
DO $$
BEGIN
	RAISE EXCEPTION 'Blocked: fix_wallet_policies.sql is unsafe for production. Use fix_wallet_trigger.sql.';
END
$$;

-- Add INSERT policy for wallets table
DROP POLICY IF EXISTS "Anyone can insert wallets" ON wallets;
CREATE POLICY "Anyone can insert wallets" ON wallets FOR INSERT WITH CHECK (true);

-- Add SELECT policy
DROP POLICY IF EXISTS "Anyone can select wallets" ON wallets;
CREATE POLICY "Anyone can select wallets" ON wallets FOR SELECT USING (true);

-- Add UPDATE policy
DROP POLICY IF EXISTS "Anyone can update wallets" ON wallets;
CREATE POLICY "Anyone can update wallets" ON wallets FOR UPDATE USING (true);

-- Verify policies
SELECT tablename, policyname, cmd FROM pg_policies WHERE tablename = 'wallets';
