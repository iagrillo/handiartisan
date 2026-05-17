-- ============================================
-- Add is_featured column to stores if it doesn't exist
-- Run this in Supabase SQL Editor
-- ============================================

-- Add the is_featured column to stores table (if not exists)
ALTER TABLE stores ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;

-- Verify the column was added
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'stores' AND column_name = 'is_featured';

-- Set is_featured = false for all existing stores that have NULL
UPDATE stores SET is_featured = false WHERE is_featured IS NULL;
