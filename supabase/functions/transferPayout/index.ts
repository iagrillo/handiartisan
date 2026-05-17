// ============================================
// Supabase Edge Function: transferPayout
// Handles job completion (payout to artisan) or cancellation (refund to customer)
// ============================================

const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  // Handle CORS preflight
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
    const { jobId, action, reason } = body;

    // Validate required fields
    if (!jobId || !action) {
      return new Response(
        JSON.stringify({ success: false, error: 'jobId and action are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (action !== 'complete' && action !== 'cancel') {
      return new Response(
        JSON.stringify({ success: false, error: 'action must be "complete" or "cancel"' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Fetch job record from Supabase
    const jobResponse = await fetch(`${SUPABASE_URL}/rest/v1/jobs?id=eq.${jobId}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
    });

    const jobs = await jobResponse.json();
    
    if (!jobs || jobs.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Job not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const job = jobs[0];

    if (action === 'complete') {
      // Move escrow funds to artisan's wallet
      const escrowAmount = job.escrow_amount || 0;
      const commissionAmount = job.commission_amount || 0;
      const payoutAmount = escrowAmount - commissionAmount;

      // Update wallet: deduct from pending, add to available
      const walletResponse = await fetch(
        `${SUPABASE_URL}/rest/v1/wallets?artisan_id=eq.${job.artisan_id}`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
        }
      );

      const wallets = await walletResponse.json();

      if (wallets && wallets.length > 0) {
        const wallet = wallets[0];
        const newPendingBalance = (wallet.pending_balance || 0) - escrowAmount;
        const newAvailableBalance = (wallet.available_balance || 0) + payoutAmount;
        const newTotalEarned = (wallet.total_earned || 0) + payoutAmount;

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
              pending_balance: newPendingBalance,
              available_balance: newAvailableBalance,
              total_earned: newTotalEarned,
            }),
          }
        );
      }

      // Update job status to completed
      await fetch(
        `${SUPABASE_URL}/rest/v1/jobs?id=eq.${jobId}`,
        {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
          body: JSON.stringify({ status: 'completed' }),
        }
      );

      // Record transaction
      await fetch(`${SUPABASE_URL}/rest/v1/transactions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
        body: JSON.stringify({
          reference: job.job_reference,
          job_reference: job.job_reference,
          artisan_id: job.artisan_id,
          customer_email: job.customer_email,
          amount: payoutAmount,
          type: 'payout',
          status: 'completed',
        }),
      });

      return new Response(
        JSON.stringify({
          success: true,
          payout_amount: payoutAmount,
          message: 'Job completed',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );

    } else if (action === 'cancel') {
      // Refund the customer via Paystack
      const refundAmount = (job.amount_paid || 0) * 100; // Convert to kobo

      const refundResponse = await fetch('https://api.paystack.co/refund', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          transaction: job.job_reference,
          amount: refundAmount,
        }),
      });

      const refundData = await refundResponse.json();

      if (!refundResponse.ok || !refundData.status) {
        return new Response(
          JSON.stringify({ success: false, error: refundData.message || 'Refund failed' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Update job status to cancelled
      await fetch(
        `${SUPABASE_URL}/rest/v1/jobs?id=eq.${jobId}`,
        {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
          body: JSON.stringify({ status: 'cancelled' }),
        }
      );

      // Deduct from pending balance
      const walletResponse = await fetch(
        `${SUPABASE_URL}/rest/v1/wallets?artisan_id=eq.${job.artisan_id}`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
        }
      );

      const wallets = await walletResponse.json();

      if (wallets && wallets.length > 0) {
        const wallet = wallets[0];
        const newPendingBalance = (wallet.pending_balance || 0) - (job.amount_paid || 0);

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
              pending_balance: newPendingBalance,
            }),
          }
        );
      }

      // Record refund transaction
      await fetch(`${SUPABASE_URL}/rest/v1/transactions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
        body: JSON.stringify({
          reference: `${job.job_reference}_refund`,
          job_reference: job.job_reference,
          artisan_id: job.artisan_id,
          customer_email: job.customer_email,
          amount: job.amount_paid,
          type: 'refund',
          status: 'completed',
          failure_reason: reason,
        }),
      });

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Job cancelled and refunded',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

  } catch (error) {
    console.error('transferPayout Error:', error);

    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
