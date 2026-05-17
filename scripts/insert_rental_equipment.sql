-- ============================================
-- INSERT RENTAL EQUIPMENT - Run in Supabase SQL Editor
-- ============================================

INSERT INTO equipment (name, description, specs, price, category, type, state, city, status, created_at)
VALUES 
('Tower Crane Rental', 'Tower crane for high-rise construction', '50m reach, 5 ton lift', 'N500,000/day', 'Construction', 'Rental', 'Lagos', 'Victoria Island', 'approved', NOW()),
('Concrete Pump Rental', 'Mobile concrete pump for construction', '40m boom, 100cbm/hr', 'N200,000/day', 'Construction', 'Rental', 'Abuja', 'Gwagwalada', 'approved', NOW()),
('Excavator Rental', 'CAT excavator 20 ton for heavy duty work', '20 ton, 150HP engine', 'N350,000/day', 'Heavy Equipment', 'Rental', 'Lagos', 'Apapa', 'approved', NOW()),
('Generator 100KVA Rental', 'Diesel generator for events and construction', '100KVA, silent type', 'N50,000/day', 'Power Equipment', 'Rental', 'Oyo', 'Ibadan', 'approved', NOW()),
('Welding Machine Rental', 'Industrial welding machine for fabrication', '300A inverter welder', 'N5,000/day', 'Tools & Equipment', 'Rental', 'Kano', 'Kano', 'approved', NOW()),
('Jackhammer Rental', 'Pneumatic jackhammer for demolition', '30kg heavy duty', 'N3,000/day', 'Tools & Equipment', 'Rental', 'Delta', 'Warri', 'approved', NOW()),
('Concrete Mixer Rental', 'Industrial concrete mixer', '500L capacity', 'N8,000/day', 'Construction', 'Rental', 'Rivers', 'Port Harcourt', 'approved', NOW()),
('Crane Truck Rental', 'Mobile crane for lifting', '10 ton capacity', 'N250,000/day', 'Construction', 'Rental', 'Enugu', 'Enugu', 'approved', NOW());

-- Then check what was inserted:
SELECT * FROM equipment WHERE type = 'Rental';
