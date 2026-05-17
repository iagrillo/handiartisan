# OTP Verification Setup Guide

This guide will help you complete the setup for the outcall booking OTP verification system.

## Step 1: Add OTP Columns to Database

1. Go to your **Supabase Dashboard**
2. Navigate to **SQL Editor**
3. Copy and paste the following SQL:

```sql
-- Add arrival OTP columns to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS arrival_otp TEXT,
ADD COLUMN IF NOT EXISTS arrival_otp_expiry TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS artisan_arrived BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS artisan_arrived_at TIMESTAMPTZ;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_jobs_arrival_otp ON jobs(job_reference) WHERE arrival_otp IS NOT NULL;

-- RLS policies for OTP access (using customer_email)
-- Allow edge functions to update arrival OTP
CREATE POLICY "Edge functions can update arrival OTP" ON jobs
    FOR UPDATE USING (true);

-- Allow customers to view their job OTP via email
CREATE POLICY "Customers can view own job OTP" ON jobs
    FOR SELECT USING (customer_email = auth.jwt()->>'email');

-- Allow artisans to update arrival status for their jobs
CREATE POLICY "Artisans can update arrival status" ON jobs
    FOR UPDATE USING (artisan_id IN (SELECT id FROM artisans WHERE email = auth.jwt()->>'email'));
```

4. Click **Run** to execute

---

## Step 2: Create Edge Functions via Dashboard

### Function 1: generateArrivalOtp

1. In Supabase Dashboard, go to **Edge Functions**
2. Click **New Function**
3. Name: `generateArrivalOtp`
4. Paste this code:

```typescript
const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function _generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function _getOtpExpiry(): string {
  const expiry = new Date();
  expiry.setMinutes(expiry.getMinutes() + 10);
  return expiry.toISOString();
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ success: false, error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const body = await req.json();
    const { jobReference, artisanId } = body;

    if (!jobReference || !artisanId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: jobReference, artisanId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const jobResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?job_reference=eq.${jobReference}&artisan_id=eq.${artisanId}`,
      {
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
      }
    );

    const jobs = await jobResponse.json();

    if (!jobs || jobs.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Job not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const job = jobs[0];

    if (job.status !== 'paid') {
      return new Response(
        JSON.stringify({ success: false, error: 'Job is not ready for arrival verification. Current status: ' + job.status }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const otp = _generateOtp();
    const otpExpiry = _getOtpExpiry();

    const updateJobResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?job_reference=eq.${jobReference}`,
      {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: JSON.stringify({
          arrival_otp: otp,
          arrival_otp_expiry: otpExpiry,
          artisan_arrived: true,
          artisan_arrived_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateJobResponse.ok) {
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to generate OTP' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'OTP generated successfully',
        otp: otp,
        otpExpiry: otpExpiry,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

5. Click **Create Function**

### Function 2: getJobOtp

1. Click **New Function** again
2. Name: `getJobOtp`
3. Paste this code:

```typescript
const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ success: false, error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const body = await req.json();
    const { jobReference } = body;

    if (!jobReference) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required field: jobReference' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const jobResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?job_reference=eq.${jobReference}`,
      {
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
      }
    );

    const jobs = await jobResponse.json();

    if (!jobs || jobs.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Job not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const job = jobs[0];
    const otp = job.arrival_otp;
    const otpExpiry = job.arrival_otp_expiry;
    const artisanArrived = job.artisan_arrived || false;

    if (!otp) {
      return new Response(
        JSON.stringify({
          success: true,
          otp: null,
          otpExpiry: null,
          artisanArrived: false,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (otpExpiry && new Date(otpExpiry) < new Date()) {
      return new Response(
        JSON.stringify({
          success: true,
          otp: null,
          otpExpiry: null,
          artisanArrived: false,
          message: 'OTP has expired',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        otp: otp,
        otpExpiry: otpExpiry,
        artisanArrived: artisanArrived,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

4. Click **Create Function**

---

## Step 3: Verify Setup

After completing both steps, your OTP verification system should be fully functional:

- **Artisan** taps "I've Arrived" → generates 6-digit OTP (valid 10 minutes)
- **Customer** can view the OTP on their jobs page
- OTP is verified before artisan can submit estimate

The Flutter app will now be able to:
1. Generate OTP when artisan arrives at the job location
2. Display OTP to customer for verification
3. Verify artisan arrival status for estimate submission
