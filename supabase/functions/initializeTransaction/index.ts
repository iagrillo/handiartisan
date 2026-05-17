// ============================================
// Supabase Edge Function: initializeTransaction
// Initializes Paystack payment for outcall booking
// ============================================

const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? 'https://awbqkptzknhlvxfboklf.supabase.co';
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
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const body = await req.json();

    const artisanId = body.artisanId || body.artisan_id;
    const customerEmail = body.customerEmail || body.customer_email;
    const customerName = body.customerName || body.customer_name;
    const customerPhone = body.customerPhone || body.customer_phone;
    const serviceType = body.serviceType || body.service_type;
    const description = body.description;
    const address = body.address;

    if (!artisanId || !customerEmail) {
      return new Response(
        JSON.stringify({ error: 'artisanId and customerEmail are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const timestamp = Date.now();
    const randomSuffix = Math.random().toString(36).substring(2, 8).toUpperCase();
    const requestedJobReference = body.jobReference || body.job_reference;
    const jobReference = requestedJobReference || `HH_JOB_${timestamp}_${randomSuffix}`;
    const paymentReference = `HH_PAY_${timestamp}`;

    const rawRequestedAmount = body.amount ?? body.amount_in_naira ?? body.amountInNaira ?? 0;
    const parsedAmount = Number(String(rawRequestedAmount).replace(/[^0-9.\-]/g, ''));
    let requestedAmount = Number.isNaN(parsedAmount) ? 0 : parsedAmount;
    let hasSubmittedEstimate = false;

    // If a job reference exists, inspect the stored estimate so the initial outcall
    // booking keeps its fixed ₦2,000 escrow while later estimate payments use the
    // real estimate value.
    if (requestedJobReference && SUPABASE_SERVICE_KEY) {
      try {
        const jobLookup = await fetch(
          `${SUPABASE_URL}/rest/v1/jobs?job_reference=eq.${encodeURIComponent(jobReference)}&select=estimate_total,estimate_materials_cost,estimate_labor_cost`,
          {
            headers: {
              apikey: SUPABASE_SERVICE_KEY,
              Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
            },
          }
        );

        if (jobLookup.ok) {
          const jobs = await jobLookup.json();
          if (Array.isArray(jobs) && jobs.length > 0) {
            const existingJob = jobs[0];
            const estimateTotal = Number(String(existingJob.estimate_total ?? existingJob.estimateTotal ?? 0).replace(/[^0-9.\-]/g, ''));
            const materialsCost = Number(String(existingJob.estimate_materials_cost ?? existingJob.estimateMaterialsCost ?? 0).replace(/[^0-9.\-]/g, ''));
            const laborCost = Number(String(existingJob.estimate_labor_cost ?? existingJob.estimateLaborCost ?? 0).replace(/[^0-9.\-]/g, ''));
            const computedEstimate = estimateTotal > 0 ? estimateTotal : (materialsCost + laborCost);
            hasSubmittedEstimate = computedEstimate > 0;
            if (requestedAmount <= 0 && !Number.isNaN(computedEstimate) && computedEstimate > 0) {
              requestedAmount = computedEstimate;
            }
          }
        }
      } catch (error) {
        console.error('Failed to load job estimate for amount fallback:', error);
      }
    }

    const amountInNaira = requestedAmount > 0 ? requestedAmount : 3000;
    const amount = Math.round(amountInNaira * 100);

    const isInitialOutcallBooking =
      (serviceType || 'outcall') === 'outcall' && !hasSubmittedEstimate;
    const escrowAmount = isInitialOutcallBooking
      ? Math.min(amountInNaira, 2000)
      : amountInNaira - Math.round(amountInNaira / 11);
    const commissionAmount = Math.max(amountInNaira - escrowAmount, 0);

    if (!PAYSTACK_SECRET_KEY || PAYSTACK_SECRET_KEY.length === 0) {
      return new Response(
        JSON.stringify({
          error: 'Paystack is not configured on the server. Payment cannot be initialized.',
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const paystackResponse = await fetch(
      'https://api.paystack.co/transaction/initialize',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: customerEmail,
          amount: amount,
          reference: paymentReference,
          callback_url: 'handihub://payment-success',
          metadata: {
            artisan_id: artisanId,
            job_reference: jobReference,
            customer_name: customerName || '',
            customer_phone: customerPhone || '',
            service_type: serviceType || 'outcall',
            description: description || '',
            address: address || '',
            escrow_amount: escrowAmount * 100,
            commission_amount: commissionAmount * 100,
          },
        }),
      }
    );

    const paystackData = await paystackResponse.json();

    if (!paystackResponse.ok || !paystackData.status) {
      return new Response(
        JSON.stringify({ error: paystackData.message || 'Failed to initialize payment' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const authorizationUrl = paystackData.data?.authorization_url;
    if (!authorizationUrl) {
      return new Response(
        JSON.stringify({ error: 'Paystack did not return an authorization URL' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

      // Create or update job record in database.
      // Payment remains pending until Paystack verification succeeds.
      try {
        let existingJobUpdated = false;
        if (requestedJobReference) {
          const updateResponse = await fetch(
            `${SUPABASE_URL}/rest/v1/jobs?job_reference=eq.${encodeURIComponent(jobReference)}`,
            {
              method: 'PATCH',
              headers: {
                'apikey': SUPABASE_SERVICE_KEY,
                'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=representation',
              },
              body: JSON.stringify({
                amount_paid: 0,
                escrow_amount: 0,
                commission_amount: 0,
                status: 'pending',
                payment_reference: paymentReference,
                updated_at: new Date().toISOString(),
              }),
            }
          );

          if (updateResponse.ok) {
            const updatedJob = await updateResponse.json();
            if (Array.isArray(updatedJob) && updatedJob.length > 0) {
              existingJobUpdated = true;
            }
          }
        }

        const jobData = {
          job_reference: jobReference,
          artisan_id: artisanId,
          customer_email: customerEmail,
          customer_name: customerName || '',
          customer_phone: customerPhone || '',
          service_type: serviceType || 'outcall',
          description: description || '',
          address: address || '',
          amount_paid: 0,
          escrow_amount: 0,
          commission_amount: 0,
          status: 'pending',
          payment_reference: paymentReference,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };

        if (!existingJobUpdated) {
          const jobResponse = await fetch(
            `${SUPABASE_URL}/rest/v1/jobs`,
            {
              method: 'POST',
              headers: {
                'apikey': SUPABASE_SERVICE_KEY,
                'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=representation',
              },
              body: JSON.stringify(jobData),
            }
          );

          if (!jobResponse.ok) {
            console.error('Failed to create job:', await jobResponse.text());
          }
        }
      } catch (dbError) {
      console.error('Database error:', dbError);
    }

    // Success response
    return new Response(
      JSON.stringify({
        success: true,
        authorization_url: authorizationUrl,
        reference: paymentReference,
        job_reference: jobReference,
        amount: amountInNaira,
        escrow_amount: escrowAmount,
        commission_amount: commissionAmount,
        message: 'Payment initialized successfully',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('InitializeTransaction Error:', error);

    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
