#!/usr/bin/env python3
"""
Nigerian Business Directory Data Fetcher
Fetches businesses from Nigerian business directories and generates SQL insert statements.
"""

import requests
import json
import re
from datetime import datetime
import uuid

# ==================== CONFIGURATION ====================
# Supabase configuration
SUPABASE_URL = 'https://awbqkptzknhlvxfboklf.supabase.co'
SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnFrcHR6a25obHZ4ZmJva2xmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1ODQyMDEsImV4cCI6MjA4NTE2MDIwMX0.eyH9HAXyhDguzRVz9urxDviD7fBZ6azOsSh8K03PVeU'

# ==================== CATEGORY MAPPING ====================
# Map external categories to HandiHub categories
CATEGORY_MAPPING = {
    # Groceries
    'grocery': 'Groceries',
    'supermarket': 'Groceries',
    'mini mart': 'Groceries',
    ' provision': 'Groceries',
    
    # Farm Produce
    'farm produce': 'Farm Produce',
    'agriculture': 'Farm Produce',
    'farming': 'Farm Produce',
    'agro': 'Farm Produce',
    
    # Building Materials
    'building materials': 'Building Materials',
    'cement': 'Building Materials',
    'blocks': 'Building Materials',
    'sand': 'Building Materials',
    
    # Electronics
    'electronics': 'Electronics',
    'phones': 'Electronics',
    'computers': 'Electronics',
    'laptops': 'Electronics',
    'gadgets': 'Electronics',
    
    # Fashion & Clothing
    'fashion': 'Fashion & Clothing',
    'clothing': 'Fashion & Clothing',
    'textiles': 'Fashion & Clothing',
    'tailoring': 'Fashion & Clothing',
    'boutique': 'Fashion & Clothing',
    
    # Household Items
    'household': 'Household Items',
    'home appliances': 'Household Items',
    'furniture': 'Household Items',
    
    # Beverages
    'beverages': 'Beverages',
    'drinks': 'Beverages',
    'water': 'Beverages',
    'juice': 'Beverages',
    
    # Cosmetics & Beauty
    'cosmetics': 'Cosmetics & Beauty',
    'beauty': 'Cosmetics & Beauty',
    'salon': 'Cosmetics & Beauty',
    'makeup': 'Cosmetics & Beauty',
    
    # Pharmaceuticals
    'pharmacy': 'Pharmaceuticals',
    'pharmaceutical': 'Pharmaceuticals',
    'medicine': 'Pharmaceuticals',
    'drug store': 'Pharmaceuticals',
    
    # Stationery
    'stationery': 'Stationery',
    'books': 'Stationery',
    'office supplies': 'Stationery',
    
    # Hardware Tools
    'hardware': 'Hardware Tools',
    'tools': 'Hardware Tools',
    'paint': 'Hardware Tools',
    
    # General Merchandise
    'general merchandise': 'General Merchandise',
    'variety store': 'General Merchandise',
    'department store': 'General Merchandise',
}

# ==================== STATE MAPPING ====================
STATE_MAPPING = {
    'lagos': 'Lagos',
    'abuja': 'Abuja',
    'fct': 'Abuja',
    'oyo': 'Oyo',
    'oyo state': 'Oyo',
    'rivers': 'Rivers',
    'port harcourt': 'Rivers',
    'kano': 'Kano',
    'kano state': 'Kano',
    'edo': 'Edo',
    'benin': 'Edo',
    'benin city': 'Edo',
    'enugu': 'Enugu',
    'delta': 'Delta',
    'warri': 'Delta',
    'ogun': 'Ogun',
    'abeokuta': 'Ogun',
    'kaduna': 'Kaduna',
    'plateau': 'Plateau',
    'jos': 'Plateau',
    'oyo': 'Oyo',
    'ibadan': 'Oyo',
    'akwa ibom': 'Akwa Ibom',
    'uyo': 'Akwa Ibom',
    'anambra': 'Anambra',
    'awka': 'Anambra',
    'nnewi': 'Anambra',
    'abia': 'Abia',
    'uyo': 'Abia',
    'IMO': 'Imo',
    'owerri': 'Imo',
    'ondo': 'Ondo',
    'akure': 'Ondo',
    'ekiti': 'Ekiti',
    'enugu': 'Enugu',
    'gombe': 'Gombe',
    'imo': 'Imo',
    'jigawa': 'Jigawa',
    'kaduna': 'Kaduna',
    'katsina': 'Katsina',
    'kebbi': 'Kebbi',
    'kogi': 'Kogi',
    'kwara': 'Kwara',
    'nasarawa': 'Nasarawa',
    'niger': 'Niger',
    'plateau': 'Plateau',
    'sokoto': 'Sokoto',
    'taraba': 'Taraba',
    'yobe': 'Yobe',
    'zamfara': 'Zamfara',
}

