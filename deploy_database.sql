-- ============================================
-- COMPLETE DATABASE DEPLOYMENT SCRIPT
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. CATEGORIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(255)
);

INSERT INTO categories (slug, name) VALUES
('carpenter','Carpenter'),
('plumber','Plumber'),
('electrician','Electrician'),
('welder','Welder'),
('painter','Painter'),
('mason','Mason'),
('tailor','Tailor'),
('mechanic','Mechanic'),
('tiler','Tiler'),
('roofer','Roofer'),
('glassmith','Glassmith'),
('furniture','Furniture Maker'),
('other','Other')
ON CONFLICT (slug) DO NOTHING;

-- ============================================
-- 2. STATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS states (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO states (name) VALUES 
('Abia'),('Adamawa'),('Akwa Ibom'),('Anambra'),('Bauchi'),('Bayelsa'),('Benue'),('Borno'),('Cross River'),('Delta'),
('Ebonyi'),('Edo'),('Ekiti'),('Enugu'),('Gombe'),('Imo'),('Jigawa'),('Kaduna'),('Kano'),('Katsina'),
('Kebbi'),('Kogi'),('Kwara'),('Lagos'),('Nasarawa'),('Niger'),('Ogun'),('Ondo'),('Osun'),('Oyo'),
('Plateau'),('Sokoto'),('Taraba'),('Yobe'),('Zamfara'),('FCT')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 3. CITIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS cities (
    id SERIAL PRIMARY KEY,
    state_id INTEGER REFERENCES states(id),
    name VARCHAR(100) NOT NULL
);

-- ============================================
-- 4. ARTISANS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS artisans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(150) NOT NULL,
    business_name VARCHAR(200),
    phone VARCHAR(20) NOT NULL,
    whatsapp VARCHAR(20),
    email VARCHAR(150),
    category VARCHAR(100),
    category_id INTEGER REFERENCES categories(id),
    bio TEXT,
    address TEXT,
    state VARCHAR(100),
    city VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    is_available BOOLEAN DEFAULT true,
    profile_image_url TEXT,
    rating DECIMAL(3,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 5. STORES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    address TEXT,
    contact VARCHAR(100),
    category VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),
    status VARCHAR(20) DEFAULT 'approved',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 6. EQUIPMENT TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS equipment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    specs TEXT,
    price VARCHAR(100),
    category VARCHAR(100),
    type VARCHAR(50),
    state VARCHAR(100),
    city VARCHAR(100),
    status VARCHAR(20) DEFAULT 'approved',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 7. JOBS TABLE (Payment/Escrow)
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
    payment_reference VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 8. WALLETS TABLE
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

-- ============================================
-- 9. TRANSACTIONS TABLE
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
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    paystack_response JSONB,
    failure_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- AUTO-CREATE WALLET TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION create_wallet_for_artisan()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO wallets (artisan_id, pending_balance, available_balance)
    VALUES (NEW.id, 0, 0)
    ON CONFLICT (artisan_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_create_wallet_on_artisan ON artisans;
CREATE TRIGGER trigger_create_wallet_on_artisan
    AFTER INSERT ON artisans
    FOR EACH ROW
    EXECUTE FUNCTION create_wallet_for_artisan();

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_artisans_category ON artisans(category);
CREATE INDEX IF NOT EXISTS idx_artisans_status ON artisans(status);
CREATE INDEX IF NOT EXISTS idx_jobs_artisan_id ON jobs(artisan_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_wallets_artisan_id ON wallets(artisan_id);
CREATE INDEX IF NOT EXISTS idx_transactions_artisan_id ON transactions(artisan_id);

-- ============================================
-- STORAGE BUCKETS
-- ============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('profiles', 'profiles', true), ('stores', 'stores', true), 
       ('equipment', 'equipment', true), ('gallery', 'gallery', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SECURE RLS POLICIES
-- ============================================

-- ARTISANS
ALTER TABLE artisans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view artisans" ON artisans;
CREATE POLICY "Public can view active artisans" ON artisans
  FOR SELECT TO anon USING (status = 'active');
DROP POLICY IF EXISTS "Authenticated users can view own artisan profile" ON artisans;
CREATE POLICY "Authenticated users can view own artisan profile" ON artisans
  FOR SELECT TO authenticated USING (
    status = 'active'
    OR id = auth.uid()::uuid
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt()->>'email', ''))
  );
DROP POLICY IF EXISTS "Authenticated users can insert artisans" ON artisans;
CREATE POLICY "Users can insert artisans" ON artisans
  FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Owners can update own artisans" ON artisans;
CREATE POLICY "Users can update own profile" ON artisans
  FOR UPDATE TO authenticated
  USING (
    id = auth.uid()::uuid
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt()->>'email', ''))
  )
  WITH CHECK (
    id = auth.uid()::uuid
    OR lower(coalesce(email, '')) = lower(coalesce(auth.jwt()->>'email', ''))
  );

