// ============================================
// Supabase Edge Function: verifyOutcallVisit
// Verifies artisan arrival at customer location and releases outcall fee
// ============================================

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? 'https://awbqkptzknhlvxfboklf.supabase.co';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnFrcHR6a25obHZ4ZmJva2xmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODM5MjkxOSwiZXhwIjoxNzA5OTI4OTE5fQ.K4AXxMHVd0VlBhGtYm0KP6Y8ZGjtM1aq5Q2ZzEQq1M';

const OUTCALL_FEE = 2000; // ₦2,000 outcall fee to artisan (after ₦1,000 commission)
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Calculate distance between two coordinates in meters (Haversine formula)
function _calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000; // Earth's radius in meters
  const dLat = _toRadians(lat2 - lat1);
  const dLon = _toRadians(lon2 - lon1);
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(_toRadians(lat1)) * Math.cos(_toRadians(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function _toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

interface VerifyOutcallRequest {
  jobReference: string;
  artisanId: string;
  customerId: string;
  verificationMethod: 'otp' | 'customerConfirm' | 'geoLocation';
  otp?: string;
  artisanLatitude?: number;
  artisanLongitude?: number;
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
    const body: VerifyOutcallRequest = await req.json();
    const { jobReference, artisanId, customerId, verificationMethod, otp } = body;

    // Validate required fields
    if (!jobReference || !artisanId || !customerId || !verificationMethod) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate verification method
    if (!['otp', 'customerConfirm', 'geoLocation'].includes(verificationMethod)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid verification method. Use "otp", "customerConfirm", or "geoLocation"' }),
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

    // Check if job is already verified (only fail for completed/accepted)
    if (job.status === 'completed' || job.status === 'accepted') {
      return new Response(
        JSON.stringify({ success: false, error: 'Job already verified' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verify based on method
    let isVerified = false;

    if (verificationMethod === 'otp') {
      // Verify OTP match
      if (!otp) {
        return new Response(
          JSON.stringify({ success: false, error: 'OTP is required for OTP verification' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Debug: Log what's in the job
      console.log('Debug - Job arrival_otp:', job.arrival_otp);
      console.log('Debug - User entered otp:', otp);
      console.log('Debug - Trimmed otp:', otp.trim());

      // Check OTP against stored OTP in job
      const storedOtp = job.arrival_otp || job.arrival_otp_code;
      console.log('Debug - storedOtp:', storedOtp, 'type:', typeof storedOtp);
      console.log('Debug - comparison:', storedOtp === otp.trim());
      
      if (storedOtp && storedOtp === otp.trim()) {
        isVerified = true;
      } else {
        // OTP verification failed - provide more info
        return new Response(
          JSON.stringify({ 
            success: false, 
            error: 'Invalid OTP code. Please check the code and try again.',
            debug: {
              storedOtp: storedOtp ? 'present' : 'missing',
              enteredOtp: otp.trim()
            }
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    } else if (verificationMethod === 'customerConfirm') {
      // Customer confirmation - check if customer_confirmed is true
      const customerConfirmed = job.customer_confirmed_arrival || job.customer_confirmed;
      if (customerConfirmed === true || customerConfirmed === 'true') {
        isVerified = true;
      } else {
        // Customer hasn't confirmed
        return new Response(
          JSON.stringify({ success: false, error: 'Customer has not confirmed arrival' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    } else if (verificationMethod === 'geoLocation') {
      // GeoLocation verification - verify artisan is near customer location
      const artisanLat = body.artisanLatitude;
      const artisanLon = body.artisanLongitude;
      
      if (!artisanLat || !artisanLon) {
        return new Response(
          JSON.stringify({ success: false, error: 'Location coordinates required for geoLocation verification' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Get customer location from job (stored when job was created)
      const customerLatitude = job.customer_latitude || job.customer_location?.latitude;
      const customerLongitude = job.customer_longitude || job.customer_location?.longitude;

      if (!customerLatitude || !customerLongitude) {
        return new Response(
          JSON.stringify({ success: false, error: 'Customer location not available for verification' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Calculate distance (Haversine formula simplified - in meters)
      const distance = _calculateDistance(
        artisanLat,
        artisanLon,
        customerLatitude,
        customerLongitude
      );

      // If within 500 meters, consider verified
      if (distance <= 500) {
        isVerified = true;
      } else {
        return new Response(
          JSON.stringify({ success: false, error: `Artisan is ${Math.round(distance)}m away. Must be within 500m to verify.` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // If still not verified after checks
    if (!isVerified) {
      return new Response(
        JSON.stringify({ success: false, error: 'Verification failed' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verification successful - update job status to estimate_pending
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
          status: 'estimate_pending',
          verified_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateJobResponse.ok) {
      console.error('Failed to update job status:', await updateJobResponse.text());
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to update job status' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Release outcall fee to artisan's wallet
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

    if (!wallets || wallets.length === 0) {
      console.error('Wallet not found for artisan:', artisanId);
      return new Response(
        JSON.stringify({ success: false, error: 'Wallet not found for artisan' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const wallet = wallets[0];
    const currentAvailable = wallet.available_balance || 0;
    const currentPending = wallet.pending_balance || 0;
    const currentTotalEarned = wallet.total_earned || 0;

    // Move outcall fee from pending_balance → available_balance (release from escrow).
    // pending_balance was credited when the customer's payment was received; decrement it
    // now so the total is not counted twice.
    const updateWalletResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/wallets?artisan_id=eq.${artisanId}`,
      {
        method: 'PATCH',
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: JSON.stringify({
          pending_balance: Math.max(0, currentPending - OUTCALL_FEE),
          available_balance: currentAvailable + OUTCALL_FEE,
          total_earned: currentTotalEarned + OUTCALL_FEE,
        }),
      }
    );

    if (!updateWalletResponse.ok) {
      console.error('Failed to update wallet:', await updateWalletResponse.text());
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to release funds to wallet' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Log the transaction
    const transactionLog = {
      wallet_id: wallet.id,
      artisan_id: artisanId,
      job_reference: jobReference,
      transaction_type: 'outcall_fee',
      amount: OUTCALL_FEE,
      status: 'completed',
      description: `Outcall visit verified for job ${jobReference}`,
      created_at: new Date().toISOString(),
    };

    await fetch(
      `${SUPABASE_URL}/rest/v1/wallet_transactions`,
      {
        method: 'POST',
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: JSON.stringify(transactionLog),
      }
    );

    // Return success
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Outcall verified, fee released',
        jobReference: jobReference,
        artisanId: artisanId,
        amountReleased: OUTCALL_FEE,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('verifyOutcallVisit Error:', error);

    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
