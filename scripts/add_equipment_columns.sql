-- ============================================
-- ADD NEW COLUMNS TO EQUIPMENT TABLE
-- Run in Supabase SQL Editor
-- ============================================

-- Add new columns for enhanced equipment listing
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS brand text;
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS contact_name text;
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS contact_phone text;
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS rental_period text;
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS rental_rate text;
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS price_type text;

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'equipment'
ORDER BY ordinal_position;
