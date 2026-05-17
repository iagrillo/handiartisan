-- Add missing estimate columns to jobs table
-- Run this in Supabase SQL Editor

-- Add estimate columns if they don't exist
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_materials JSONB;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_materials_cost DECIMAL;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_labor_cost DECIMAL;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_total DECIMAL;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_timeline VARCHAR;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_notes TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_submitted_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_status VARCHAR DEFAULT 'pending';

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'jobs' 
AND column_name LIKE 'estimate%';
