-- ============================================
-- Check the create_wallet_for_artisan function
-- Run this in Supabase SQL Editor
-- ============================================

-- Get the function definition
SELECT 
    proname AS function_name,
    prosrc AS function_body
FROM pg_proc
WHERE proname = 'create_wallet_for_artisan';

-- Also check if there's a unique constraint on wallets table
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'wallets';
