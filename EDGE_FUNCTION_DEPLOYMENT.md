# Manual Edge Function Deployment Guide

Since CLI deployment requires an interactive access token, follow these steps to deploy via Supabase Dashboard:

## Step 1: Access Edge Functions

Go to: https://supabase.com/dashboard/project/awbqkptzknhlvxfboklf/functions

## Step 2: Create Each Function

For each function below, click "New Function", enter the name, select "Edge" runtime, and paste the code:

### Function 1: `initializeTransaction`
```typescript
// supabase/functions/initializeTransaction/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY")!

serve(async (req) => {
  const { email, amount, artisan_id, job_reference } = await req.json()
  
  const response = await fetch("https://api.paystack.co/transaction/initialize", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${PAYSTACK_SECRET_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      email,
      amount: amount * 100, // Convert to kobo
      reference: job_reference,
      callback_url: "handihub://payment-success",
      metadata: {
        artisan_id,
        job_reference,
        custom_fields: [
          { display_name: "Job Reference", variable_name: "job_reference", value: job_reference }
        ]
      }
    })
  })
  
  const data = await response.json()
  return new Response(JSON.stringify(data), { headers: { "Content-Type": "application/json" } })
})
```

### Function 2: `webhookHandler`
```typescript
// supabase/functions/webhookHandler/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY")!
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

const crypto = await import("crypto")

serve(async (req) => {
  const signature = req.headers.get("x-paystack-signature")!
  const body = await req.text()
  
  // Verify signature
  const hash = crypto.createHmac("sha512", PAYSTACK_SECRET_KEY).update(body).digest("hex")
  if (hash !== signature) {
    return new Response(JSON.stringify({ error: "Invalid signature" }), { status: 401 })
  }
  
  const event = JSON.parse(body)
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  
  if (event.event === "charge.success") {
    const reference = event.data.reference
    const amount = event.data.amount / 100
    const metadata = event.data.metadata
    
    // Update job status to PAID
    await supabase.from("jobs").update({ 
      status: "paid", 
      amount_paid: amount 
    }).eq("job_reference", reference)
    
    // Add to artisan pending_balance (escrow)
    const { data: wallet } = await supabase.from("wallets")
      .select("pending_balance")
      .eq("artisan_id", metadata.artisan_id)
      .single()
    
    if (wallet) {
      await supabase.from("wallets")
        .update({ pending_balance: (wallet.pending_balance || 0) + amount })
        .eq("artisan_id", metadata.artisan_id)
    }
    
    // Record transaction
    await supabase.from("transactions").insert({
      reference,
      amount,
      status: "completed",
      job_reference: metadata.job_reference,
      customer_email: event.data.customer.email
    })
  }
  
  return new Response(JSON.stringify({ received: true }), { headers: { "Content-Type": "application/json" } })
})
```

