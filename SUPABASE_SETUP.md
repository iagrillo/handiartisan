# Supabase Setup Guide

This document outlines how to set up the Supabase backend for the HandiHub Artisan app.

## Prerequisites

1. A Supabase project at https://supabase.com
2. Your Supabase URL and anon key (already configured in `main.dart`)

## Database Setup

### Step 1: Run the SQL Schema

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of `supabase_schema.sql`
4. Run the SQL script

This will create:
- `categories` - Artisan skill categories
- `states` - Nigerian states
- `cities` - Nigerian cities
- `artisans` - Artisan profiles
- `stores` - Store listings
- `equipment` - Equipment listings
- Storage buckets for images

### Step 2: Verify Tables

After running the SQL, verify these tables exist:
- categories (should have 13 rows)
- states (should have 36 rows)
- cities (should have multiple cities)
- artisans
- stores
- equipment

### Step 3: Test the App

Run the Flutter app:
```bash
cd handiartisan
flutter pub get
flutter run
```

## Features Connected

### Artisan Profile Submission
- Form fetches categories from Supabase
- Form fetches states/cities from Supabase
- Submits to `artisans` table with status='active'

### Store Listings
- Form fetches states/cities from Supabase
- Submits to `stores` table with status='approved'
- Provider fetches and filters stores

### Equipment Listings
- Form fetches states/cities from Supabase
- Submits to `equipment` table with status='approved'
- Service fetches approved equipment with filters

## Supabase Configuration

The app is already configured in `main.dart`:
- URL: `https://awbqkptzknhlvxfboklf.supabase.co`
- Key: (configured in main.dart)

## Data Flow

```
App Forms → Supabase Tables → App Providers → UI
```

### Column Mappings

**Artisans Table:**
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| full_name | VARCHAR | Artisan's full name |
| business_name | VARCHAR | Business name (optional) |
| phone | VARCHAR | Contact phone |
| email | VARCHAR | Email address |
| category | VARCHAR | Category name |
| category_id | INTEGER | FK to categories |
| state | VARCHAR | State |
| city | VARCHAR | City |
| status | VARCHAR | 'active' or 'inactive' |
| is_available | BOOLEAN | Availability |
| profile_image_url | TEXT | Profile image URL |
| rating | DECIMAL | Rating score |

**Stores Table:**
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| name | VARCHAR | Store name |
| description | TEXT | Description |
| address | TEXT | Address |
| contact | VARCHAR | Contact info |
| category | VARCHAR | Category |
| state | VARCHAR | State |
| city | VARCHAR | City |
| status | VARCHAR | 'approved' or 'pending' |

**Equipment Table:**
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key |
| name | VARCHAR | Equipment name |
| description | TEXT | Description |
| specs | TEXT | Specifications |
| price | VARCHAR | Price/rate |
| category | VARCHAR | Category |
| type | VARCHAR | Sale/Rental/Servicing/Parts |
| state | VARCHAR | State |
| city | VARCHAR | City |
| status | VARCHAR | 'approved' or 'pending' |

## Troubleshooting

If you encounter issues:

1. **Tables not found**: Run the SQL schema again
2. **No data showing**: Check Row Level Security policies
3. **Insert errors**: Verify column names match the schema
4. **Category dropdown empty**: Check categories table has data

## Notes

- The app uses Row Level Security (RLS) policies
- Public can view active/approved items only
- Authenticated users can insert new items
- Storage buckets are set up for images
