// ============================================
// Supabase Edge Function: createSubaccount
// Creates Paystack subaccount for artisan payouts & commissions
// ============================================

const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

// Default commission rate (10%)
const DEFAULT_COMMISSION_RATE = 10;

interface CreateSubaccountRequest {
  artisanId: string;
  bankName: string;
  accountNumber: string;
  accountName: string;
  bankCode?: string;
  businessName?: string;
  email?: string;
  phone?: string;
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

    // Parse request body
    const body: CreateSubaccountRequest = await req.json();
    const { 
      artisanId, 
      bankName, 
      accountNumber, 
      accountName, 
      bankCode, 
      businessName,
      email,
      phone 
    } = body;

    // Validate required fields
    if (!artisanId || !bankName || !accountNumber || !accountName) {
      return new Response(
        JSON.stringify({ 
          error: 'artisanId, bankName, accountNumber, and accountName are required' 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Validate account number (10 digits for Nigeria)
    if (accountNumber.length !== 10 || !/^\d+$/.test(accountNumber)) {
      return new Response(
        JSON.stringify({ error: 'Invalid account number. Must be 10 digits.' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Get bank code from bank name if not provided
    const resolvedBankCode = bankCode || await resolveBankCode(bankName);
    
    if (!resolvedBankCode) {
      return new Response(
        JSON.stringify({ error: 'Invalid bank name. Please provide a valid Nigerian bank.' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Verify account number with Paystack (optional but recommended)
    const accountVerifyResponse = await fetch(
      `https://api.paystack.co/bank/resolve?account_number=${accountNumber}&bank_code=${resolvedBankCode}`,
      {
        headers: {
          'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
        },
      }
    );

    const accountVerifyData = await accountVerifyResponse.json();
    
    if (!accountVerifyData.status) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid account details',
          details: accountVerifyData.message 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Verify account name matches
    if (accountName.toLowerCase() !== accountVerifyData.data.account_name.toLowerCase()) {
      return new Response(
        JSON.stringify({ 
          error: 'Account name does not match records',
          expected: accountVerifyData.data.account_name,
          provided: accountName
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Get artisan details
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
    
    if (!artisans || artisans.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Artisan not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const artisan = artisans[0];

    // Create Paystack subaccount
    const subaccountResponse = await fetch('https://api.paystack.co/subaccount', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
      },
      body: JSON.stringify({
        business_name: businessName || artisan.business_name || artisan.full_name,
        bank_code: resolvedBankCode,
        account_number: accountNumber,
        percentage_charge: DEFAULT_COMMISSION_RATE,
        description: `HandiHub artisan: ${artisan.full_name}`,
        primary_contact_email: email || artisan.email,
        primary_contact_phone: phone || artisan.phone,
      }),
    });

    const subaccountData = await subaccountResponse.json();

    if (!subaccountData.status) {
      return new Response(
        JSON.stringify({ 
          error: 'Failed to create subaccount',
          details: subaccountData.message 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const subaccountCode = subaccountData.data.subaccount_code;

    // Update wallet with subaccount details
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

    if (wallets && wallets.length > 0) {
      // Update existing wallet
      await fetch(
        `${SUPABASE_URL}/rest/v1/wallets?id=eq.${wallets[0].id}`,
        {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
          body: JSON.stringify({
            bank_name: bankName,
            account_number: accountNumber,
            account_name: accountName,
            bank_code: resolvedBankCode,
            paystack_recipient_code: subaccountCode,
            is_verified: true,
            updated_at: new Date().toISOString(),
          }),
        }
      );
    } else {
      // Create new wallet
      await fetch(
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
            bank_name: bankName,
            account_number: accountNumber,
            account_name: accountName,
            bank_code: resolvedBankCode,
            paystack_recipient_code: subaccountCode,
            is_verified: true,
            pending_balance: 0,
            available_balance: 0,
            total_earned: 0,
            total_withdrawn: 0,
          }),
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Subaccount created successfully',
        subaccount_code: subaccountCode,
        bank_name: bankName,
        account_number: accountNumber,
        account_name: accountName,
        commission_rate: DEFAULT_COMMISSION_RATE,
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
    console.error('Error in createSubaccount:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});

function normalizeBankName(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]/g, ' ').replace(/\s+/g, ' ').trim();
}

async function resolveBankCode(bankName: string): Promise<string | null> {
  const bankCodes: Record<string, string> = {
    'abbey mortgage bank': '801',
    'access bank': '044',
    'access': '044',
    'alat by wema': '035',
    'citibank': '023',
    'ecobank': '050',
    'fidelity bank': '070',
    'first bank of nigeria': '011',
    'first bank': '011',
    'fcmb': '214',
    'first city monument bank': '214',
    'guaranty trust bank': '058',
    'gtbank': '058',
    'gtb': '058',
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
    'union bank of nigeria': '032',
    'union bank': '032',
    'united bank for africa': '033',
    'uba': '033',
    'unity bank': '215',
    'wema bank': '035',
    'zenith bank': '057',
  };

  const normalizedBankName = normalizeBankName(bankName);
  const localCode = bankCodes[normalizedBankName] ??
    Object.entries(bankCodes).find(([name]) =>
      name.includes(normalizedBankName) || normalizedBankName.includes(name),
    )?.[1];
  if (localCode) return localCode;

  try {
    const bankListResponse = await fetch('https://api.paystack.co/bank?country=nigeria&perPage=100', {
      headers: {
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
      },
    });

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
  } catch (_) {
    // fall through to null if Paystack list could not be loaded.
  }

  return null;
}
