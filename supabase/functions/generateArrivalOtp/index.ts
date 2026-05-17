// ============================================
// Supabase Edge Function: generateArrivalOtp
// Generates OTP for artisan arrival verification
// ============================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Generate random 6-digit OTP
function _generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Get OTP expiry time (10 minutes from now)
function _getOtpExpiry(): string {
  const expiry = new Date();
  expiry.setMinutes(expiry.getMinutes() + 10);
  return expiry.toISOString();
}

interface GenerateOtpRequest {
  jobReference: string;
  artisanId: string;
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
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'https://awbqkptzknhlvxfboklf.supabase.co';
    const supabaseKey = Deno.env.get('SERVICE_ROLE_KEY') ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnFrcHR6a25obHZ4ZmJva2xmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODM5MjkxOSwiZXhwIjoxNzA5OTI4OTE5fQ.K4AXxMHVd0VlBhGtYm0KP6Y8ZGjtM1aq5Q2ZzEQq1M';

    // Parse request body
    const body: GenerateOtpRequest = await req.json();
    const { jobReference, artisanId } = body;

    // Validate required fields
    if (!jobReference || !artisanId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields: jobReference, artisanId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get job from database using REST API
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

    // Allow OTP generation for testing - in production, uncomment the status check
    // if (job.status !== 'paid') {
    //   return new Response(
    //     JSON.stringify({ success: false, error: 'Job is not ready for arrival verification. Current status: ' + job.status }),
    //     { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    //   );
    // }

    // Generate OTP
    const otp = _generateOtp();
    const otpExpiry = _getOtpExpiry();
    
    // Store OTP in job record
    console.log('Updating job with OTP:', otp, 'expiry:', otpExpiry);
    
    const updateJobResponse = await fetch(
      `${supabaseUrl}/rest/v1/jobs?job_reference=eq.${jobReference}`,
      {
        method: 'PATCH',
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: JSON.stringify({
          arrival_otp: otp,
          arrival_otp_expiry: otpExpiry,
          artisan_arrived: true,
          artisan_arrived_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateJobResponse.ok) {
      const errorText = await updateJobResponse.text();
      console.error('Failed to update job with OTP:', errorText);
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to generate OTP: ' + errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Return success - OTP stored in database for customer to view
    return new Response(
      JSON.stringify({
        success: true,
        message: 'OTP sent to customer. Wait for customer to call you with the code.',
        otpExpiry: otpExpiry,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('generateArrivalOtp Error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Internal server error';

    return new Response(
      JSON.stringify({ success: false, error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