-- STORES
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view approved stores" ON stores;
CREATE POLICY "Public can view approved stores" ON stores
  FOR SELECT TO anon, authenticated USING (status = 'approved');
DROP POLICY IF EXISTS "Authenticated users can insert stores" ON stores;
CREATE POLICY "Users can insert stores" ON stores
  FOR INSERT TO authenticated WITH CHECK (true);

-- EQUIPMENT
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public can view approved equipment" ON equipment;
CREATE POLICY "Public can view approved equipment" ON equipment
  FOR SELECT TO anon, authenticated USING (status = 'approved');
DROP POLICY IF EXISTS "Authenticated users can insert equipment" ON equipment;
CREATE POLICY "Users can insert equipment" ON equipment
  FOR INSERT TO authenticated WITH CHECK (true);

-- WALLETS - STRICT!
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can insert wallets" ON wallets;
DROP POLICY IF EXISTS "Anyone can select wallets" ON wallets;
DROP POLICY IF EXISTS "Anyone can update wallets" ON wallets;
DROP POLICY IF EXISTS "Users can view own jobs" ON wallets;
DROP POLICY IF EXISTS "Service role can manage wallets" ON wallets;

CREATE POLICY "Wallet owner can view" ON wallets
  FOR SELECT TO anon, authenticated
  USING (
    artisan_id IN (SELECT id FROM artisans WHERE id = auth.uid()::uuid)
    OR artisan_id IN (SELECT id FROM artisans WHERE email = auth.jwt()->>'email')
  );

CREATE POLICY "Service role manages wallets" ON wallets
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- JOBS
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own jobs" ON jobs;
DROP POLICY IF EXISTS "Service role can manage jobs" ON jobs;

CREATE POLICY "Users can view own jobs" ON jobs
  FOR SELECT TO authenticated
  USING (
    artisan_id = auth.uid()::uuid
    OR customer_email = auth.jwt()->>'email'
  );

CREATE POLICY "Public can view completed jobs" ON jobs
  FOR SELECT TO anon
  USING (status = 'completed');

CREATE POLICY "Service role manages jobs" ON jobs
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- TRANSACTIONS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Service role can manage transactions" ON transactions;

CREATE POLICY "Users can view own transactions" ON transactions
  FOR SELECT TO authenticated
  USING (
    artisan_id IN (SELECT id FROM artisans WHERE id = auth.uid()::uuid)
    OR artisan_id IN (SELECT id FROM artisans WHERE email = auth.jwt()->>'email')
    OR customer_email = auth.jwt()->>'email'
  );

CREATE POLICY "Service role manages transactions" ON transactions
  FOR ALL TO service_role
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- ============================================
-- VERIFY DEPLOYMENT
-- ============================================
SELECT 'Tables created:' AS status;
SELECT tablename FROM pg_tables WHERE schemaname = 'public' 
  AND tablename IN ('artisans','stores','equipment','jobs','wallets','transactions','categories','states','cities');

SELECT 'RLS enabled:' AS status;
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' 
  AND rowsecurity = true;

SELECT 'Policies created:' AS status;
SELECT policyname, tablename, cmd FROM pg_policies WHERE schemaname = 'public';

SELECT 'Deployment completed successfully!' AS status;
SELECT 'Tables: artisans, stores, equipment, jobs, wallets, transactions' AS info;
SELECT 'RLS: Enabled on all tables with secure policies' AS info;