CITY_MAPPING = {
    # Lagos
    'ikeja': 'Ikeja',
    'lekki': 'Lekki',
    'victoria island': 'Victoria Island',
    'vi': 'Victoria Island',
    'lagos island': 'Lagos Island',
    'apapa': 'Apapa',
    'yaba': 'Yaba',
    'surulere': 'Surulere',
    'oshodi': 'Oshodi',
    'mushin': 'Mushin',
    'ikoyi': 'Ikoyi',
    'ajah': 'Ajah',
    'badagry': 'Badagry',
    'epe': 'Epe',
    'ibadan': 'Ibadan',
    
    # Abuja
    'gwagwalada': 'Gwagwalada',
    'kuje': 'Kuje',
    'bwari': 'Bwari',
    'kubwa': 'Kubwa',
    'lugi': 'Lugi',
    
    # Other major cities
    'port harcourt': 'Port Harcourt',
    'benin city': 'Benin City',
    'kano': 'Kano',
    'kaduna': 'Kaduna',
    'jos': 'Jos',
    'owerri': 'Owerri',
    'enugu': 'Enugu',
    'akure': 'Akure',
    'abuja': 'Abuja',
    'ife': 'Ile-Ife',
    'abeokuta': 'Abeokuta',
    'warri': 'Warri',
}


def clean_phone(phone):
    """Clean and normalize phone number to +234 format"""
    if not phone:
        return ''
    
    # Remove all non-digit characters
    phone = re.sub(r'\D', '', phone)
    
    # Ensure it starts with country code
    if phone.startswith('0'):
        phone = '234' + phone[1:]
    elif not phone.startswith('234'):
        phone = '234' + phone
    
    # Add + prefix for display
    return '+' + phone


# ==================== MAIN PROCESSING ====================
def process_businesses(businesses):
    """Process and normalize business data"""
    processed = []
    seen = set()  # For deduplication
    
    for biz in businesses:
        # Extract fields (adjust based on API response structure)
        name = biz.get('name') or biz.get('business_name') or biz.get('title', '')
        category = biz.get('category') or biz.get('category_name') or ''
        city = biz.get('city') or biz.get('location') or ''
        state = biz.get('state') or ''
        phone = biz.get('phone') or biz.get('phone_number') or ''
        website = biz.get('website') or biz.get('url') or ''
        address = biz.get('address') or biz.get('full_address') or ''
        
        # Normalize
        category = normalize_category(category)
        state = normalize_state(state)
        city = normalize_city(city, state)
        phone = clean_phone(phone)
        
        # Create unique key for deduplication
        key = (name.lower().strip(), city.lower().strip(), state.lower().strip())
        
        if key in seen:
            continue
        
        seen.add(key)
        
        processed.append({
            'store_id': str(uuid.uuid4()),
            'name': name.strip(),
            'category': category,
            'city': city,
            'state': state,
            'phone': phone,
            'website': website.strip() if website else '',
            'address': address.strip() if address else '',
        })
    
    return processed


def normalize_category(category):
    """Map external category to HandiHub category"""
    if not category:
        return 'General Merchandise'
    
    category_lower = category.lower().strip()
    
    for key, value in CATEGORY_MAPPING.items():
        if key in category_lower:
            return value
    
    return 'General Merchandise'


def normalize_state(state):
    """Normalize state name"""
    if not state:
        return 'Lagos'  # Default
    
    state_lower = state.lower().strip()
    return STATE_MAPPING.get(state_lower, state.title())


def normalize_city(city, state):
    """Normalize city name"""
    if not city:
        return 'Ikeja'  # Default
    
    city_lower = city.lower().strip()
    
    # First check direct mapping
    if city_lower in CITY_MAPPING:
        return CITY_MAPPING[city_lower]
    
    # Title case
    return city.title()


def generate_sql_inserts(businesses):
    """Generate SQL INSERT statements - matching actual stores table schema"""
    sql_statements = []
    
    for biz in businesses:
        # Escape single quotes in strings
        name = biz['name'].replace("'", "''")
        category = biz['category'].replace("'", "''")
        city = biz['city'].replace("'", "''")
        state = biz['state'].replace("'", "''")
        address = biz['address'].replace("'", "''") if biz['address'] else ''
        
        # Build description with phone and website info (no emojis for SQL compatibility)
        phone = biz['phone'].replace("'", "''") if biz['phone'] else ''
        website = biz['website'].replace("'", "''") if biz['website'] else ''
        
        # Create description with contact info
        description_parts = []
        if phone:
            description_parts.append(f"Phone: {phone}")
        if website:
            description_parts.append(f"Website: {website}")
        
        description = " - " + " | ".join(description_parts) if description_parts else ""
        
        # Format address as SQL string
        address_sql = f"'{address}'" if address else 'NULL'
        description_sql = f"'{description}'" if description else 'NULL'
        
        sql = f"""INSERT INTO stores (id, name, category, city, state, address, description, status, created_at)
VALUES ('{biz['store_id']}', '{name}', '{category}', '{city}', '{state}', {address_sql}, {description_sql}, 'approved', NOW());"""
        
        sql_statements.append(sql)
    
    return sql_statements


