declare const Deno: any;

const rawSupabaseUrl =
  (Deno.env.get('SUPABASE_URL') ?? Deno.env.get('DB_URL') ?? '').trim();
const SUPABASE_URL = rawSupabaseUrl.startsWith('http')
  ? rawSupabaseUrl
  : (Deno.env.get('SUPABASE_URL') ?? '').trim();
const SUPABASE_SERVICE_KEY = Deno.env.get('SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Content-Type': 'application/json',
};

interface WalletAccessRequest {
  action: 'login' | 'bundle' | 'saveBankDetails' | 'verifyWallet';
  artisanId?: string;
  email?: string;
  phone?: string;
  password?: string;
  bankName?: string;
  accountNumber?: string;
  accountName?: string;
}

async function rest(path: string, init: RequestInit = {}) {
  const headers = {
    apikey: SUPABASE_SERVICE_KEY,
    Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json',
    ...(init.headers || {}),
  };

  return fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers,
  });
}

async function authenticateArtisan(email?: string, phone?: string, password?: string) {
  if (!email || !phone || !password) return null;

  const res = await rest(
    `artisans?select=id,email,phone&email=eq.${encodeURIComponent(email)}&phone=eq.${encodeURIComponent(phone)}&password=eq.${encodeURIComponent(password)}&limit=1`,
  );

  if (!res.ok) return null;
  const rows = await res.json();
  if (!Array.isArray(rows) || rows.length == 0) return null;
  return rows[0] as { id: string; email: string; phone: string };
}

async function ensureWallet(artisanId: string) {
  const walletRes = await rest(`wallets?select=*&artisan_id=eq.${artisanId}&limit=1`);
  if (!walletRes.ok) {
    return { wallet: null, error: 'Failed to load wallet' };
  }

  const wallets = await walletRes.json();
  if (Array.isArray(wallets) && wallets.length > 0) {
    return { wallet: wallets[0], error: null };
  }

  const createRes = await rest('wallets', {
    method: 'POST',
    headers: {
      Prefer: 'return=representation',
    },
    body: JSON.stringify({
      artisan_id: artisanId,
      pending_balance: 0,
      available_balance: 0,
      total_earned: 0,
      total_withdrawn: 0,
    }),
  });

  if (!createRes.ok) {
    const txt = await createRes.text();
    return { wallet: null, error: `Failed to create wallet: ${txt}` };
  }

  const rawCreated = await createRes.text();
  const created = rawCreated ? JSON.parse(rawCreated) : null;
  return { wallet: Array.isArray(created) ? created[0] : created, error: null };
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS });

  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    return new Response(JSON.stringify({ success: false, error: 'Missing Supabase service configuration' }), {
      status: 500,
      headers: CORS_HEADERS,
    });
  }

  try {
    const body = (await req.json()) as WalletAccessRequest;
    const artisan = await authenticateArtisan(body.email, body.phone, body.password);

    if (!artisan) {
      return new Response(JSON.stringify({ success: false, error: 'Invalid credentials' }), {
        status: 401,
        headers: CORS_HEADERS,
      });
    }

    if (body.artisanId && body.artisanId !== artisan.id) {
      return new Response(JSON.stringify({ success: false, error: 'Unauthorized artisan access' }), {
        status: 403,
        headers: CORS_HEADERS,
      });
    }

    const artisanId = artisan.id;

    if (body.action === 'login' || body.action === 'bundle') {
      const { wallet, error } = await ensureWallet(artisanId);
      if (error) {
        return new Response(JSON.stringify({ success: false, error }), { status: 500, headers: CORS_HEADERS });
      }

      const jobsRes = await rest(`jobs?select=*&artisan_id=eq.${artisanId}&order=created_at.desc`);
      const txRes = await rest(`transactions?select=*&artisan_id=eq.${artisanId}&order=created_at.desc`);
      const jobs = jobsRes.ok ? await jobsRes.json() : [];
      const transactions = txRes.ok ? await txRes.json() : [];

      return new Response(
        JSON.stringify({
          success: true,
          artisan: { id: artisan.id, email: artisan.email, phone: artisan.phone },
          wallet,
          jobs,
          transactions,
        }),
        { status: 200, headers: CORS_HEADERS },
      );
    }

    if (body.action === 'saveBankDetails') {
      if (!body.bankName || !body.accountNumber || !body.accountName) {
        return new Response(JSON.stringify({ success: false, error: 'Missing bank details' }), {
          status: 400,
          headers: CORS_HEADERS,
        });
      }

      const { wallet, error } = await ensureWallet(artisanId);
      if (error || !wallet?.id) {
        return new Response(JSON.stringify({ success: false, error: error ?? 'Wallet not found' }), {
          status: 500,
          headers: CORS_HEADERS,
        });
      }

      const updateRes = await rest(`wallets?id=eq.${wallet.id}`, {
        method: 'PATCH',
        body: JSON.stringify({
          bank_name: body.bankName,
          account_number: body.accountNumber,
          account_name: body.accountName,
          updated_at: new Date().toISOString(),
        }),
      });

      if (!updateRes.ok) {
        const txt = await updateRes.text();
        return new Response(JSON.stringify({ success: false, error: `Failed to save bank details: ${txt}` }), {
          status: 500,
          headers: CORS_HEADERS,
        });
      }

      return new Response(JSON.stringify({ success: true, message: 'Bank details saved' }), {
        status: 200,
        headers: CORS_HEADERS,
      });
    }

    if (body.action === 'verifyWallet') {
      const { wallet, error } = await ensureWallet(artisanId);
      if (error || !wallet?.id) {
        return new Response(JSON.stringify({ success: false, error: error ?? 'Wallet not found' }), {
          status: 500,
          headers: CORS_HEADERS,
        });
      }

      if (!wallet.bank_name || !wallet.account_number || !wallet.account_name) {
        return new Response(JSON.stringify({ success: false, error: 'Missing bank details' }), {
          status: 400,
          headers: CORS_HEADERS,
        });
      }

      const verifyRes = await rest(`wallets?id=eq.${wallet.id}`, {
        method: 'PATCH',
        body: JSON.stringify({
          is_verified: true,
          updated_at: new Date().toISOString(),
        }),
      });

      if (!verifyRes.ok) {
        const txt = await verifyRes.text();
        return new Response(JSON.stringify({ success: false, error: `Verification failed: ${txt}` }), {
          status: 500,
          headers: CORS_HEADERS,
        });
      }

      return new Response(JSON.stringify({ success: true, message: 'Wallet verified' }), {
        status: 200,
        headers: CORS_HEADERS,
      });
    }

    return new Response(JSON.stringify({ success: false, error: 'Unsupported action' }), {
      status: 400,
      headers: CORS_HEADERS,
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: `Internal error: ${error instanceof Error ? error.message : String(error)}` }),
      {
        status: 500,
        headers: CORS_HEADERS,
      },
    );
  }
});
