// ============================================
// Supabase Edge Function: declineEstimate
// Customer declines an estimate - job closes, artisan keeps outcall fee
// ============================================

const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface DeclineEstimateRequest {
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

    const body: DeclineEstimateRequest = await req.json();
    const { jobReference, customerId } = body;

    if (!jobReference || !customerId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: jobReference and customerId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get job
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
        JSON.stringify({ success: false, error: 'No pending estimate to decline' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const artisanId = job.artisan_id;
    const estimateId = job.estimate_id;

    // Update job status to closed
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
          status: 'closed',
          estimate_status: 'declined',
          estimate_responded_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateJobResponse.ok) {
      console.error('Failed to update job:', await updateJobResponse.text());
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to close job' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

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
            status: 'declined',
            updated_at: new Date().toISOString(),
          }),
        }
      );
    }

    // Note: Artisan keeps the outcall fee already released during verification

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Estimate declined. Job closed. Artisan keeps outcall fee.',
        jobReference: jobReference,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('declineEstimate Error:', error);
    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