def generate_sample_data():
    """
    Generate sample Nigerian businesses for demonstration.
    Replace this with actual API data.
    """
    return [
        # Lagos Stores
        {
            'name': 'Eze Supermarket',
            'category': 'Supermarket',
            'city': 'Ikeja',
            'state': 'Lagos',
            'phone': '08012345678',
            'website': 'www.ezesupermart.com',
            'address': '12 Allen Avenue, Ikeja'
        },
        {
            'name': 'Lagos Electronics Store',
            'category': 'Electronics',
            'city': 'Ikeja',
            'state': 'Lagos',
            'phone': '07012345678',
            'website': 'www.lagoselectronic.com',
            'address': 'Computer Village, Ikeja'
        },
        {
            'name': 'Fashion Hub Nigeria',
            'category': 'Fashion',
            'city': 'Lagos Island',
            'state': 'Lagos',
            'phone': '08023456789',
            'website': 'www.fashionhubnigeria.com',
            'address': 'Balogun Plaza, Lagos Island'
        },
        {
            'name': 'Fresh Farm Produce',
            'category': 'Agriculture',
            'city': 'Oshodi',
            'state': 'Lagos',
            'phone': '08034567890',
            'website': 'www.freshfarmproduce.com',
            'address': 'Agric Market, Oshodi'
        },
        {
            'name': 'PharmaCare Pharmacy',
            'category': 'Pharmacy',
            'city': 'Surulere',
            'state': 'Lagos',
            'phone': '08045678901',
            'website': 'www.pharmacare.com.ng',
            'address': 'Adeniran Ogunsanya, Surulere'
        },
        {
            'name': 'BuildRight Hardware',
            'category': 'Hardware',
            'city': 'Apapa',
            'state': 'Lagos',
            'phone': '08056789012',
            'website': 'www.buildrighthardware.com',
            'address': 'Warehouse Road, Apapa'
        },
        {
            'name': 'Beverage World',
            'category': 'Beverages',
            'city': 'Yaba',
            'state': 'Lagos',
            'phone': '08067890123',
            'website': 'www.beverageworld.com.ng',
            'address': 'Herbert Macaulay, Yaba'
        },
        {
            'name': 'Beauty Palace',
            'category': 'Cosmetics',
            'city': 'Ikoyi',
            'state': 'Lagos',
            'phone': '08078901234',
            'website': 'www.beautypalace.com.ng',
            'address': 'Awolowo Road, Ikoyi'
        },
        
        # Abuja Stores
        {
            'name': 'Abuja Farm Produce Ltd',
            'category': 'Agriculture',
            'city': 'Gwarinpa',
            'state': 'Abuja',
            'phone': '08098765432',
            'website': 'www.abujafarm.com',
            'address': 'Estate Road, Gwarinpa'
        },
        {
            'name': 'Central Hardware',
            'category': 'Hardware',
            'city': 'Wuse',
            'state': 'Abuja',
            'phone': '07098765432',
            'website': 'www.centralhardware.abj',
            'address': 'Wuse Market, Abuja'
        },
        {
            'name': 'Abuja Electronics Hub',
            'category': 'Electronics',
            'city': 'Gwagwalada',
            'state': 'Abuja',
            'phone': '08011112222',
            'website': 'www.abjelectronics.com',
            'address': 'Zone 5, Gwagwalada'
        },
        
        # Other States
        {
            'name': 'Ibadan Supermarket',
            'category': 'Supermarket',
            'city': 'Ibadan',
            'state': 'Oyo',
            'phone': '08022223333',
            'website': 'www.ibadansupermarket.com',
            'address': 'Ring Road, Ibadan'
        },
        {
            'name': 'Port Harcourt Grocers',
            'category': 'Groceries',
            'city': 'Port Harcourt',
            'state': 'Rivers',
            'phone': '08033334444',
            'website': 'www.phgrocers.com',
            'address': 'Aba Road, Port Harcourt'
        },
        {
            'name': 'Kano Textiles',
            'category': 'Fashion',
            'city': 'Kano',
            'state': 'Kano',
            'phone': '08044445555',
            'website': 'www.kanotextiles.com',
            'address': 'Kano Market'
        },
        {
            'name': 'Benin Building Materials',
            'category': 'Building Materials',
            'city': 'Benin City',
            'state': 'Edo',
            'phone': '08055556666',
            'website': 'www.beninbuilding.com',
            'address': 'Akpakpava Road, Benin City'
        },
        {
            'name': 'Enugu Stationery House',
            'category': 'Stationery',
            'city': 'Enugu',
            'state': 'Enugu',
            'phone': '08066667777',
            'website': 'www.enugustationery.com',
            'address': 'Obianoz Anyim, Enugu'
        },
        {
            'name': 'Warri Cosmetics Centre',
            'category': 'Cosmetics',
            'city': 'Warri',
            'state': 'Delta',
            'phone': '08077778888',
            'website': 'www.warricosmetics.com',
            'address': 'Effurun, Warri'
        },
        {
            'name': 'Abeokuta Farm Supplies',
            'category': 'Agriculture',
            'city': 'Abeokuta',
            'state': 'Ogun',
            'phone': '08088889999',
            'website': 'www.abeokutafarms.com',
            'address': 'Oke-Oke Road, Abeokuta'
        },
        {
            'name': 'Kaduna General Merchandise',
            'category': 'General Merchandise',
            'city': 'Kaduna',
            'state': 'Kaduna',
            'phone': '08099990000',
            'website': 'www.kadunamerchandise.com',
            'address': 'Kaduna Central Market'
        },
        {
            'name': 'Jos Pharmaceutical Store',
            'category': 'Pharmacy',
            'city': 'Jos',
            'state': 'Plateau',
            'phone': '08100001111',
            'website': 'www.jospharmacy.com',
            'address': 'Bukuru Road, Jos'
        },
    ]


