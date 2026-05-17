-- Drop existing tables if they exist (run this first)
DROP TABLE IF EXISTS cities CASCADE;
DROP TABLE IF EXISTS stores CASCADE;
DROP TABLE IF EXISTS equipment CASCADE;
DROP TABLE IF EXISTS artisans CASCADE;
DROP TABLE IF EXISTS states CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- Now create tables fresh

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL
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
('glasssmith','Glasssmith'),
('furniture','Furniture Maker'),
('other','Other');

CREATE TABLE states (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO states (name) VALUES 
('Abia'),('Adamawa'),('Akwa Ibom'),('Anambra'),('Bauchi'),('Bayelsa'),('Benue'),('Borno'),('Cross River'),('Delta'),
('Ebonyi'),('Edo'),('Ekiti'),('Enugu'),('Gombe'),('Imo'),('Jigawa'),('Kaduna'),('Kano'),('Katsina'),
('Kebbi'),('Kogi'),('Kwara'),('Lagos'),('Nasarawa'),('Niger'),('Ogun'),('Ondo'),('Osun'),('Oyo'),
('Plateau'),('Sokoto'),('Taraba'),('Yobe'),('Zamfara'),('FCT');

CREATE TABLE cities (
    id SERIAL PRIMARY KEY,
    state_id INTEGER REFERENCES states(id),
    name VARCHAR(100)
);

CREATE TABLE artisans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(150),
    category VARCHAR(100),
    category_id INTEGER REFERENCES categories(id),
    state VARCHAR(100),
    city VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    bio TEXT,
    address TEXT,
    profile_image_url TEXT
);

CREATE TABLE stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    address TEXT,
    contact VARCHAR(100),
    category VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),
    status VARCHAR(20) DEFAULT 'approved'
);

CREATE TABLE equipment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    specs TEXT,
    price VARCHAR(100),
    category VARCHAR(100),
    type VARCHAR(50),
    state VARCHAR(100),
    city VARCHAR(100),
    status VARCHAR(20) DEFAULT 'approved'
);
