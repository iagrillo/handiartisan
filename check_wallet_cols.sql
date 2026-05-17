-- Check wallet table columns - run in Supabase SQL Editor
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'wallets'
ORDER BY ordinal_position;