def insert_to_supabase(businesses):
    """Insert businesses directly to Supabase"""
    import requests
    
    success_count = 0
    error_count = 0
    
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
    }
    
    for biz in businesses:
        # Build description with phone and website info (no emojis)
        description_parts = []
        if biz['phone']:
            description_parts.append(f"Phone: {biz['phone']}")
        if biz['website']:
            description_parts.append(f"Website: {biz['website']}")
        
        description = " - " + " | ".join(description_parts) if description_parts else None
        
        payload = {
            'id': biz['store_id'],
            'name': biz['name'],
            'category': biz['category'],
            'city': biz['city'],
            'state': biz['state'],
            'address': biz['address'] if biz['address'] else None,
            'description': description,
            'status': 'approved',
        }
        
        url = f"{SUPABASE_URL}/rest/v1/stores"
        
        try:
            response = requests.post(url, json=payload, headers=headers)
            
            if response.status_code in [200, 201]:
                success_count += 1
                print(f"Inserted: {biz['name']}")
            else:
                error_count += 1
                print(f"Error inserting {biz['name']}: {response.text}")
        except Exception as e:
            error_count += 1
            print(f"Error inserting {biz['name']}: {str(e)}")
    
    print(f"\nSuccess: {success_count}, Errors: {error_count}")
    return success_count, error_count


def main():
    print("=" * 60)
    print("Nigerian Business Directory Data Fetcher")
    print("=" * 60)
    
    # Get businesses (using sample data for now)
    print("\nUsing sample data for demonstration...")
    businesses = generate_sample_data()
    print(f"Fetched {len(businesses)} businesses")
    
    # Process and normalize
    print("\nProcessing and normalizing data...")
    processed = process_businesses(businesses)
    print(f"Processed {len(processed)} unique businesses")
    
    # Generate SQL
    print("\nGenerating SQL INSERT statements...")
    sql_statements = generate_sql_inserts(processed)
    
    # Save SQL to file
    sql_file = 'stores_insert_statements.sql'
    with open(sql_file, 'w') as f:
        f.write(f"-- Generated on {datetime.now()}\n")
        f.write(f"-- Total records: {len(sql_statements)}\n\n")
        f.write("\n".join(sql_statements))
        f.write("\n")
    
    print(f"\nSQL statements saved to: {sql_file}")
    
    # Try to insert directly to Supabase
    print("\n" + "=" * 60)
    print("Attempting to insert directly to Supabase...")
    print("=" * 60)
    
    success, errors = insert_to_supabase(processed)
    
    # Show sample output
    print("\n" + "=" * 60)
    print("SAMPLE OUTPUT:")
    print("=" * 60)
    for sql in sql_statements[:3]:
        print(sql)
        print()


if __name__ == '__main__':
    main()
