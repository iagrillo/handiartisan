-- ============================================
-- COMPLETE FIX FOR HANDIHUB APP
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Fix artisans - set status to 'active'
UPDATE artisans SET status = 'active' WHERE status IS NULL OR status = '';

-- Step 2: Fix stores - set status to 'approved' 
UPDATE stores SET status = 'approved' WHERE status IS NULL OR status = '';

-- Step 3: Fix equipment - set status to 'approved'
UPDATE equipment SET status = 'approved' WHERE status IS NULL OR status = '';

-- Step 4: Check current status values
SELECT 'artisans' as table_name, status, COUNT(*) as count FROM artisans GROUP BY status
UNION ALL
SELECT 'stores', status, COUNT(*) FROM stores GROUP BY status
UNION ALL
SELECT 'equipment', status, COUNT(*) FROM equipment GROUP BY status;

-- Step 5: If created_at columns don't exist, add them
-- Check and add created_at to equipment if missing
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Check and add created_at to stores if missing
ALTER TABLE stores ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Check and add created_at to artisans if missing
ALTER TABLE artisans ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
