-- ============================================
-- HandiHub Payment System - Database Schema
-- Run this SQL in Supabase SQL Editor
-- Paystack Escrow + Wallet System
-- ============================================

-- ============================================
-- JOBS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS jobs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    job_reference VARCHAR(50) NOT NULL UNIQUE,
    artisan_id UUID REFERENCES artisans(id) ON DELETE CASCADE,
    customer_email VARCHAR(150) NOT NULL,
    customer_phone VARCHAR(20),
    customer_name VARCHAR(150),
    service_type VARCHAR(100),
    description TEXT,
    address TEXT,
    amount_paid INTEGER NOT NULL DEFAULT 0,
    escrow_amount INTEGER NOT NULL DEFAULT 0,
    commission_amount INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    -- Status values: pending, paid, in_progress, completed, failed, cancelled, refunded
    payment_reference VARCHAR(100),
    transfer_reference VARCHAR(100),
    refund_reference VARCHAR(100),
    scheduled_date TIMESTAMP WITH TIME ZONE,
    completed_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Indexes for jobs
CREATE INDEX IF NOT EXISTS idx_jobs_artisan_id ON jobs(artisan_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_payment_reference ON jobs(payment_reference);
CREATE INDEX IF NOT EXISTS idx_jobs_job_reference ON jobs(job_reference);

-- ============================================
-- WALLETS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS wallets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    artisan_id UUID REFERENCES artisans(id) ON DELETE CASCADE UNIQUE,
    pending_balance INTEGER NOT NULL DEFAULT 0,
    available_balance INTEGER NOT NULL DEFAULT 0,
    total_earned INTEGER NOT NULL DEFAULT 0,
    total_withdrawn INTEGER NOT NULL DEFAULT 0,
    paystack_transfer_code VARCHAR(100),
    paystack_recipient_code VARCHAR(100),
    bank_name VARCHAR(100),
    account_number VARCHAR(20),
    account_name VARCHAR(150),
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- Index for wallets
CREATE INDEX IF NOT EXISTS idx_wallets_artisan_id ON wallets(artisan_id);

-- ============================================
-- TRANSACTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reference VARCHAR(100) NOT NULL UNIQUE,
    job_reference VARCHAR(50),
    artisan_id UUID REFERENCES artisans(id) ON DELETE SET NULL,
    customer_email VARCHAR(150),
    amount INTEGER NOT NULL,
    fee INTEGER NOT NULL DEFAULT 0,
    net_amount INTEGER NOT NULL,
    type VARCHAR(30) NOT NULL,
    -- Type: payment, escrow, payout, refund, commission, withdrawal
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    -- Status: pending, success, failed
    paystack_response JSONB,
    failure_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for transactions
CREATE INDEX IF NOT EXISTS idx_transactions_job_reference ON transactions(job_reference);
CREATE INDEX IF NOT EXISTS idx_transactions_artisan_id ON transactions(artisan_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_reference ON transactions(reference);

-- ============================================
-- AUTO-CREATE WALLET TRIGGER
-- ============================================
-- Create a function to auto-create wallet when artisan is created
CREATE OR REPLACE FUNCTION create_wallet_for_artisan()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO wallets (artisan_id, pending_balance, available_balance)
    VALUES (NEW.id, 0, 0)
    ON CONFLICT (artisan_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_create_wallet_on_artisan ON artisans;
CREATE TRIGGER trigger_create_wallet_on_artisan
    AFTER INSERT ON artisans
    FOR EACH ROW
    EXECUTE FUNCTION create_wallet_for_artisan();

-- ============================================
-- REAL-TIME ENABLEMENT
-- ============================================
-- Add tables to realtime (ignore if already exists)
ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS wallets;
ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS jobs;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Jobs policies
CREATE POLICY "Users can view own jobs" ON jobs
    FOR SELECT USING (auth.uid()::text IN (
        SELECT id::text FROM artisans WHERE email = auth.jwt()->>'email'
    ));

CREATE POLICY "Service role can manage jobs" ON jobs
    FOR ALL USING (auth.role() = 'service_role');

-- Wallets policies - artisans can view their own wallet
CREATE POLICY "Artisans can view own wallet" ON wallets
    FOR SELECT USING (
        artisan_id IN (SELECT id FROM artisans WHERE email = auth.jwt()->>'email')
    );

CREATE POLICY "Service role can manage wallets" ON wallets
    FOR ALL USING (auth.role() = 'service_role');

-- Transactions policies
CREATE POLICY "Users can view own transactions" ON transactions
    FOR SELECT USING (
        artisan_id IN (SELECT id FROM artisans WHERE email = auth.jwt()->>'email')
        OR (customer_email = auth.jwt()->>'email')
    );

CREATE POLICY "Service role can manage transactions" ON transactions
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Generate unique job reference
CREATE OR REPLACE FUNCTION generate_job_reference()
RETURNS TRIGGER AS $$
DECLARE
    ref_text TEXT;
    ref_count INTEGER;
BEGIN
    SELECT COUNT(*) + 1 INTO ref_count FROM jobs;
    ref_count := COALESCE(ref_count, 1);
    NEW.job_reference := 'HANDIHUB_JOB_' || LPAD(ref_count::TEXT, 8, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PRINT SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Payment system schema created successfully!';
    RAISE NOTICE 'Tables: jobs, wallets, transactions';
    RAISE NOTICE 'Real-time enabled on all payment tables';
END $$;
