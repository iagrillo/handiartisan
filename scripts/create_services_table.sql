-- ============================================
-- CREATE SERVICES TABLE FOR SERVICE PROVIDERS
-- Run in Supabase SQL Editor
-- ============================================

-- Create services table
CREATE TABLE IF NOT EXISTS services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    contact_number TEXT NOT NULL,
    email TEXT,
    state TEXT NOT NULL,
    city TEXT NOT NULL,
    address TEXT,
    
    -- Power Tools (stored as JSON array)
    power_tools_drills BOOLEAN DEFAULT FALSE,
    power_tools_grinders BOOLEAN DEFAULT FALSE,
    power_tools_saws BOOLEAN DEFAULT FALSE,
    power_tools_sanders BOOLEAN DEFAULT FALSE,
    power_tools_welding BOOLEAN DEFAULT FALSE,
    power_tools_other TEXT,
    
    -- Heavy Equipment
    heavy_equipment_generators BOOLEAN DEFAULT FALSE,
    heavy_equipment_compressors BOOLEAN DEFAULT FALSE,
    heavy_equipment_excavators BOOLEAN DEFAULT FALSE,
    heavy_equipment_forklifts BOOLEAN DEFAULT FALSE,
    heavy_equipment_bulldozers BOOLEAN DEFAULT FALSE,
    heavy_equipment_other TEXT,
    
    -- Service Type (stored as JSON array)
    service_maintenance BOOLEAN DEFAULT FALSE,
    service_repair BOOLEAN DEFAULT FALSE,
    service_installation BOOLEAN DEFAULT FALSE,
    service_diagnostics BOOLEAN DEFAULT FALSE,
    
    -- Mobility
    mobility TEXT,  -- 'mobile', 'workshop', 'both'
    
    -- Experience & Certifications
    experience_summary TEXT,
    certifications TEXT,
    
    -- Status
    status TEXT DEFAULT 'approved',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (optional - can disable for testing)
ALTER TABLE services ENABLE ROW LEVEL SECURITY;

-- Allow anonymous access for testing
CREATE POLICY "Allow all access to services" ON services
    FOR ALL USING (true) WITH CHECK (true);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_services_state_city ON services(state, city);
CREATE INDEX IF NOT EXISTS idx_services_status ON services(status);
