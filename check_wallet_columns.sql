-- Get all columns in wallets table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'wallets';