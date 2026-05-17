// ============================================
// Supabase Edge Function: refundTransaction
// Refunds payment to customer
// ============================================

const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

interface RefundRequest {
  jobId: string;
  reason?: string;
}

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
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

    // Parse request body
    const body: RefundRequest = await req.json();
    const { jobId, reason } = body;

    // Validate required fields
    if (!jobId) {
      return new Response(
        JSON.stringify({ error: 'jobId is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Get job details
    const jobResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?id=eq.${jobId}`,
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
        JSON.stringify({ error: 'Job not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const job = jobs[0];

    // Check if job can be refunded
    const refundableStatuses = ['paid', 'in_progress', 'pending'];
    if (!refundableStatuses.includes(job.status)) {
      return new Response(
        JSON.stringify({ 
          error: 'Job cannot be refunded in current status',
          current_status: job.status 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Check if already refunded
    if (job.status === 'refunded') {
      return new Response(
        JSON.stringify({ error: 'Job already refunded' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    if (!job.payment_reference) {
      return new Response(
        JSON.stringify({ error: 'No payment reference found' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const artisanId = job.artisan_id;
    const refundAmount = job.amount_paid * 100; // Convert to kobo

    // Initiate Paystack refund
    const refundResponse = await fetch('https://api.paystack.co/refund', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
      },
      body: JSON.stringify({
        transaction: job.payment_reference,
        amount: refundAmount,
        reason: reason || 'Job cancelled or failed',
      }),
    });

    const refundData = await refundResponse.json();

    if (!refundData.status) {
      // Record failed refund
      await recordTransaction(
        SUPABASE_URL,
        SUPABASE_SERVICE_KEY,
        `RF_${job.job_reference}_${Date.now()}`,
        job.job_reference,
        artisanId,
        job.customer_email,
        refundAmount / 100,
        'refund',
        'failed',
        refundData.message
      );

      return new Response(
        JSON.stringify({ 
          error: 'Refund failed',
          details: refundData.message 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const refundReference = refundData.data.reference;

    // Get artisan wallet and deduct escrow amount if any was held
    if (job.escrow_amount > 0) {
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
      
      if (wallets && wallets.length > 0) {
        const wallet = wallets[0];
        
        // Deduct from pending balance
        await fetch(
          `${SUPABASE_URL}/rest/v1/wallets?id=eq.${wallet.id}`,
          {
            method: 'PATCH',
            headers: {
              'Content-Type': 'application/json',
              'apikey': SUPABASE_SERVICE_KEY,
              'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
            },
            body: JSON.stringify({
              pending_balance: Math.max(0, wallet.pending_balance - job.escrow_amount),
              updated_at: new Date().toISOString(),
            }),
          }
        );
      }
    }

    // Update job status
    await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?id=eq.${jobId}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
        body: JSON.stringify({
          status: 'refunded',
          refund_reference: refundReference,
          updated_at: new Date().toISOString(),
        }),
      }
    );

    // Record refund transaction
    await recordTransaction(
      SUPABASE_URL,
      SUPABASE_SERVICE_KEY,
      refundReference,
      job.job_reference,
      artisanId,
      job.customer_email,
      refundAmount / 100,
      'refund',
      'success',
      null
    );

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Refund processed successfully',
        job_id: jobId,
        job_reference: job.job_reference,
        refund_reference: refundReference,
        refund_amount: refundAmount / 100,
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
    console.error('Error in refundTransaction:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});

// Helper function to record transactions
async function recordTransaction(
  supabaseUrl: string,
  serviceKey: string,
  reference: string,
  jobReference: string,
  artisanId: string,
  customerEmail: string,
  amount: number,
  type: string,
  status: string,
  failureReason: string | null
) {
  await fetch(`${supabaseUrl}/rest/v1/transactions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': serviceKey,
      'Authorization': `Bearer ${serviceKey}`,
    },
    body: JSON.stringify({
      reference: reference,
      job_reference: jobReference,
      artisan_id: artisanId,
      customer_email: customerEmail,
      amount: amount,
      fee: 0,
      net_amount: amount,
      type: type,
      status: status,
      failure_reason: failureReason,
    }),
  });
}
