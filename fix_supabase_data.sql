-- ============================================
-- Fix: Update artisans status to 'active'
-- Run this in Supabase SQL Editor
-- ============================================

-- Update all artisans to have status = 'active' (if they don't have a status)
UPDATE artisans 
SET status = 'active' 
WHERE status IS NULL OR status = '';

-- OR if you want to update ALL artisans regardless of current status:
-- UPDATE artisans SET status = 'active';

-- ============================================
-- Fix: Update stores status to 'approved'
-- ============================================

-- Update all stores to have status = 'approved' (if they don't have a status)
UPDATE stores 
SET status = 'approved' 
WHERE status IS NULL OR status = '';

-- OR if you want to update ALL stores regardless of current status:
-- UPDATE stores SET status = 'approved';

-- ============================================
-- Fix: Update equipment status to 'approved'
-- ============================================

-- Update all equipment to have status = 'approved' (if they don't have a status)
UPDATE equipment 
SET status = 'approved' 
WHERE status IS NULL OR status = '';

-- OR if you want to update ALL equipment regardless of current status:
-- UPDATE equipment SET status = 'approved';

-- ============================================
-- Verify the data after update
-- ============================================

-- Check artisans status distribution
SELECT status, COUNT(*) as count FROM artisans GROUP BY status;

-- Check stores status distribution
SELECT status, COUNT(*) as count FROM stores GROUP BY status;

-- Check equipment status distribution
SELECT status, COUNT(*) as count FROM equipment GROUP BY status;
