-- Verify secure policies are applied
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual IS NULL THEN 'No filter'
        WHEN qual LIKE '%auth.uid()%' THEN 'Owner only'
        WHEN qual LIKE '%status =%' THEN 'Status filtered'
        WHEN qual LIKE '%service_role%' THEN 'Service role only'
        ELSE 'Custom'
    END as access_type
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('wallets','jobs','transactions','artisans','stores','equipment')
ORDER BY tablename, policyname;