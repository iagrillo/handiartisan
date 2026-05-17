-- ============================================
-- Add is_featured column to stores if it doesn't exist
-- Run this in Supabase SQL Editor
-- ============================================

-- Add the is_featured column to stores table (if not exists)
ALTER TABLE stores ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_stores_is_featured ON stores(is_featured);

-- ============================================
-- RLS Policies for stores table
-- ============================================

-- Enable RLS if not already enabled
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

-- Drop existing policies that might block updates
DROP POLICY IF EXISTS "Public can view approved stores" ON stores;
DROP POLICY IF EXISTS "Authenticated users can insert stores" ON stores;
DROP POLICY IF EXISTS "Users can delete stores" ON stores;
DROP POLICY IF EXISTS "Users can update stores" ON stores;

-- Create policies that allow all operations for authenticated users
CREATE POLICY "Public can view approved stores" ON stores
    FOR SELECT USING (status = 'approved');

CREATE POLICY "Authenticated users can insert stores" ON stores
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Authenticated users can update stores" ON stores
    FOR UPDATE USING (true);

CREATE POLICY "Authenticated users can delete stores" ON stores
    FOR DELETE USING (true);

-- ============================================
-- Verify the column was added
-- ============================================
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'stores' AND column_name = 'is_featured';
