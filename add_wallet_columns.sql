-- Add missing columns to wallets table - Run in Supabase SQL Editor
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100);
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS account_number VARCHAR(20);
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS account_name VARCHAR(150);

-- Now verify the wallet
UPDATE wallets 
SET is_verified = true, updated_at = NOW() 
WHERE artisan_id = '33492604-99d7-43f0-8a6e-ec947eddfa51';

-- Show result
SELECT id, artisan_id, is_verified, bank_name, account_number FROM wallets 
WHERE artisan_id = '33492604-99d7-43f0-8a6e-ec947eddfa51';