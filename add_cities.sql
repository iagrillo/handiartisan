-- Add cities to the cities table
INSERT INTO cities (state_id, name) 
SELECT s.id, city_name FROM states s,
(VALUES
    ('Lagos', ARRAY['Lagos', 'Ikeja', 'Lekki', 'Victoria Island', 'Apapa', 'Yaba', 'Surulere', 'Abeokuta', 'Ojo', 'Ikorodu']),
    ('Ogun', ARRAY['Abeokuta', 'Sagamu', 'Ota', 'Ibara', 'Ijebu Ode', 'Mowe', 'Aiyegunle']),
    ('Oyo', ARRAY['Ibadan', 'Oyo', 'Iseyin', 'Ogbomoso', 'Eruwa', 'Igboora']),
    ('Osun', ARRAY['Osogbo', 'Ilesa', 'Ile-Ife', 'Ikirun', 'Ila', 'Ede']),
    ('Ondo', ARRAY['Akure', 'Ondo', 'Owo', 'Ore', 'Ikare']),
    ('Edo', ARRAY['Benin City', 'Ekpoma', 'Auchi', 'Okene', 'Irrua']),
    ('Delta', ARRAY['Asaba', 'Warri', 'Abraka', 'Sapele', 'Ozoro']),
    ('Rivers', ARRAY['Port Harcourt', 'Obigbo', 'Okrika', 'Bori', 'Omoku']),
    ('Akwa Ibom', ARRAY['Uyo', 'Ikot Ekpene', 'Eket', 'Oron']),
    ('Anambra', ARRAY['Awka', 'Onitsha', 'Nnewi', 'Ihiala']),
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
