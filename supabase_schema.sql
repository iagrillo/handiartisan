-- ============================================
-- HandiHub Artisan App - Database Schema
-- Run this SQL in Supabase SQL Editor
-- ============================================

-- ============================================
-- CATEGORIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories for artisans
INSERT INTO categories (slug, name, icon) VALUES
    ('carpenter', 'Carpenter', 'carpenter_icon'),
    ('plumber', 'Plumber', 'plumber_icon'),
    ('electrician', 'Electrician', 'electrician_icon'),
    ('welder', 'Welder', 'welder_icon'),
    ('painter', 'Painter', 'painter_icon'),
    ('mason', 'Mason', 'mason_icon'),
    ('tailor', 'Tailor', 'tailor_icon'),
    ('mechanic', 'Mechanic', 'mechanic_icon'),
    ('tiler', 'Tiler', 'tiler_icon'),
    ('roofer', 'Roofer', 'roofer_icon'),
    ('glassmith', 'Glassmith', 'glassmith_icon'),
    ('furniture', 'Furniture Maker', 'furniture_icon'),
    ('other', 'Other', 'other_icon')
ON CONFLICT (slug) DO NOTHING;

-- ============================================
-- STATES TABLE (Nigeria)
-- ============================================
CREATE TABLE IF NOT EXISTS states (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert Nigerian states
INSERT INTO states (name) VALUES
    ('Abia'), ('Adamawa'), ('Akwa Ibom'), ('Anambra'), ('Bauchi'),
    ('Bayelsa'), ('Benue'), ('Borno'), ('Cross River'), ('Delta'),
    ('Ebonyi'), ('Edo'), ('Ekiti'), ('Enugu'), ('Gombe'),
    ('Imo'), ('Jigawa'), ('Kaduna'), ('Kano'), ('Katsina'),
    ('Kebbi'), ('Kogi'), ('Kwara'), ('Lagos'), ('Nasarawa'),
    ('Niger'), ('Ogun'), ('Ondo'), ('Osun'), ('Oyo'),
    ('Plateau'), ('Sokoto'), ('Taraba'), ('Yobe'), ('Zamfara'),
    ('FCT')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- CITIES TABLE (Nigeria)
-- ============================================
CREATE TABLE IF NOT EXISTS cities (
    id SERIAL PRIMARY KEY,
    state_id INTEGER REFERENCES states(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(state_id, name)
);

-- Insert major Nigerian cities
INSERT INTO cities (state_id, name) 
SELECT s.id, city_name FROM states s,
(VALUES
    ('Lagos', ARRAY['Lagos', 'Ikeja', ' Lekki', 'Victoria Island', 'Apapa', 'Yaba', 'Surulere', 'Abeokuta', 'Ojo', 'Ikorodu']),
    ('Ogun', ARRAY['Abeokuta', 'Sagamu', 'Ota', 'Ibara', 'Ijebu Ode', 'Mowe', 'Aiyegunle']),
    ('Oyo', ARRAY['Ibadan', 'Oyo', 'Iseyin', 'Ogbomoso', 'Eruwa', 'Igboora']),
    ('Osun', ARRAY['Osogbo', 'Ilesa', 'Ile-Ife', 'Ikirun', 'Ila', 'Ede']),
    ('Ondo', ARRAY['Akure', 'Ondo', 'Owo', 'Ore', 'Ikare']),
    ('Edo', ARRAY['Benin City', 'Ekpoma', 'Auchi', 'Okene', 'Irrua']),
    ('Delta', ARRAY['Asaba', 'Warri', 'Abraka', 'Sapele', ' Oleh', 'Ozoro']),
    ('Rivers', ARRAY['Port Harcourt', 'Obigbo', 'Okrika', 'Bori', 'Omoku']),
    ('Akwa Ibom', ARRAY['Uyo', 'Ikot Ekpene', 'Eket', 'Oron']),
    ('Anambra', ARRAY['Awka', 'Onitsha', 'Nnewi', 'Awgba', ' Ihiala']),
    ('Enugu', ARRAY['Enugu', 'Nsukka', 'Awgu', 'Udi', 'Oji River']),
    ('Imo', ARRAY['Owerri', 'Orlu', 'Okigwe', 'Mbaaise', 'Oguta']),
    ('Abuja', ARRAY['Abuja', 'Gwagwalada', 'Kuje', 'Bwari', 'Zuba']),
    ('Kano', ARRAY['Kano', 'Wudil', 'Gwarzo', 'Rano', 'Bichi']),
    ('Kaduna', ARRAY['Kaduna', 'Zaria', 'Kafia', 'Birnin Gwari', 'Saminaka']),
    ('Katsina', ARRAY['Katsina', 'Daura', 'Funtua', 'Kankia', 'Kusada']),
    ('Borno', ARRAY['Maiduguri', 'Biu', 'Gwoza', 'Dikwa', 'Bama']),
    ('Yobe', ARRAY['Damaturu', 'Potiskum', 'Gashua', 'Nguru', 'Bari']),
    ('Plateau', ARRAY['Jos', 'Bukuru', 'Pankshin', 'Shendam', 'Langtang']),
    ('Niger', ARRAY['Minna', 'Bida', 'Kontagora', 'Suleja', 'Tegina']),
    ('Kwara', ARRAY['Ilorin', 'Offa', 'Okene', 'Omu Aran', 'Jebba'])
) AS cities(state, cities)
WHERE s.name = state;

-- ============================================
-- ARTISANS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS artisans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
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
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    profile_image_url TEXT,
    gallery_image_urls JSONB,
    is_featured BOOLEAN DEFAULT false,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    tradetype VARCHAR(50),
    password VARCHAR(255),
    show_distance BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE artisans ENABLE ROW LEVEL SECURITY;

-- Create policy for public read access
CREATE POLICY "Public can view artisans" ON artisans
    FOR SELECT USING (status = 'active');

-- Create policy for authenticated users to insert
CREATE POLICY "Authenticated users can insert artisans" ON artisans
    FOR INSERT WITH CHECK (true);

-- Create policy for owners to update their profile
CREATE POLICY "Owners can update own artisans" ON artisans
    FOR UPDATE USING (true);

-- ============================================
-- STORES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS stores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    address TEXT,
    contact VARCHAR(100),
    category VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),
    logo_url TEXT,
    ai_description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    is_featured BOOLEAN DEFAULT false,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

-- Create policy for public read access (approved stores only)
CREATE POLICY "Public can view approved stores" ON stores
    FOR SELECT USING (status = 'approved');

-- Create policy for authenticated users to insert
CREATE POLICY "Authenticated users can insert stores" ON stores
    FOR INSERT WITH CHECK (true);

-- ============================================
-- EQUIPMENT TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS equipment (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    specs TEXT,
    price VARCHAR(100),
    category VARCHAR(100),
    type VARCHAR(50), -- Sale, Rental, Servicing, Parts
    state VARCHAR(100),
    city VARCHAR(100),
    image_urls JSONB,
    ai_description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    is_featured BOOLEAN DEFAULT false,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;

-- Create policy for public read access (approved equipment only)
CREATE POLICY "Public can view approved equipment" ON equipment
    FOR SELECT USING (status = 'approved');

-- Create policy for authenticated users to insert
CREATE POLICY "Authenticated users can insert equipment" ON equipment
    FOR INSERT WITH CHECK (true);

-- ============================================
-- CREATE INDEXES FOR BETTER PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_artisans_category ON artisans(category);
CREATE INDEX IF NOT EXISTS idx_artisans_state ON artisans(state);
CREATE INDEX IF NOT EXISTS idx_artisans_city ON artisans(city);
CREATE INDEX IF NOT EXISTS idx_artisans_status ON artisans(status);
CREATE INDEX IF NOT EXISTS idx_artisans_is_featured ON artisans(is_featured);

CREATE INDEX IF NOT EXISTS idx_stores_category ON stores(category);
CREATE INDEX IF NOT EXISTS idx_stores_state ON stores(state);
CREATE INDEX IF NOT EXISTS idx_stores_city ON stores(city);
CREATE INDEX IF NOT EXISTS idx_stores_status ON stores(status);

CREATE INDEX IF NOT EXISTS idx_equipment_category ON equipment(category);
CREATE INDEX IF NOT EXISTS idx_equipment_type ON equipment(type);
CREATE INDEX IF NOT EXISTS idx_equipment_state ON equipment(state);
CREATE INDEX IF NOT EXISTS idx_equipment_status ON equipment(status);

CREATE INDEX IF NOT EXISTS idx_cities_state_id ON cities(state_id);

-- ============================================
-- STORAGE BUCKET FOR IMAGES
-- ============================================
-- Create bucket for profile images
INSERT INTO storage.buckets (id, name, public)
VALUES ('profiles', 'profiles', true)
ON CONFLICT (id) DO NOTHING;

-- Create bucket for store images
INSERT INTO storage.buckets (id, name, public)
VALUES ('stores', 'stores', true)
ON CONFLICT (id) DO NOTHING;

-- Create bucket for equipment images
INSERT INTO storage.buckets (id, name, public)
VALUES ('equipment', 'equipment', true)
ON CONFLICT (id) DO NOTHING;

-- Create bucket for gallery images
INSERT INTO storage.buckets (id, name, public)
VALUES ('gallery', 'gallery', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- STORAGE POLICIES
-- ============================================
-- Profiles bucket policies
CREATE POLICY "Public can view profiles" ON storage.objects
    FOR SELECT USING (bucket_id = 'profiles');

CREATE POLICY "Users can upload profiles" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'profiles' AND auth.role() = 'authenticated');

-- Stores bucket policies
CREATE POLICY "Public can view stores" ON storage.objects
    FOR SELECT USING (bucket_id = 'stores');

CREATE POLICY "Users can upload stores" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'stores' AND auth.role() = 'authenticated');

-- Equipment bucket policies
CREATE POLICY "Public can view equipment" ON storage.objects
    FOR SELECT USING (bucket_id = 'equipment');

CREATE POLICY "Users can upload equipment" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'equipment' AND auth.role() = 'authenticated');

-- Gallery bucket policies
CREATE POLICY "Public can view gallery" ON storage.objects
    FOR SELECT USING (bucket_id = 'gallery');

CREATE POLICY "Users can upload gallery" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'gallery' AND auth.role() = 'authenticated');

-- ============================================
-- PRINT SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Database schema created successfully!';
END $$;
