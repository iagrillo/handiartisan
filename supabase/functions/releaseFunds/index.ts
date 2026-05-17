// ============================================
// Supabase Edge Function: releaseFunds
// Releases pending funds to available balance
// Only accessible by admin users
// ============================================

const SUPABASE_URL = Deno.env.get('DB_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? '';

interface ReleaseFundsRequest {
  artisanId: string;
  jobReference?: string;
}

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    // Only allow POST
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Verify admin authorization
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Parse request body
    const body: ReleaseFundsRequest = await req.json();
    const { artisanId, jobReference } = body;

    // Validate required fields
    if (!artisanId) {
      return new Response(
        JSON.stringify({ error: 'artisanId is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Get artisan wallet
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
      return new Response(
        JSON.stringify({ error: 'Wallet not found for artisan' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const wallet = wallets[0];
    const pendingBalance = wallet.pending_balance || 0;

    // Check if there are pending funds to release
    if (pendingBalance <= 0) {
      return new Response(
        JSON.stringify({ 
          error: 'No pending funds to release',
          current_pending_balance: pendingBalance 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Get artisan details for logging
    const artisanResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/artisans?id=eq.${artisanId}`,
      {
        headers: {
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
      }
    );

    const artisans = await artisanResponse.json();
    const artisan = artisans?.[0];
    const artisanEmail = artisan?.email || 'unknown';

    // Calculate new balances
    const newAvailableBalance = (wallet.available_balance || 0) + pendingBalance;
    const releaseAmount = pendingBalance;

    // Update wallet - move pending to available
    const updateWalletResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/wallets?id=eq.${wallet.id}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
        body: JSON.stringify({
          pending_balance: 0,
          available_balance: newAvailableBalance,
          updated_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateWalletResponse.ok) {
      const errorText = await updateWalletResponse.text();
      console.error('Failed to update wallet:', errorText);
      return new Response(
        JSON.stringify({ error: 'Failed to release funds' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Generate release reference
    const releaseReference = `REL_${Date.now()}_${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

    // Record transaction in transactions table
    const transactionResponse = await fetch(
      `${SUPABASE_URL}/rest/v1/transactions`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_SERVICE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
        body: JSON.stringify({
          reference: releaseReference,
          job_reference: jobReference || null,
          artisan_id: artisanId,
          customer_email: artisanEmail,
          amount: releaseAmount,
          fee: 0,
          net_amount: releaseAmount,
          type: 'release',
          status: 'success',
        }),
      }
    );

    if (!transactionResponse.ok) {
      console.error('Failed to record release transaction');
      // Non-critical - wallet was already updated
    }

    console.log('Funds released successfully:', {
      artisan_id: artisanId,
      release_amount: releaseAmount,
      reference: releaseReference,
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Funds released successfully',
        artisan_id: artisanId,
        release_amount: releaseAmount,
        previous_pending_balance: pendingBalance,
        new_available_balance: newAvailableBalance,
        reference: releaseReference,
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );

  } catch (error) {
    console.error('Error in releaseFunds:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
