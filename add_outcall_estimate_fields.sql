-- ============================================
-- Complete Outcall Verification & Estimate Schema
-- ============================================

-- 1. Add outcall verification fields to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS outcall_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS outcall_verified_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS outcall_fee_released BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS arrival_otp VARCHAR(10),
ADD COLUMN IF NOT EXISTS customer_confirmed_arrival BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS customer_latitude DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS customer_longitude DECIMAL(11, 8);

-- 2. Add estimate fields to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS estimate_id UUID,
ADD COLUMN IF NOT EXISTS estimate_status VARCHAR(20) DEFAULT 'pending';

-- 3. Create estimates table
CREATE TABLE IF NOT EXISTS estimates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_reference VARCHAR(50) NOT NULL,
  artisan_id UUID NOT NULL,
  materials JSONB NOT NULL DEFAULT '[]',
  labor_cost DECIMAL(12, 2) NOT NULL DEFAULT 0,
  timeline VARCHAR(100),
  total DECIMAL(12, 2) NOT NULL DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for estimates
CREATE INDEX IF NOT EXISTS idx_estimates_job_ref ON estimates(job_reference);
CREATE INDEX IF NOT EXISTS idx_estimates_artisan ON estimates(artisan_id);

-- Enable RLS on estimates
ALTER TABLE estimates ENABLE ROW LEVEL SECURITY;

-- RLS policies for estimates
DROP POLICY IF EXISTS "Anyone can read estimates" ON estimates;
CREATE POLICY "Anyone can read estimates" ON estimates
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Service role can insert estimates" ON estimates;
CREATE POLICY "Service role can insert estimates" ON estimates
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role can update estimates" ON estimates;
CREATE POLICY "Service role can update estimates" ON estimates
  FOR UPDATE USING (auth.role() = 'service_role');

-- 4. Create outcall_transactions table for logging releases
CREATE TABLE IF NOT EXISTS outcall_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_reference VARCHAR(50) NOT NULL,
  artisan_id UUID NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  type VARCHAR(20) NOT NULL,
  status VARCHAR(20) DEFAULT 'completed',
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for outcall_transactions
CREATE INDEX IF NOT EXISTS idx_outcall_transactions_job ON outcall_transactions(job_reference);
CREATE INDEX IF NOT EXISTS idx_outcall_transactions_artisan ON outcall_transactions(artisan_id);

-- Enable RLS on outcall_transactions
ALTER TABLE outcall_transactions ENABLE ROW LEVEL SECURITY;

-- RLS policies
DROP POLICY IF EXISTS "Anyone can read outcall transactions" ON outcall_transactions;
CREATE POLICY "Anyone can read outcall transactions" ON outcall_transactions
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Service role can insert outcall transactions" ON outcall_transactions;
CREATE POLICY "Service role can insert outcall transactions" ON outcall_transactions
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- 5. Add outcall fee tracking to wallets table
ALTER TABLE wallets 
ADD COLUMN IF NOT EXISTS outcall_fee_total DECIMAL(12, 2) DEFAULT 0;

-- 6. Create job_contracts table for accepted estimates with escrow
CREATE TABLE IF NOT EXISTS job_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_reference VARCHAR(50) UNIQUE NOT NULL,
  job_reference VARCHAR(50) NOT NULL,
  artisan_id UUID NOT NULL,
  customer_id UUID NOT NULL,
  estimate_id UUID,
  total_amount DECIMAL(12, 2) NOT NULL,
  escrow_amount DECIMAL(12, 2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  payment_status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for job_contracts
CREATE INDEX IF NOT EXISTS idx_job_contracts_job_ref ON job_contracts(job_reference);
CREATE INDEX IF NOT EXISTS idx_job_contracts_artisan ON job_contracts(artisan_id);
CREATE INDEX IF NOT EXISTS idx_job_contracts_customer ON job_contracts(customer_id);

-- Enable RLS on job_contracts
ALTER TABLE job_contracts ENABLE ROW LEVEL SECURITY;

-- RLS policies
DROP POLICY IF EXISTS "Anyone can read contracts" ON job_contracts;
CREATE POLICY "Anyone can read contracts" ON job_contracts
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Service role can manage contracts" ON job_contracts;
CREATE POLICY "Service role can manage contracts" ON job_contracts
  FOR ALL USING (auth.role() = 'service_role');

-- 7. Add foreign key for estimate_id in jobs
ALTER TABLE jobs 
ADD CONSTRAINT fk_jobs_estimate 
FOREIGN KEY (estimate_id) 
REFERENCES estimates(id) 
ON DELETE SET NULL;

-- 8. Add function to generate arrival OTP automatically
CREATE OR REPLACE FUNCTION generate_arrival_otp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.arrival_otp := LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for new outcall jobs
DROP TRIGGER IF EXISTS generate_otp_on_job_create ON jobs;
CREATE TRIGGER generate_otp_on_job_create
  BEFORE INSERT ON jobs
  FOR EACH ROW
  WHEN (NEW.service_type = 'outcall')
  EXECUTE FUNCTION generate_arrival_otp();

-- Comments for documentation
COMMENT ON COLUMN jobs.outcall_verified IS 'Whether outcall visit has been verified';
COMMENT ON COLUMN jobs.outcall_verified_at IS 'Timestamp when outcall was verified';
COMMENT ON COLUMN jobs.outcall_fee_released IS 'Whether the outcall fee has been released to artisan';
COMMENT ON COLUMN jobs.arrival_otp IS 'One-time password for artisan arrival verification';
COMMENT ON COLUMN jobs.customer_confirmed_arrival IS 'Customer confirms artisan has arrived';
COMMENT ON COLUMN jobs.customer_latitude IS 'Customer location latitude for geo-verification';
COMMENT ON COLUMN jobs.customer_longitude IS 'Customer location longitude for geo-verification';
COMMENT ON COLUMN jobs.estimate_id IS 'Link to submitted estimate';
COMMENT ON COLUMN jobs.estimate_status IS 'Status of estimate: pending, accepted, declined';
COMMENT ON COLUMN estimates.materials IS 'JSON array of materials with costs';
COMMENT ON COLUMN estimates.status IS 'Estimate status: pending, accepted, declined';
COMMENT ON COLUMN wallets.outcall_fee_total IS 'Total outcall fees earned by artisan';
COMMENT ON COLUMN outcall_transactions.type IS 'Transaction type: outcall_fee, escrow_release, etc';
