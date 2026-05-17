export {};

const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? 'https://awbqkptzknhlvxfboklf.supabase.co';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type PaystackVerifyResponse = {
  status: boolean;
  message?: string;
  data?: {
    status?: string;
    reference?: string;
    amount?: number;
    customer?: { email?: string };
    metadata?: {
      artisan_id?: string;
      escrow_amount?: number;
      commission_amount?: number;
    };
  };
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function normalizeMoney(value: number, paidAmount: number) {
  if (!Number.isFinite(value) || value <= 0) return 0;
  return value > paidAmount * 2 ? value / 100 : value;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  try {
    const body = await req.json();
    const jobReference = body.jobReference || body.job_reference;
    const paymentReference = body.paymentReference || body.payment_reference;

    if (!jobReference && !paymentReference) {
      return jsonResponse({ error: 'jobReference or paymentReference is required' }, 400);
    }

    const query = jobReference
      ? `job_reference=eq.${encodeURIComponent(jobReference)}`
      : `payment_reference=eq.${encodeURIComponent(paymentReference)}`;

    const jobResponse = await fetch(`${SUPABASE_URL}/rest/v1/jobs?${query}&select=*`, {
      headers: {
        apikey: SUPABASE_SERVICE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
    });

    if (!jobResponse.ok) {
      return jsonResponse({ error: 'Failed to load job' }, 500);
    }

    const jobs = await jobResponse.json();
    if (!Array.isArray(jobs) || jobs.length === 0) {
      return jsonResponse({ error: 'Job not found' }, 404);
    }

    const job = jobs[0];

    if (job.status === 'paid') {
      return jsonResponse({ success: true, message: 'Payment already confirmed', job });
    }

    if (!job.payment_reference) {
      return jsonResponse({ error: 'No payment reference found for this job' }, 400);
    }

    if (!PAYSTACK_SECRET_KEY) {
      return jsonResponse({ error: 'PAYSTACK_SECRET_KEY is not configured on the server' }, 500);
    }

    const verifyResponse = await fetch(
      `https://api.paystack.co/transaction/verify/${encodeURIComponent(job.payment_reference)}`,
      {
        headers: {
          Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
      },
    );

    const verifyData = await verifyResponse.json() as PaystackVerifyResponse;
    if (!verifyResponse.ok || verifyData.status != true || verifyData.data?.status != 'success') {
      return jsonResponse({
        success: false,
        message: verifyData.message ?? 'Payment is not yet successful',
        paymentStatus: verifyData.data?.status ?? 'pending',
        job,
      }, 200);
    }

    const payment = verifyData.data;
    const paidAmount = Number(payment?.amount ?? 0) / 100;
    const metadata = payment?.metadata ?? {};

    const hasSubmittedEstimate =
      Number(job.estimate_total ?? 0) > 0 ||
      Number(job.estimate_materials_cost ?? 0) > 0 ||
      Number(job.estimate_labor_cost ?? 0) > 0;
    const isInitialOutcallBooking =
      (job.service_type ?? '') === 'outcall' && !hasSubmittedEstimate;

    const escrowAmount = isInitialOutcallBooking
      ? Math.min(paidAmount, 2000)
      : normalizeMoney(
          Number(metadata.escrow_amount ?? job.escrow_amount ?? 0),
          paidAmount,
        ) || paidAmount;

    const commissionAmount = isInitialOutcallBooking
      ? Math.max(paidAmount - escrowAmount, 0)
      : normalizeMoney(
          Number(metadata.commission_amount ?? job.commission_amount ?? 0),
          paidAmount,
        ) || Math.max(paidAmount - escrowAmount, 0);

    const updateJobResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/jobs?id=eq.${job.id}&status=in.(pending,accepted,estimate_accepted,estimate_submitted)`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          apikey: SUPABASE_SERVICE_KEY,
          Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
          Prefer: 'return=representation',
        },
        body: JSON.stringify({
          status: 'paid',
          ...(hasSubmittedEstimate ? { estimate_status: 'accepted' } : {}),
          amount_paid: paidAmount > 0 ? paidAmount : (job.amount_paid ?? 0),
          escrow_amount: escrowAmount > 0 ? escrowAmount : (job.escrow_amount ?? 0),
          commission_amount: commissionAmount,
          updated_at: new Date().toISOString(),
        }),
      },
    );

    if (!updateJobResponse.ok) {
      const text = await updateJobResponse.text();
      console.error('verifyTransaction failed to update job:', text);
      return jsonResponse({ error: 'Failed to update job status' }, 500);
    }

    const updatedJobs = await updateJobResponse.json();
    if (!Array.isArray(updatedJobs) || updatedJobs.length === 0) {
      const refreshedJobResponse = await fetch(`${SUPABASE_URL}/rest/v1/jobs?id=eq.${job.id}&select=*`, {
        headers: {
          apikey: SUPABASE_SERVICE_KEY,
          Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
      });

      if (!refreshedJobResponse.ok) {
        return jsonResponse({ error: 'Failed to reload job after verification' }, 500);
      }

      const refreshedJobs = await refreshedJobResponse.json();
      const refreshedJob = Array.isArray(refreshedJobs) && refreshedJobs.length > 0 ? refreshedJobs[0] : job;

      if (String(refreshedJob?.status ?? '').toLowerCase() === 'paid') {
        return jsonResponse({
          success: true,
          message: 'Payment already confirmed',
          job: refreshedJob,
        });
      }

      return jsonResponse({
        success: false,
        message: 'Payment verification succeeded but the job could not be finalized safely',
        paymentStatus: verifyData.data?.status ?? 'success',
        job: refreshedJob,
      }, 409);
    }

    const updatedJob = updatedJobs[0];

    const walletResponse = await fetch(`${SUPABASE_URL}/rest/v1/wallets?artisan_id=eq.${updatedJob.artisan_id}`, {
      headers: {
        apikey: SUPABASE_SERVICE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
    });

    if (walletResponse.ok) {
      const wallets = await walletResponse.json();
      if (Array.isArray(wallets) && wallets.length > 0) {
        const wallet = wallets[0];
        const materialAmount = Number(updatedJob.estimate_materials_cost ?? 0);
        const laborAmount = Number(updatedJob.estimate_labor_cost ?? 0);
        const estimateTotal = Number(updatedJob.estimate_total ?? 0);
        const hasEstimateSplit = materialAmount > 0 || laborAmount > 0;
        const isOutcallBooking = (updatedJob.service_type ?? '') == 'outcall' && !hasEstimateSplit;

        const walletAvailableDelta = isOutcallBooking
          ? 0
          : hasEstimateSplit
            ? materialAmount
            : (estimateTotal > 0 ? estimateTotal : escrowAmount);
        const walletPendingDelta = isOutcallBooking
          ? escrowAmount
          : hasEstimateSplit
            ? laborAmount
            : 0;
        const walletEarnedDelta = isOutcallBooking ? 0 : walletAvailableDelta + walletPendingDelta;

        await fetch(`${SUPABASE_URL}/rest/v1/wallets?id=eq.${wallet.id}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            apikey: SUPABASE_SERVICE_KEY,
            Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
          body: JSON.stringify({
            pending_balance: Number(wallet.pending_balance ?? 0) + walletPendingDelta,
            available_balance: Number(wallet.available_balance ?? 0) + walletAvailableDelta,
            total_earned: Number(wallet.total_earned ?? 0) + walletEarnedDelta,
            updated_at: new Date().toISOString(),
          }),
        });
      }
    }

    await fetch(`${SUPABASE_URL}/rest/v1/transactions?on_conflict=reference`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: SUPABASE_SERVICE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
        Prefer: 'resolution=ignore-duplicates',
      },
      body: JSON.stringify({
        reference: updatedJob.payment_reference,
        job_reference: updatedJob.job_reference,
        artisan_id: updatedJob.artisan_id,
        customer_email: payment?.customer?.email ?? updatedJob.customer_email,
        amount: paidAmount,
        fee: commissionAmount,
        net_amount: escrowAmount,
        type: 'escrow',
        status: 'success',
        paystack_response: payment,
      }),
    });

    return jsonResponse({
      success: true,
      message: 'Payment verified successfully',
      job: updatedJob,
    });
  } catch (error) {
    console.error('verifyTransaction error:', error);
    return jsonResponse({ error: error instanceof Error ? error.message : 'Internal server error' }, 500);
  }
});
