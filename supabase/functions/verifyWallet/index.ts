// ============================================
// Supabase Edge Function: verifyWallet
// Verifies artisan's bank account using Paystack API
// ============================================

const rawSupabaseUrl =
  (Deno.env.get('SUPABASE_URL') ?? Deno.env.get('DB_URL') ?? '').trim();
const SUPABASE_URL = rawSupabaseUrl.startsWith('http')
  ? rawSupabaseUrl
  : (Deno.env.get('SUPABASE_URL') ?? '').trim();
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? '';

// Common Paystack/Nigerian bank aliases. We still query Paystack's live bank
// list to support as many payout/verification banks as possible.
const COMMON_BANK_CODES: Record<string, string> = {
  'abbey mortgage bank': '801',
  'access bank': '044',
  'access bank plc': '044',
  'alat by wema': '035',
  'citibank': '023',
  'ecobank': '050',
  'ecobank nigeria': '050',
  'fidelity bank': '070',
  'first bank': '011',
  'first bank of nigeria': '011',
  'fcmb': '214',
  'first city monument bank': '214',
  'guaranty trust bank': '058',
  'gtbank': '058',
  'gtb': '058',
  'guaranty trust bank plc': '058',
  'heritage bank': '030',
  'jaiz bank': '301',
  'keystone bank': '082',
  'lotus bank': '303',
  'polaris bank': '076',
  'providus bank': '101',
  'stanbic ibtc bank': '221',
  'standard chartered bank': '068',
  'sterling bank': '232',
  'suntrust bank': '100',
  'taj bank': '302',
  'titan trust bank': '102',
  'union bank': '032',
  'union bank of nigeria': '032',
  'united bank for africa': '033',
  'uba': '033',
  'unity bank': '215',
  'wema bank': '035',
  'zenith bank': '057',
};

function normalizeBankName(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]/g, ' ').replace(/\s+/g, ' ').trim();
}

async function resolveBankCode(bankName: string): Promise<string | null> {
  const normalizedBankName = normalizeBankName(bankName);

  const localCode = COMMON_BANK_CODES[normalizedBankName] ??
    Object.entries(COMMON_BANK_CODES).find(([name]) =>
      name.includes(normalizedBankName) || normalizedBankName.includes(name),
    )?.[1];
  if (localCode) return localCode;

  try {
    const bankListResponse = await fetch(
      'https://api.paystack.co/bank?country=nigeria&perPage=100',
      {
        headers: {
          'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
      },
    );

    const bankListData = await bankListResponse.json();
    if (bankListResponse.ok && bankListData?.status && Array.isArray(bankListData.data)) {
      const matchedBank = bankListData.data.find((bank: { name?: string; code?: string; active?: boolean }) => {
        if (!bank?.code || bank?.active === false) return false;
        const paystackName = normalizeBankName(bank.name ?? '');
        return paystackName == normalizedBankName ||
          paystackName.includes(normalizedBankName) ||
          normalizedBankName.includes(paystackName);
      });

      if (matchedBank?.code) {
        return String(matchedBank.code);
      }
    }
  } catch (error) {
    console.error('Failed to fetch Paystack bank list:', error);
  }

  return null;
}

interface VerifyWalletRequest {
  artisanId: string;
  bankName: string;
  accountNumber: string;
  accountName: string;
}

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    // Only allow POST
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ success: false, error: 'Method not allowed' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Check Paystack key
    console.log('PAYSTACK_SECRET_KEY present:', PAYSTACK_SECRET_KEY ? 'Yes' : 'No');
    if (!PAYSTACK_SECRET_KEY) {
      return new Response(
        JSON.stringify({ success: false, error: 'Paystack secret not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    const body: VerifyWalletRequest = await req.json();
    const { artisanId, bankName, accountNumber, accountName } = body;
    
    console.log('verifyWallet request:', { artisanId, bankName, accountNumber, accountName: accountName?.substring(0, 2) + '***' });

    // Validate required fields
    if (!artisanId || !bankName || !accountNumber || !accountName) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing fields: artisanId, bankName, accountNumber, and accountName are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Validate account number length
    if (accountNumber.length !== 10) {
      return new Response(
        JSON.stringify({ success: false, error: 'Account number must be 10 digits' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Get bank code from bank name using local aliases + Paystack's live bank list.
    const bankCode = await resolveBankCode(bankName);
    if (!bankCode) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid bank name. Please provide a valid Paystack-supported Nigerian bank name.' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    console.log('Verifying bank account:', { bankName, bankCode, accountNumber, accountName });

    // Call Paystack's bank account verification API
    const paystackUrl = `https://api.paystack.co/bank/resolve?account_number=${accountNumber}&bank_code=${bankCode}`;
    
    const paystackResponse = await fetch(paystackUrl, {
      headers: {
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    const paystackData = await paystackResponse.json();

    console.log('Paystack response:', paystackData);

    if (!paystackResponse.ok || !paystackData.status) {
      console.error('Paystack verification failed:', paystackData);
      return new Response(
        JSON.stringify({ success: false, error: 'Verification failed: Could not verify bank account details' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Check if account name matches
    const paystackAccountName = paystackData.data?.account_name?.toLowerCase().trim();
    const providedAccountName = accountName.toLowerCase().trim();
    
    // Allow for minor variations in name matching
    const namesMatch = paystackAccountName === providedAccountName || 
                       paystackAccountName?.includes(providedAccountName) ||
                       providedAccountName?.includes(paystackAccountName);

    if (!namesMatch) {
      console.error('Account name mismatch:', { paystackAccountName, providedAccountName });
      return new Response(
        JSON.stringify({ success: false, error: 'Account name does not match. Please check your account details.' }),
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
    
    let wallet;
    if (!wallets || wallets.length === 0) {
      // Create wallet if it doesn't exist
      const createWalletResponse = await fetch(
        `${SUPABASE_URL}/rest/v1/wallets`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
          body: JSON.stringify({
            artisan_id: artisanId,
            pending_balance: 0,
            available_balance: 0,
            total_earned: 0,
            total_withdrawn: 0,
            is_verified: true,
            bank_name: bankName,
            account_number: accountNumber,
            account_name: accountName,
          }),
        }
      );

      if (!createWalletResponse.ok) {
        const errorText = await createWalletResponse.text();
        console.error('Failed to create wallet:', errorText);
        return new Response(
          JSON.stringify({ success: false, error: 'Failed to create wallet' }),
          { status: 500, headers: { 'Content-Type': 'application/json' } }
        );
      }

      console.log('Wallet created and verified successfully for artisan:', artisanId);

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Wallet verified and created successfully',
          artisanId: artisanId,
          bankName: bankName,
          accountNumber: accountNumber,
          accountName: accountName,
        }),
        {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    wallet = wallets[0];

    // Update wallet with verified bank details
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
          is_verified: true,
          bank_name: bankName,
          account_number: accountNumber,
          account_name: accountName,
          updated_at: new Date().toISOString(),
        }),
      }
    );

    if (!updateWalletResponse.ok) {
      const errorText = await updateWalletResponse.text();
      console.error('Failed to update wallet:', errorText);
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to update wallet verification status' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    console.log('Wallet verified successfully for artisan:', artisanId);

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Wallet verified successfully',
        artisanId: artisanId,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
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
    console.error('Error in verifyWallet:', error);
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
