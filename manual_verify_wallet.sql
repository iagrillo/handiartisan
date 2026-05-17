-- Manual wallet verification - Run in Supabase SQL Editor
-- Replace 'your-artisan-id' with the actual artisan ID

-- First, get the artisan and their wallet
SELECT 
  a.id as artisan_id,
  a.full_name,
  a.email,
  w.id as wallet_id,
  w.bank_name,
  w.account_number,
  w.account_name,
  w.is_verified
FROM artisans a
LEFT JOIN wallets w ON w.artisan_id = a.id
WHERE a.id = 'your-artisan-id';

-- To manually verify a wallet (set is_verified = true)
UPDATE wallets 
SET is_verified = true, updated_at = NOW() 
WHERE artisan_id = 'your-artisan-id';

-- Or to manually set bank details and verify
UPDATE wallets SET
  bank_name = 'guaranty trust bank',
  account_number = '1234567890',
  account_name = 'John Doe',
  is_verified = true,
  updated_at = NOW()
WHERE artisan_id = 'your-artisan-id';