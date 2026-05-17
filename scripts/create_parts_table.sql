-- ============================================
-- CREATE PARTS TABLE FOR EQUIPMENT PARTS
-- Run in Supabase SQL Editor
-- ============================================

-- Create parts table
CREATE TABLE IF NOT EXISTS parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    sub_category TEXT,
    brand TEXT,
    model TEXT,
    part_number TEXT,
    compatible_with TEXT,
    
    -- Pricing
    price TEXT,
    price_type TEXT, -- 'Firm', 'Negotiable'
    
    -- Location
    state TEXT NOT NULL,
    city TEXT NOT NULL,
    
    -- Contact
    contact_name TEXT,
    contact_phone TEXT NOT NULL,
    email TEXT,
    
    -- Availability
    in_stock BOOLEAN DEFAULT TRUE,
    quantity INTEGER,
    
    -- Status
    status TEXT DEFAULT 'approved',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;

-- Allow anonymous access for testing
CREATE POLICY "Allow all access to parts" ON parts
    FOR ALL USING (true) WITH CHECK (true);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_parts_state_city ON parts(state, city);
CREATE INDEX IF NOT EXISTS idx_parts_category ON parts(category);
CREATE INDEX IF NOT EXISTS idx_parts_status ON parts(status);

-- Insert sample parts data
INSERT INTO parts (name, description, category, sub_category, brand, price, price_type, state, city, contact_phone, in_stock, status) VALUES
('CAT 320 Excavator Bucket', 'High quality excavator bucket for CAT 320', 'Heavy Equipment Parts', 'Attachments', 'CAT', '₦450000', 'Negotiable', 'Lagos', 'Ikeja', '08012345678', true, 'approved'),
('Honda GX200 Engine', 'Original Honda GX200 petrol engine', 'Power Tools Parts', 'Engines', 'Honda', '₦85000', 'Firm', 'Lagos', 'Lekki', '08023456789', true, 'approved'),
('Hydraulic Pump for Concrete Pump', 'High pressure hydraulic pump', 'Heavy Equipment Parts', 'Hydraulics', 'Generic', '₦120000', 'Negotiable', 'Abuja', 'Gwagwalada', '08034567890', true, 'approved'),
('Generator Spare Parts Kit', 'Complete spare parts kit for 10KVA generator', 'Heavy Equipment Parts', 'Electrical', 'Generic', '₦35000', 'Firm', 'Oyo', 'Ibadan', '08045678901', true, 'approved'),
('Welding Rods Box', 'E6013 welding rods, 5kg box', 'Power Tools Parts', 'Consumables', 'Lincoln', '₦8000', 'Firm', 'Rivers', 'Port Harcourt', '08056789012', true, 'approved');
