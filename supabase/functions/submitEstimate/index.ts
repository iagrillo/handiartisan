// ============================================
// Supabase Edge Function: submitEstimate
// Allows artisans to submit job estimates for customer approval
// ============================================

const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface SubmitEstimateRequest {
  jobReference: string;
  artisanId: string;
  materials: { name: string; cost: number; quantity?: number }[];
  laborCost: number;
  timeline: string; // e.g., "2 days", "1 week"
  notes?: string;
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
    const body: SubmitEstimateRequest = await req.json();
    const { jobReference, artisanId, materials, laborCost, timeline, notes } = body;

    // Validate required fields
    if (!jobReference || !artisanId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: jobReference and artisanId are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate materials and labor cost
    if (!materials || !Array.isArray(materials) || materials.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Materials list is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (laborCost === undefined || laborCost === null || laborCost < 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Valid labor cost is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!timeline) {
      return new Response(
        JSON.stringify({ success: false, error: 'Timeline is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get job from database
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

    // Allow estimate submission for jobs in various statuses (not just estimate_pending)
    // This allows artisans to submit estimates directly without needing outcall verification
    const allowedStatuses = ['pending', 'paid', 'estimate_pending', 'arrival_confirmed', 'outcall_confirmed'];
    if (!allowedStatuses.includes(job.status)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Job status does not allow estimate submission. Current status: ' + job.status }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Calculate total estimate cost
    const materialsTotal = materials.reduce((sum, item) => sum + (item.cost * (item.quantity || 1)), 0);
    const totalEstimate = materialsTotal + laborCost;

    // Update job with estimate details
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
          status: 'estimate_submitted',
          estimate_materials: JSON.stringify(materials),
          estimate_materials_cost: materialsTotal,
          estimate_labor_cost: laborCost,
          estimate_total: totalEstimate,
          estimate_timeline: timeline,
          estimate_notes: notes || '',
          estimate_submitted_at: new Date().toISOString(),
          estimate_status: 'pending', // pending, accepted, declined
        }),
      }
    );

    if (!updateJobResponse.ok) {
      const errorText = await updateJobResponse.text();
      console.error('Failed to update job with estimate:', errorText);
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to submit estimate', details: errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Return success
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Estimate submitted successfully',
        jobReference: jobReference,
        artisanId: artisanId,
        estimate: {
          materials: materials,
          materialsTotal: materialsTotal,
          laborCost: laborCost,
          totalEstimate: totalEstimate,
          timeline: timeline,
          notes: notes,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('submitEstimate Error:', error);

    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
