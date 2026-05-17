-- ============================================
-- Sample Equipment Data - Run in Supabase SQL Editor
-- ============================================

INSERT INTO equipment (name, description, specs, price, category, type, state, city, status, created_at)
VALUES 
('Concrete Pump 50M', 'High-quality concrete pump for construction projects', '50m boom, 120cbm/hr capacity', '₦15,000,000', 'Construction Equipment', 'Sale', 'Lagos', 'Ikeja', 'approved', NOW()),
('Mobile Batching Plant', 'Mobile batching plant for on-site concrete production', '60cbm/hr capacity, diesel powered', '₦25,000,000', 'Construction Equipment', 'Rental', 'Abuja', 'Gwagwalada', 'approved', NOW()),
('Excavator CAT 320', 'Heavy duty excavator for construction', '20 ton, 150HP engine', '₦45,000,000', 'Heavy Equipment', 'Rental', 'Lagos', 'Apapa', 'approved', NOW()),
('Crane Tower', 'Tower crane for high-rise building construction', '50m reach, 5 ton lift capacity', '₦35,000,000', 'Construction Equipment', 'Rental', 'Lagos', 'Victoria Island', 'approved', NOW()),
('Concrete Mixer', 'Industrial concrete mixer', '500L capacity, electric motor', '₦2,500,000', 'Construction Equipment', 'Sale', 'Oyo', 'Ibadan', 'approved', NOW()),
('Generator 100KVA', 'Industrial generator for construction sites', '100KVA, diesel powered', '₦8,500,000', 'Power Equipment', 'Sale', 'Rivers', 'Port Harcourt', 'approved', NOW()),
('Welding Machine', 'Industrial welding machine', '300A, inverter type', '₦450,000', 'Tools & Equipment', 'Sale', 'Kano', 'Kano', 'approved', NOW()),
('Jackhammer', 'Pneumatic jackhammer for demolition', '30kg class, heavy duty', '₦180,000', 'Tools & Equipment', 'Rental', 'Delta', 'Warri', 'approved', NOW());
