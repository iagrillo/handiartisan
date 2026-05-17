// ============================================
// Supabase Edge Function: webhookHandler
// Handles Paystack webhook events (charge.success)
// ============================================

const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? 'https://awbqkptzknhlvxfboklf.supabase.co';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnFrcHR6a25obHZ4ZmJva2xmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODM5MjkxOSwiZXhwIjoxNzA5OTI4OTE5fQ.K4AXxMHVd0VlBhGtYm0KP6Y8ZGjtM1aq5Q2ZzEQq1M';

// Paystack webhook event types
type PaystackEvent = {
  event: string;
  data: {
    id: number;
    reference: string;
    amount: number;
    currency: string;
    status: string;
    customer: {
      email: string;
      phone?: string;
      first_name?: string;
      last_name?: string;
    };
    metadata?: {
      job_id?: string;
      job_reference?: string;
      artisan_id?: string;
      escrow_amount?: number;
      commission_amount?: number;
    };
    authorization?: {
      authorization_code: string;
      bank?: string;
      channel: string;
      last4: string;
    };
  };
};

Deno.serve(async (req) => {
  // Handle CORS for preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-paystack-signature, content-type',
      },
    });
  }

  try {
    // Only allow POST
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Verify Paystack signature
    const signature = req.headers.get('x-paystack-signature');
    if (!signature) {
      return new Response(
        JSON.stringify({ error: 'Missing Paystack signature' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Get raw request body for signature verification
    const rawBody = await req.text();
    
    // Verify signature using HMAC-SHA512
    const encoder = new TextEncoder();
    const key = encoder.encode(PAYSTACK_SECRET_KEY);
    const data = encoder.encode(rawBody);
    
    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      key,
      { name: 'HMAC', hash: 'SHA-512' },
      false,
      ['sign']
    );
    
    const signatureBuffer = await crypto.subtle.sign('HMAC', cryptoKey, data);
    const computedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');

    if (computedSignature !== signature) {
      console.error('Invalid signature:', { expected: signature, computed: computedSignature });
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Parse webhook payload
    const payload: PaystackEvent = JSON.parse(rawBody);
    
    console.log('Received webhook event:', payload.event);

    // Handle only charge.success events
    if (payload.event !== 'charge.success') {
      return new Response(
        JSON.stringify({ message: `Event ${payload.event} ignored` }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const paymentData = payload.data;
    const reference = paymentData.reference;
    const amount = paymentData.amount;
    const customer = paymentData.customer;
    const metadata = paymentData.metadata || {};

    // Find job by reference
    const jobResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?payment_reference=eq.${reference}`,
      {
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
      }
    );

    const jobs = await jobResponse.json();
    
    if (!jobs || jobs.length === 0) {
      console.error('Job not found for reference:', reference);
      return new Response(
        JSON.stringify({ error: 'Job not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const job = jobs[0];
    
    // Check if already processed (idempotency)
    if (job.status === 'paid') {
      console.log('Job already processed:', job.job_reference);
      return new Response(
        JSON.stringify({ message: 'Job already processed' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const artisanId = metadata.artisan_id || job.artisan_id;
    const hasSubmittedEstimate =
      Number(job.estimate_total || job.estimateTotal || 0) > 0 ||
      Number(job.estimate_materials_cost || job.estimateMaterialsCost || 0) > 0 ||
      Number(job.estimate_labor_cost || job.estimateLaborCost || 0) > 0;
    const isInitialOutcallBooking =
      (job.service_type || job.serviceType) === 'outcall' && !hasSubmittedEstimate;
    const paidAmount = amount / 100;
    const escrowAmount = isInitialOutcallBooking
      ? Math.min(paidAmount, 2000)
      : (metadata.escrow_amount || job.escrow_amount * 100) / 100; // Convert from kobo
    const commissionAmount = isInitialOutcallBooking
      ? Math.max(paidAmount - escrowAmount, 0)
      : (metadata.commission_amount || job.commission_amount * 100) / 100;

    // Get artisan wallet
    const walletResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/wallets?artisan_id=eq.${artisanId}`,
      {
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
      }
    );

    const wallets = await walletResponse.json();
    
    if (!wallets || wallets.length === 0) {
      console.error('Wallet not found for artisan:', artisanId);
      return new Response(
        JSON.stringify({ error: 'Wallet not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const wallet = wallets[0];

    // Start transaction - update job status and wallet
    // 1. Update job to PAID status
    const updateJobResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?id=eq.${job.id}&status=in.(pending,accepted,estimate_accepted,estimate_submitted)`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Prefer': 'return=representation',
        },
        body: JSON.stringify({
          status: 'paid',
          ...(hasSubmittedEstimate ? { estimate_status: 'accepted' } : {}),
          amount_paid: amount / 100,
          updated_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateJobResponse.ok) {
      console.error('Failed to update job status');
      return new Response(
        JSON.stringify({ error: 'Failed to update job' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const updatedJobs = await updateJobResponse.json();
    if (!Array.isArray(updatedJobs) || updatedJobs.length === 0) {
      console.log('Job was already finalized by another verifier:', job.job_reference);
      return new Response(
        JSON.stringify({ message: 'Job already processed' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // 2. Update artisan wallet based on estimate split
    const materialAmount = Number(job.estimate_materials_cost || job.estimateMaterialsCost || 0);
    const laborAmount = Number(job.estimate_labor_cost || job.estimateLaborCost || 0);
    const estimateTotal = Number(job.estimate_total || job.estimateTotal || 0);
    const hasEstimateSplit = materialAmount > 0 || laborAmount > 0;
    const isOutcallBooking = (job.service_type || job.serviceType) === 'outcall' && !hasEstimateSplit;

    // For initial outcall bookings (no estimate yet), hold escrow in pending_balance until
    // the artisan's arrival is verified by verifyOutcallVisit. This prevents double-crediting
    // because verifyOutcallVisit will later move it from pending → available.
    const walletAvailableDelta = isOutcallBooking
      ? 0
      : hasEstimateSplit
        ? materialAmount
        : estimateTotal > 0 ? estimateTotal : escrowAmount;
    const walletPendingDelta = isOutcallBooking
      ? escrowAmount
      : hasEstimateSplit ? laborAmount : 0;
    const walletEarnedDelta = isOutcallBooking ? 0 : walletAvailableDelta + walletPendingDelta;

    const updateWalletResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/wallets?id=eq.${wallet.id}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
        body: JSON.stringify({
          pending_balance: wallet.pending_balance + walletPendingDelta,
          available_balance: wallet.available_balance + walletAvailableDelta,
          total_earned: wallet.total_earned + walletEarnedDelta,
          updated_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateWalletResponse.ok) {
      console.error('Failed to update wallet');
      // Job is already marked as paid, but wallet update failed
      // This should be handled by a reconciliation job
    }

    // 3. Record transaction
    const transactionResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/transactions?on_conflict=reference`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Prefer': 'resolution=ignore-duplicates',
        },
        body: JSON.stringify({
          reference: reference,
          job_reference: job.job_reference,
          artisan_id: artisanId,
          customer_email: customer.email,
          amount: amount / 100,
          fee: 0,
          net_amount: amount / 100,
          type: 'escrow',
          status: 'success',
          paystack_response: paymentData,
        }),
      }
    );

    if (!transactionResponse.ok) {
      console.error('Failed to record transaction');
    }

    console.log('Payment processed successfully:', {
      job_reference: job.job_reference,
      artisan_id: artisanId,
      escrow_amount: escrowAmount,
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Payment processed successfully',
        job_reference: job.job_reference,
        escrow_amount: escrowAmount,
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );

  } catch (error) {
    console.error('Error in webhookHandler:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