### Function 3: `transferPayout`
```typescript
// supabase/functions/transferPayout/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY")!
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

serve(async (req) => {
  const { job_reference, action, recipient_code, otp } = await req.json()
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  
  const { data: job } = await supabase.from("jobs")
    .select("*, artisan:artisans(*)}")
    .eq("job_reference", job_reference)
    .single()
  
  if (!job) return new Response(JSON.stringify({ error: "Job not found" }), { status: 404 })
  
  if (action === "complete") {
    // Transfer to artisan minus commission
    const grossAmount = job.amount_paid
    const commission = grossAmount * 0.1 // 10%
    const netAmount = grossAmount - commission
    
    // Create transfer
    const transferResponse = await fetch("https://api.paystack.co/transfer", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${PAYSTACK_SECRET_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        source: "balance",
        amount: netAmount * 100,
        recipient: recipient_code,
        otp: otp
      })
    })
    
    const transferData = await transferResponse.json()
    
    if (transferData.status) {
      // Update job status
      await supabase.from("jobs").update({ status: "completed" }).eq("job_reference", job_reference)
      
      // Update wallet: move from pending to available
      const { data: wallet } = await supabase.from("wallets")
        .select("pending_balance, available_balance")
        .eq("artisan_id", job.artisan_id)
        .single()
      
      if (wallet) {
        await supabase.from("wallets").update({
          pending_balance: wallet.pending_balance - grossAmount,
          available_balance: (wallet.available_balance || 0) + netAmount,
          total_earned: (wallet.total_earned || 0) + netAmount
        }).eq("artisan_id", job.artisan_id)
      }
      
      return new Response(JSON.stringify({ success: true, transfer: transferData }))
    }
    
    return new Response(JSON.stringify(transferData), { status: 400 })
  }
  
  // Refund action
  const refundResponse = await fetch("https://api.paystack.co/refund", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${PAYSTACK_SECRET_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      transaction: job_reference,
      amount: job.amount_paid * 100
    })
  })
  
  const refundData = await refundResponse.json()
  
  if (refundData.status) {
    await supabase.from("jobs").update({ 
      status: action === "cancel" ? "cancelled" : "failed" 
    }).eq("job_reference", job_reference)
    
    // Deduct from pending balance
    const { data: wallet } = await supabase.from("wallets")
      .select("pending_balance")
      .eq("artisan_id", job.artisan_id)
      .single()
    
    if (wallet) {
      await supabase.from("wallets")
        .update({ pending_balance: wallet.pending_balance - job.amount_paid })
        .eq("artisan_id", job.artisan_id)
    }
    
    return new Response(JSON.stringify({ success: true, refund: refundData }))
  }
  
  return new Response(JSON.stringify(refundData), { status: 400 })
})
```

### Function 4: `refundTransaction`
```typescript
// supabase/functions/refundTransaction/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY")!
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

serve(async (req) => {
  const { job_reference } = await req.json()
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  
  const { data: job } = await supabase.from("jobs")
    .select("*")
    .eq("job_reference", job_reference)
    .single()
  
  if (!job) return new Response(JSON.stringify({ error: "Job not found" }), { status: 404 })
  
  const refundResponse = await fetch("https://api.paystack.co/refund", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${PAYSTACK_SECRET_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      transaction: job_reference,
      amount: job.amount_paid * 100
    })
  })
  
  const refundData = await refundResponse.json()
  
  if (refundData.status) {
    await supabase.from("jobs").update({ status: "refunded" }).eq("job_reference", job_reference)
    
    // Deduct from pending
    const { data: wallet } = await supabase.from("wallets")
      .select("pending_balance")
      .eq("artisan_id", job.artisan_id)
      .single()
    
    if (wallet) {
      await supabase.from("wallets")
        .update({ pending_balance: wallet.pending_balance - job.amount_paid })
        .eq("artisan_id", job.artisan_id)
    }
    
    return new Response(JSON.stringify({ success: true }))
  }
  
  return new Response(JSON.stringify(refundData), { status: 400 })
})
```

### Function 5: `releaseFunds`
```typescript
// supabase/functions/releaseFunds/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

serve(async (req) => {
  const { wallet_id, amount } = await req.json()
  
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  
  const { data: wallet, error } = await supabase.from("wallets")
    .select("pending_balance, available_balance")
    .eq("id", wallet_id)
    .single()
  
  if (error || !wallet) {
    return new Response(JSON.stringify({ error: "Wallet not found" }), { status: 404 })
  }
  
  if (amount > wallet.pending_balance) {
    return new Response(JSON.stringify({ error: "Insufficient pending balance" }), { status: 400 })
  }
  
  const { error: updateError } = await supabase.from("wallets")
    .update({
      pending_balance: wallet.pending_balance - amount,
      available_balance: (wallet.available_balance || 0) + amount
    })
    .eq("id", wallet_id)
  
  if (updateError) {
    return new Response(JSON.stringify({ error: updateError.message }), { status: 500 })
  }
  
  return new Response(JSON.stringify({ success: true }))
})
```

## Step 3: Set Environment Secrets

