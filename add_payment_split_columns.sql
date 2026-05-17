-- Add columns to track materials and labor payment splits
-- Run this in Supabase SQL Editor

-- Add payment split columns to jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS materials_cost_paid DECIMAL(12, 2) DEFAULT 0;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS labor_cost_paid DECIMAL(12, 2) DEFAULT 0;

-- Add comments
COMMENT ON COLUMN jobs.materials_cost_paid IS 'Materials amount paid - goes to available balance immediately';
COMMENT ON COLUMN jobs.labor_cost_paid IS 'Labor amount paid - held in pending until job completion';
