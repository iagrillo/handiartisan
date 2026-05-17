// ============================================
// Supabase Edge Function: generateJobCompletionOtp
// Generates OTP for job completion verification
// ============================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function _generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function _getOtpExpiry(): string {
  const expiry = new Date();
  expiry.setMinutes(expiry.getMinutes() + 30);
  return expiry.toISOString();
}

interface GenerateCompletionOtpRequest {
  jobReference: string;
  artisanId: string;
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

    const body: GenerateCompletionOtpRequest = await req.json();
    const { jobReference, artisanId } = body;

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
    console.log('Job response:', JSON.stringify(jobs));

    if (!jobs || !Array.isArray(jobs) || jobs.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Job not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const job = jobs[0];
    console.log('Job data:', JSON.stringify(job));

    const laborCost = job.estimate_labor_cost;
    if (laborCost === null || laborCost === undefined || laborCost <= 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'No pending labor for this job' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const otp = _generateOtp();
    const otpExpiry = _getOtpExpiry();
    
    console.log('Generating completion OTP:', otp, 'expiry:', otpExpiry);

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
          status: 'pending_completion',
          completion_otp: otp,
          completion_otp_expiry: otpExpiry,
        }),
      }
    );

    if (!updateJobResponse.ok) {
      const errorText = await updateJobResponse.text();
      console.error('Failed to update job with completion OTP:', errorText);
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to generate OTP: ' + errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const customerPhone = job.customer_phone;
    const notifyUrl = Deno.env.get('NOTIFICATION_URL');

    if (notifyUrl && customerPhone) {
      try {
        await fetch(notifyUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            phone: customerPhone,
            message: `Your artisan has completed the work. Use OTP: ${otp} to verify completion.`,
            jobReference: jobReference,
          }),
        });
      } catch (e) {
        console.log('Notification failed:', e);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Completion OTP generated. Customer notified.',
        otp: otp,
        otpExpiry: otpExpiry,
        customerNotified: !!notifyUrl,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('generateJobCompletionOtp Error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Internal server error';

    return new Response(
      JSON.stringify({ success: false, error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});