After creating each function, go to "Secrets" tab and add:
- `PAYSTACK_SECRET_KEY` - Your Paystack secret key (sk_live_... or sk_test_...)
- `SUPABASE_SERVICE_ROLE_KEY` - Your Supabase service_role key
- `SUPABASE_URL` - Your Supabase project URL

## Step 4: Configure Paystack Webhook

1. Go to Paystack Dashboard → Settings → Webhooks
2. Add your webhook URL:
   ```
   https://awbqkptzknhlvxfboklf.supabase.co/functions/v1/webhookHandler
   ```
3. Select "Enable" for charge.success event

### Function 6: `generateArrivalOtp`
```typescript
// supabase/functions/generateArrivalOtp/index.ts
// Generates OTP for artisan arrival verification

const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

const OUTCALL_FEE = 2000; // ₦2,000 outcall fee

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
    const body = await req.json();
    const { jobReference, artisanId } = body;

    if (!jobReference || !artisanId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get job
    const jobResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?job_reference=eq.${jobReference}&artisan_id=eq.${artisanId}`,
      { headers: { 'apikey': SUPABASE_SERVICE_KEY, 'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}` } }
    );
    const jobs = await jobResponse.json();

    if (!jobs || jobs.length === 0) {
      return new Response(JSON.stringify({ success: false, error: 'Job not found' }), { status: 404 });
    }

    const job = jobs[0];
    if (job.status !== 'paid') {
      return new Response(
        JSON.stringify({ success: false, error: 'Job not ready for arrival verification' }),
        { status: 400 }
      );
    }

    const otp = _generateOtp();
    const otpExpiry = _getOtpExpiry();

    // Update job with OTP
    await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?job_reference=eq.${jobReference}`,
      {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          arrival_otp: otp,
          arrival_otp_expiry: otpExpiry,
          artisan_arrived: true,
          artisan_arrived_at: new Date().toISOString(),
        }),
      }
    );

    return new Response(
      JSON.stringify({ success: true, otp: otp, otpExpiry: otpExpiry }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

### Function 7: `getJobOtp`
```typescript
// supabase/functions/getJobOtp/index.ts
// Retrieves OTP for customer to view

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
    const body = await req.json();
    const { jobReference } = body;

    if (!jobReference) {
      return new Response(JSON.stringify({ success: false, error: 'Missing jobReference' }), { status: 400 });
    }

    const jobResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?job_reference=eq.${jobReference}`,
      { headers: { 'apikey': SUPABASE_SERVICE_KEY, 'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}` } }
    );
    const jobs = await jobResponse.json();

    if (!jobs || jobs.length === 0) {
      return new Response(JSON.stringify({ success: false, error: 'Job not found' }), { status: 404 });
    }

    const job = jobs[0];
    const otp = job.arrival_otp;
    const otpExpiry = job.arrival_otp_expiry;
    const artisanArrived = job.artisan_arrived || false;

    // Check if OTP expired
    if (otp && otpExpiry && new Date(otpExpiry) < new Date()) {
      return new Response(
        JSON.stringify({ success: true, otp: null, artisanArrived: false, message: 'OTP expired' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, otp: otp, otpExpiry: otpExpiry, artisanArrived: artisanArrived }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

## Step 5: Test

Test the complete flow:
1. Use Outcall Book button → Paystack checkout
2. Check wallet for pending balance
3. Use admin "Release Funds" button
4. Verify wallet shows updated balances

## Step 6: Test OTP Verification Flow

1. Run `add_arrival_otp_columns.sql` in Supabase SQL Editor to add required columns
2. Deploy `generateArrivalOtp` and `getJobOtp` edge functions
3. Test the flow:
   - Customer has a job with "paid" status
   - Artisan logs in → sees job → clicks "I've Arrived"
   - OTP is generated and stored
   - Customer logs in → sees OTP on their job page
   - Customer gives code to artisan
   - Artisan enters code → clicks "Verify & Confirm Arrival"
   - If correct: ₦2000 moves from pending to available in artisan wallet
