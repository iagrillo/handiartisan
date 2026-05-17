// ============================================
// Supabase Edge Function: verifyAndReleaseLabor
// Called when customer verifies + artisan confirms
// ============================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface VerifyLaborRequest {
  jobReference: string;
  artisanId: string;
  customerOtp?: string;
  artisanOtp?: string;
}

Deno.serve(async (req: Request) => {
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

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'https://awbqkptzknhlvxfboklf.supabase.co';
    const supabaseKey = Deno.env.get('SERVICE_ROLE_KEY') ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnFrcHR6a25obHZ4ZmJva2xmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODM5MjkxOSwiZXhwIjoxNzA5OTI4OTE5fQ.K4AXxMHVd0VlBhGtYm0KP6Y8ZGjtM1aq5Q2ZzEQq1M';

    const body: VerifyLaborRequest = await req.json();
    const { jobReference, artisanId, customerOtp } = body;

    if (!jobReference || !artisanId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: jobReference, artisanId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const jobResponse = await fetch(
      `${supabaseUrl}/rest/v1/jobs?job_reference=eq.${jobReference}&artisan_id=eq.${artisanId}`,
      {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
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

    if (job.status !== 'pending_completion' && job.status !== 'pending_completion_confirmation') {
      return new Response(
        JSON.stringify({ success: false, error: 'Job is not in pending completion state' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!customerOtp) {
      return new Response(
        JSON.stringify({ success: false, error: 'Customer OTP is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (job.completion_otp !== customerOtp) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid OTP' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (job.completion_otp_expiry && new Date(job.completion_otp_expiry) < new Date()) {
      return new Response(
        JSON.stringify({ success: false, error: 'OTP has expired' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const laborCost = job.estimate_labor_cost || 0;

    if (laborCost <= 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'No labor cost to release' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const walletResponse = await fetch(
      `${supabaseUrl}/rest/v1/wallets?artisan_id=eq.${artisanId}`,
      {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        },
      }
    );

    const wallets = await walletResponse.json();

    if (!wallets || wallets.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Wallet not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const wallet = wallets[0];
    const currentPending = wallet.pending_balance || 0;
    const currentAvailable = wallet.available_balance || 0;

    const updateWalletResponse = await fetch(
      `${supabaseUrl}/rest/v1/wallets?id=eq.${wallet.id}`,
      {
        method: 'PATCH',
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          pending_balance: Math.max(0, currentPending - laborCost),
          available_balance: currentAvailable + laborCost,
          updated_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateWalletResponse.ok) {
      const errorText = await updateWalletResponse.text();
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to update wallet: ' + errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const updateJobResponse = await fetch(
      `${supabaseUrl}/rest/v1/jobs?job_reference=eq.${jobReference}`,
      {
        method: 'PATCH',
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          status: 'completed',
          labor_cost_released: true,
          labor_cost_released_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        }),
      }
    );

    const transactionRef = `TXN_${Date.now()}_${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
    await fetch(
      `${supabaseUrl}/rest/v1/transactions`,
      {
        method: 'POST',
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          reference: transactionRef,
          job_reference: jobReference,
          artisan_id: artisanId,
          customer_email: job.customer_email,
          amount: laborCost,
          fee: 0,
          net_amount: laborCost,
          type: 'labor_release',
          status: 'success',
        }),
      }
    );

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Labor cost released to wallet',
        amountReleased: laborCost,
        jobReference: jobReference,
        transactionRef: transactionRef,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('verifyAndReleaseLabor Error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Internal server error';

    return new Response(
      JSON.stringify({ success: false, error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});