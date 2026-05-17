-- Get all artisans with their wallet status - Run in Supabase SQL Editor
SELECT 
  a.id as artisan_id,
  a.full_name,
  a.email,
  a.phone,
  w.id as wallet_id,
  w.bank_name,
  w.account_number,
  w.account_name,
  w.is_verified,
  w.available_balance,
  w.pending_balance
FROM artisans a
LEFT JOIN wallets w ON w.artisan_id = a.id
ORDER BY a.created_at DESC
LIMIT 20;