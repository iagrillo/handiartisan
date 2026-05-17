-- Remove unsafe/duplicate wallet policies
DROP POLICY IF EXISTS "Authenticated users full access" ON wallets;
DROP POLICY IF EXISTS "Service role wallets" ON wallets;
DROP POLICY IF EXISTS "Artisans can view own wallet" ON wallets;

SELECT policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'wallets'
ORDER BY policyname;
