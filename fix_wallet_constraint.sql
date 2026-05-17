-- ============================================
-- Fix: Add unique constraint to wallets table
-- Run this in Supabase SQL Editor
-- ============================================

-- Add unique constraint to wallets table (needed for ON CONFLICT in trigger)
ALTER TABLE wallets ADD CONSTRAINT wallets_artisan_id_unique UNIQUE (artisan_id);
