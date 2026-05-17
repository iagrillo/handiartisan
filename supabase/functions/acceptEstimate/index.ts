// ============================================
// Supabase Edge Function: acceptEstimate
// Customer accepts an estimate - creates contract with escrow
// ============================================

const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface AcceptEstimateRequest {
  jobReference: string;
  customerId: string;
}

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

    const body: AcceptEstimateRequest = await req.json();
    const { jobReference, customerId } = body;

    if (!jobReference || !customerId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: jobReference and customerId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get job and estimate
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

    // Check if estimate is submitted
    if (job.status !== 'estimate_submitted') {
      return new Response(
        JSON.stringify({ success: false, error: 'No pending estimate to accept' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const artisanId = job.artisan_id;
    const estimateId = job.estimate_id;
    const totalAmount = job.estimate_total;

    // Generate contract reference
    const timestamp = Date.now();
    const contractReference = `HH_CONTRACT_${timestamp}`;

    // Create contract
    const contractResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/job_contracts`,
      {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: JSON.stringify({
          contract_reference: contractReference,
          job_reference: jobReference,
          artisan_id: artisanId,
          customer_id: customerId,
          estimate_id: estimateId,
          total_amount: totalAmount,
          escrow_amount: totalAmount,
          status: 'contract_active',
          payment_status: 'pending',
        }),
      }
    );

    if (!contractResponse.ok) {
      console.error('Failed to create contract:', await contractResponse.text());
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to create contract' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const contract = await contractResponse.json();

    // Update job status
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
          status: 'contract_active',
          estimate_status: 'accepted',
          estimate_responded_at: new Date().toISOString(),
          contract_id: contract[0]?.id,
        }),
      }
    );

    // Update estimate status
    if (estimateId) {
      await fetch(
        `${SUPABASE_URL}/rest/v1/estimates?id=eq.${estimateId}`,
        {
          method: 'PATCH',
          headers: {
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: JSON.stringify({
            status: 'accepted',
            updated_at: new Date().toISOString(),
          }),
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Estimate accepted, contract created with escrow',
        jobReference: jobReference,
        contractReference: contractReference,
        escrowAmount: totalAmount,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('acceptEstimate Error:', error);
    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
