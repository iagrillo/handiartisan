-- ============================================
-- Debug: Check all triggers on artisans table
-- Run this in Supabase SQL Editor
-- ============================================

-- List all triggers on artisans table
SELECT 
    tgname AS trigger_name,
    proname AS function_name,
    prosrc AS function_body
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'artisans'::regclass;

-- List all RLS policies on artisans table
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'artisans';

-- Check if there are any constraints (unique or otherwise)
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'artisans';
