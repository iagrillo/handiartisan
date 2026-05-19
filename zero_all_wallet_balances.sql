-- =============================================
-- ZERO ALL WALLET BALANCES (PRODUCTION SAFE)
-- Run as service_role or with admin privileges in Supabase SQL Editor
-- =============================================

-- 1. Set all wallet balances to zero
UPDATE wallets
SET pending_balance = 0,
    available_balance = 0,
    total_earned = 0,
    total_withdrawn = 0,
    updated_at = NOW();

-- 2. Verify the update (show 10 most recent wallets)
SELECT artisan_id, available_balance, pending_balance, total_earned, total_withdrawn, updated_at
FROM wallets
ORDER BY updated_at DESC NULLS LAST
LIMIT 10;

-- 3. Health check (count wallets with nonzero balances)
SELECT 
  SUM(CASE WHEN COALESCE(available_balance,0) > 0 THEN 1 ELSE 0 END) AS wallets_with_available,
  SUM(CASE WHEN COALESCE(pending_balance,0) > 0 THEN 1 ELSE 0 END) AS wallets_with_pending,
  SUM(CASE WHEN COALESCE(total_earned,0) > 0 THEN 1 ELSE 0 END) AS wallets_with_earned,
  SUM(CASE WHEN COALESCE(total_withdrawn,0) > 0 THEN 1 ELSE 0 END) AS wallets_with_withdrawn
FROM wallets;

-- If all counts above are zero, all balances are reset.
