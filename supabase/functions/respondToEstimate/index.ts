// ============================================
// Supabase Edge Function: respondToEstimate
// Allows customers to accept or decline an estimate
// If accepted, creates a new job contract with escrow
// ============================================

const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface RespondToEstimateRequest {
  jobReference: string;
  customerId: string;
  response: 'accept' | 'decline';
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Only allow POST
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ success: false, error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    const body: RespondToEstimateRequest = await req.json();
    const { jobReference, customerId, response } = body;

    // Validate required fields
    if (!jobReference || !customerId || !response) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: jobReference, customerId, and response are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate response
    if (!['accept', 'decline'].includes(response)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid response. Use "accept" or "decline"' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get job from database
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

    // Check if job is in estimate_submitted status
    if (job.status !== 'estimate_submitted') {
      return new Response(
        JSON.stringify({ success: false, error: 'No pending estimate for this job' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get estimate details
    const estimateTotal = job.estimate_total;
    const artisanId = job.artisan_id;

    if (response === 'decline') {
      // Update job status to estimate_declined
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
            status: 'estimate_declined',
            estimate_status: 'declined',
            estimate_responded_at: new Date().toISOString(),
          }),
        }
      );

      if (!updateJobResponse.ok) {
        console.error('Failed to update job status:', await updateJobResponse.text());
        return new Response(
          JSON.stringify({ success: false, error: 'Failed to respond to estimate' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Estimate declined',
          jobReference: jobReference,
          response: 'declined',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Response is accept - create contract with escrow
    // Generate new contract reference
    const timestamp = Date.now();
    const contractReference = `HH_CONTRACT_${timestamp}`;

    // Create contract record
    const contractData = {
      contract_reference: contractReference,
      job_reference: jobReference,
      artisan_id: artisanId,
      customer_id: customerId,
      total_amount: estimateTotal,
      escrow_amount: estimateTotal, // Full amount goes to escrow
      status: 'active',
      payment_status: 'pending',
      created_at: new Date().toISOString(),
    };

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
        body: JSON.stringify(contractData),
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

    // Update job status to accepted
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
          status: 'accepted',
          estimate_status: 'accepted',
          estimate_responded_at: new Date().toISOString(),
          contract_id: contract[0]?.id || null,
          contract_reference: contractReference,
        }),
      }
    );

    if (!updateJobResponse.ok) {
      console.error('Failed to update job status:', await updateJobResponse.text());
    }

    // Return success with contract details
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Estimate accepted, contract created',
        jobReference: jobReference,
        response: 'accepted',
        contract: {
          contractReference: contractReference,
          totalAmount: estimateTotal,
          escrowAmount: estimateTotal,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('respondToEstimate Error:', error);

    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
