-- Fix wallets RLS - Make wallet creation trigger run with elevated privileges
-- Run in Supabase SQL Editor

-- PRODUCTION NOTES:
-- 1. Wallet balances are sensitive financial data and must never be readable by anon/public.
-- 2. Wallet rows should be auto-created by trigger and modified only by trusted server code.
-- 3. If the app still depends on legacy custom login + direct wallet table reads/updates,
--    migrate those flows to Supabase Auth or Edge Functions before enforcing strict RLS.

ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- Ensure ON CONFLICT(artisan_id) is backed by a unique constraint/index.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'wallets_artisan_id_unique'
  ) THEN
    ALTER TABLE wallets
      ADD CONSTRAINT wallets_artisan_id_unique UNIQUE (artisan_id);
  END IF;
END
$$;

-- Recreate the wallet trigger function as SECURITY DEFINER with an explicit search_path.
-- This avoids search_path hijacking in definer functions.

CREATE OR REPLACE FUNCTION create_wallet_for_artisan()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO wallets (artisan_id, pending_balance, available_balance)
    VALUES (NEW.id, 0, 0)
    ON CONFLICT (artisan_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Optional hardening: prevent arbitrary direct execution of the trigger function.
REVOKE ALL ON FUNCTION create_wallet_for_artisan() FROM PUBLIC;

DROP TRIGGER IF EXISTS trigger_create_wallet_on_artisan ON artisans;
CREATE TRIGGER trigger_create_wallet_on_artisan
  AFTER INSERT ON artisans
  FOR EACH ROW
  EXECUTE FUNCTION create_wallet_for_artisan();

-- Clean up old/weak policies first.
DROP POLICY IF EXISTS "Anyone can insert wallets" ON wallets;
DROP POLICY IF EXISTS "Anyone can select wallets" ON wallets;
DROP POLICY IF EXISTS "Anyone can update wallets" ON wallets;
DROP POLICY IF EXISTS "Authenticated users full access" ON wallets;
DROP POLICY IF EXISTS "Service role wallets" ON wallets;
DROP POLICY IF EXISTS "Artisans can view own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can insert own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can view own wallet" ON wallets;
CREATE POLICY "Users can view own wallet" ON wallets
  FOR SELECT TO authenticated
  USING (artisan_id IN (SELECT id FROM artisans WHERE email = auth.jwt()->>'email'));

DROP POLICY IF EXISTS "Users can update own wallet" ON wallets;
-- Intentionally do NOT allow client-side INSERT/UPDATE on wallets in production.
-- Wallet creation is handled by trigger; wallet writes should happen via service role / server code.

-- Service role can still do everything
DROP POLICY IF EXISTS "Service role manages wallets" ON wallets;
CREATE POLICY "Service role manages wallets" ON wallets
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- Remove legacy public/anon read access.
DROP POLICY IF EXISTS "Wallet owner can view" ON wallets;
DROP POLICY IF EXISTS "Public can view wallets" ON wallets;

SELECT 'Wallets RLS hardened for production: trigger secured, public access removed, writes restricted to trusted server role' AS status;