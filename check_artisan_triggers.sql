-- ============================================
-- Check for triggers on artisans table
-- Run this in Supabase SQL Editor
-- ============================================

-- List all triggers on artisans table
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_orientation
FROM information_schema.triggers
WHERE event_object_table = 'artisans'
ORDER BY trigger_name;

-- Also check for any triggers using pg_trigger
SELECT 
    tgname AS trigger_name,
    proname AS function_name,
    prosrc AS function_body
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE NOT t.tgisinternal
AND tgrelid = 'artisans'::regclass;
