// ============================================
// Supabase Edge Function: getJobOtp
// Retrieves OTP for customer to view
// ============================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface GetOtpRequest {
  jobReference: string;
}

Deno.serve(async (req: Request) => {
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

    // Get Supabase URL and key from environment
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

    // Parse request body
    const body: GetOtpRequest = await req.json();
    const { jobReference } = body;

    // Validate required fields
    if (!jobReference) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required field: jobReference' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get job from database
    const jobResponse = await fetch(
      `${supabaseUrl}/rest/v1/jobs?job_reference=eq.${jobReference}`,
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

    // Check if artisan has generated OTP
    const otp = job.arrival_otp;
    const otpExpiry = job.arrival_otp_expiry;
    const artisanArrived = job.artisan_arrived || false;

    // If no OTP or expired, return not arrived
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

    // Check if OTP has expired
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

    // Return OTP info
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
    console.error('getJobOtp Error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Internal server error';

    return new Response(
      JSON.stringify({ success: false, error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
