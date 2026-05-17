-- Copy and run this in Supabase SQL Editor

-- 1. CREATE CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(255)
);

-- 2. INSERT CATEGORIES
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

-- 3. CREATE STATES TABLE
CREATE TABLE IF NOT EXISTS states (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- 4. INSERT STATES
INSERT INTO states (name) VALUES 
('Abia'),('Adamawa'),('Akwa Ibom'),('Anambra'),('Bauchi'),('Bayelsa'),('Benue'),('Borno'),('Cross River'),('Delta'),
('Ebonyi'),('Edo'),('Ekiti'),('Enugu'),('Gombe'),('Imo'),('Jigawa'),('Kaduna'),('Kano'),('Katsina'),
('Kebbi'),('Kogi'),('Kwara'),('Lagos'),('Nasarawa'),('Niger'),('Ogun'),('Ondo'),('Osun'),('Oyo'),
('Plateau'),('Sokoto'),('Taraba'),('Yobe'),('Zamfara'),('FCT')
ON CONFLICT (name) DO NOTHING;

-- 5. CREATE CITIES TABLE
CREATE TABLE IF NOT EXISTS cities (
    id SERIAL PRIMARY KEY,
    state_id INTEGER REFERENCES states(id),
    name VARCHAR(100) NOT NULL
);

-- 6. CREATE ARTISANS TABLE
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

-- 7. CREATE STORES TABLE
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

-- 8. CREATE EQUIPMENT TABLE
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

-- 9. ENABLE SECURITY (optional - for production)
ALTER TABLE artisans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_view_artisans" ON artisans FOR SELECT USING (status = 'active');

-- DONE!
