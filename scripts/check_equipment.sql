-- ============================================
-- SQL to check equipment data in Supabase
-- Run this in Supabase SQL Editor
-- ============================================

-- View all equipment records
SELECT * FROM equipment ORDER BY created_at DESC;

-- View approved equipment only
SELECT * FROM equipment WHERE status = 'approved' ORDER BY created_at DESC;

-- Count total equipment
SELECT COUNT(*) as total_equipment FROM equipment;

-- Check table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'equipment';
