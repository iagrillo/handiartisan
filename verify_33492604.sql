-- Verify wallet for artisan 33492604-99d7-43f0-8a6e-ec947eddfa51
-- Run in Supabase SQL Editor

-- Check current wallet status
SELECT * FROM wallets WHERE artisan_id = '33492604-99d7-43f0-8a6e-ec947eddfa51';

-- Manually verify the wallet
UPDATE wallets 
SET is_verified = true, updated_at = NOW() 
WHERE artisan_id = '33492604-99d7-43f0-8a6e-ec947eddfa51';

-- Verify update worked
SELECT id, artisan_id, is_verified, available_balance, pending_balance 
FROM wallets WHERE artisan_id = '33492604-99d7-43f0-8a6e-ec947eddfa51';