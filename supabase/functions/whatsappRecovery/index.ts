export {};

const rawSupabaseUrl =
  (Deno.env.get('SUPABASE_URL') ?? Deno.env.get('DB_URL') ?? '').trim();
const SUPABASE_URL = rawSupabaseUrl.startsWith('http')
  ? rawSupabaseUrl
  : (Deno.env.get('SUPABASE_URL') ?? '').trim();
const SUPABASE_SERVICE_KEY =
  Deno.env.get('SERVICE_ROLE_KEY') ??
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
  '';
const BUSINESS_NUMBER = normalizePhone(
  Deno.env.get('HANDIHUB_WHATSAPP_BUSINESS_NUMBER') ?? '2349139106323',
);
const VERIFY_TOKEN =
  (Deno.env.get('HANDIHUB_WHATSAPP_WEBHOOK_VERIFY_TOKEN') ??
          'handihub_whatsapp_verify_2026')
      .trim() || 'handihub_whatsapp_verify_2026';
const META_PHONE_NUMBER_ID =
  (Deno.env.get('HANDIHUB_WHATSAPP_PHONE_NUMBER_ID') ??
          Deno.env.get('WHATSAPP_PHONE_NUMBER_ID') ??
          '')
      .trim();
const META_ACCESS_TOKEN =
  (Deno.env.get('HANDIHUB_WHATSAPP_ACCESS_TOKEN') ??
          Deno.env.get('WHATSAPP_ACCESS_TOKEN') ??
          '')
      .trim();
const DEFAULT_REDIRECT =
  (Deno.env.get('HANDIHUB_PASSWORD_RECOVERY_URL') ??
          'handihubglobal://login-callback/')
      .trim() || 'handihubglobal://login-callback/';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Content-Type': 'application/json',
};

type RecoveryRow = {
  id: string;
  email: string;
  phone: string;
  token: string;
  status: 'pending' | 'verified' | 'used' | 'expired';
  recovery_link?: string | null;
  expires_at: string;
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: CORS_HEADERS,
  });
}

function twimlResponse(message: string, status = 200) {
  const safeMessage = escapeXml(message);
  return new Response(
    `<?xml version="1.0" encoding="UTF-8"?><Response><Message>${safeMessage}</Message></Response>`,
    {
      status,
      headers: {
        'Content-Type': 'text/xml; charset=utf-8',
      },
    },
  );
}

function escapeXml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
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

async function authAdmin(path: string, init: RequestInit = {}) {
  const headers = {
    apikey: SUPABASE_SERVICE_KEY,
    Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json',
    ...(init.headers || {}),
  };

  return fetch(`${SUPABASE_URL}/auth/v1/${path}`, {
    ...init,
    headers,
  });
}

function normalizePhone(input: string | null | undefined) {
  let digits = (input ?? '')
    .replace(/^whatsapp:/i, '')
    .replace(/\D/g, '');

  if (digits.startsWith('0') && digits.length === 11) {
    digits = `234${digits.substring(1)}`;
  } else if (digits.length === 10) {
    digits = `234$digits`;
  }

  return digits;
}

function encodeValue(value: string) {
  return encodeURIComponent(value);
}

function generateToken() {
  const random = Math.floor(Math.random() * 9000) + 1000;
  return `HB-${random}`;
}

function buildWhatsAppUrl(token: string) {
  const message = `Reset my HandiHub password ID: ${token}`;
  return `https://wa.me/${BUSINESS_NUMBER}?text=${encodeURIComponent(message)}`;
}

async function sendMetaWhatsAppReply(to: string, message: string) {
  if (!META_PHONE_NUMBER_ID || !META_ACCESS_TOKEN || !to) {
    return false;
  }

  const response = await fetch(
    `https://graph.facebook.com/v22.0/${META_PHONE_NUMBER_ID}/messages`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${META_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to,
        type: 'text',
        text: {
          body: message,
        },
      }),
    },
  );

  if (!response.ok) {
    console.error('Failed to send Meta WhatsApp reply:', await response.text());
    return false;
  }

  return true;
}

async function verifyRegisteredAccount(email: string, phone: string) {
  const artisanResponse = await rest(
    `artisans?select=id,email,phone&email=eq.${encodeValue(email)}&limit=10`,
  );
  const storeResponse = await rest(
    `stores?select=id,email,phone_number,whatsapp_number,contact&email=eq.${encodeValue(email)}&limit=10`,
  );

  if (!artisanResponse.ok && !storeResponse.ok) {
    throw new Error('Unable to verify the registered account right now.');
  }

  const artisanRows = artisanResponse.ok ? await artisanResponse.json() : [];
  const storeRows = storeResponse.ok ? await storeResponse.json() : [];

  const artisanMatch = Array.isArray(artisanRows)
    ? artisanRows.some(
        (row) => normalizePhone(row?.phone?.toString?.() ?? '') === phone,
      )
    : false;
  const storeMatch = Array.isArray(storeRows)
    ? storeRows.some(
        (row) =>
          normalizePhone(
            row?.phone_number?.toString?.() ??
              row?.whatsapp_number?.toString?.() ??
              row?.contact?.toString?.() ??
              '',
          ) === phone,
      )
    : false;

  return artisanMatch || storeMatch;
}

async function expirePendingRequests(email: string, phone: string) {
  await rest(
    `whatsapp_password_recoveries?email=eq.${encodeValue(email)}&phone=eq.${encodeValue(phone)}&status=eq.pending`,
    {
      method: 'PATCH',
      body: JSON.stringify({
        status: 'expired',
      }),
    },
  );
}

async function createRecoveryRequest(
  email: string,
  phone: string,
  token: string,
  expiresAt: string,
) {
  const response = await rest('whatsapp_password_recoveries', {
    method: 'POST',
    headers: {
      Prefer: 'return=representation',
    },
    body: JSON.stringify({
      email,
      phone,
      token,
      status: 'pending',
      expires_at: expiresAt,
    }),
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(
      details.includes('relation')
        ? 'WhatsApp recovery storage is missing. Run whatsapp_password_recovery_schema.sql first.'
        : `Unable to create a WhatsApp recovery request: ${details}`,
    );
  }

  const created = await response.json();
  return Array.isArray(created) ? created[0] : created;
}

async function findRecoveryRequest(
  token: string,
  email?: string,
  phone?: string,
): Promise<RecoveryRow | null> {
  const filters = [
    `token=eq.${encodeValue(token)}`,
    email ? `email=eq.${encodeValue(email)}` : null,
    phone ? `phone=eq.${encodeValue(phone)}` : null,
    'order=created_at.desc',
    'limit=1',
  ].filter(Boolean);

  const response = await rest(
    `whatsapp_password_recoveries?select=*&${filters.join('&')}`,
  );

  if (!response.ok) {
    const details = await response.text();
    throw new Error(
      details.includes('relation')
        ? 'WhatsApp recovery storage is missing. Run whatsapp_password_recovery_schema.sql first.'
        : `Unable to load the WhatsApp recovery request: ${details}`,
    );
  }

  const rows = await response.json();
  if (!Array.isArray(rows) || rows.length === 0) {
    return null;
  }

  return rows[0] as RecoveryRow;
}

async function updateRecoveryRequest(id: string, values: Record<string, unknown>) {
  const response = await rest(`whatsapp_password_recoveries?id=eq.${id}`, {
    method: 'PATCH',
    body: JSON.stringify(values),
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`Failed to update the WhatsApp recovery request: ${details}`);
  }
}

async function generateRecoveryLink(email: string, redirectTo: string) {
  const response = await authAdmin('admin/generate_link', {
    method: 'POST',
    body: JSON.stringify({
      type: 'recovery',
      email,
      redirect_to: redirectTo,
      options: {
        redirectTo,
      },
    }),
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`Unable to generate the recovery link: ${details}`);
  }

  const data = await response.json();
  const properties = data?.properties ?? {};
  const actionLink =
    properties?.action_link ??
    properties?.actionLink ??
    data?.action_link ??
    data?.actionLink ??
    '';

  if (!actionLink) {
    throw new Error('The recovery link was generated but no action link was returned.');
  }

  return actionLink as string;
}

function parseWebhookPayload(rawBody: string, contentType: string) {
  if (contentType.includes('application/x-www-form-urlencoded')) {
    const params = new URLSearchParams(rawBody);
    return {
      from: normalizePhone(params.get('From') ?? ''),
      body: (params.get('Body') ?? '').trim(),
      provider: 'twilio',
    };
  }

  let parsed: Record<string, unknown> = {};
  try {
    parsed = JSON.parse(rawBody);
  } catch (_) {
    parsed = {};
  }

  if (Array.isArray((parsed as { entry?: unknown[] }).entry)) {
    for (const entry of (parsed as { entry?: unknown[] }).entry ?? []) {
      const changes = Array.isArray((entry as { changes?: unknown[] })?.changes)
        ? ((entry as { changes?: unknown[] }).changes ?? [])
        : [];
      for (const change of changes) {
        const value = (change as { value?: Record<string, unknown> })?.value ?? {};
        const messages = Array.isArray(value.messages as unknown[])
          ? (value.messages as Array<Record<string, unknown>>)
          : [];
        for (const message of messages) {
          const text = (message.text as { body?: string } | undefined)?.body ??
            (message.button as { text?: string } | undefined)?.text ??
            ((message.interactive as { button_reply?: { title?: string } } | undefined)
                    ?.button_reply?.title ??
                '');
          return {
            from: normalizePhone(String(message.from ?? '')),
            body: String(text).trim(),
            provider: 'meta',
          };
        }
      }
    }
  }

  return {
    from: normalizePhone(
      String(parsed.from ?? parsed.From ?? parsed.phone ?? ''),
    ),
    body: String(parsed.body ?? parsed.Body ?? parsed.message ?? ''),
    provider: String(parsed.provider ?? 'generic').toLowerCase(),
  };
}

async function processInboundRecoveryMessage(from: string, body: string) {
  const tokenMatch = body.toUpperCase().match(/HB-\d{4,8}/);

  if (!from || !tokenMatch) {
    return {
      ok: false,
      status: 200,
      message:
        'HandiHub could not verify that request. Send the exact recovery message from your registered number and try again.',
    };
  }

  const token = tokenMatch[0];
  const recovery = await findRecoveryRequest(token);
  if (!recovery) {
    return {
      ok: false,
      status: 200,
      message:
        'That recovery ID was not found. Start the WhatsApp password reset flow again in the HandiHub app.',
    };
  }

  const senderMatchesRequest = recovery.phone === from;
  const senderMatchesAccount = senderMatchesRequest ||
    await verifyRegisteredAccount(recovery.email, from);

  if (!senderMatchesAccount) {
    return {
      ok: false,
      status: 200,
      message:
        'This phone number does not match the registered HandiHub account for that recovery request.',
    };
  }

  if (new Date(recovery.expires_at).getTime() < Date.now()) {
    await updateRecoveryRequest(recovery.id, { status: 'expired' });
    return {
      ok: false,
      status: 200,
      message:
        'That HandiHub recovery ID has expired. Request a new one in the app and try again.',
    };
  }

  const link = recovery.recovery_link ||
    await generateRecoveryLink(recovery.email, DEFAULT_REDIRECT);

  const replyMessage =
    `HandiHub verified your request. Use this secure reset link now: ${link}`;
  const sentViaMeta = await sendMetaWhatsAppReply(from, replyMessage);

  await updateRecoveryRequest(recovery.id, {
    status: 'verified',
    inbound_phone: from,
    inbound_message: body,
    recovery_link: link,
    verified_at: new Date().toISOString(),
    replied_at: new Date().toISOString(),
  });

  return {
    ok: true,
    status: 200,
    whatsappDelivered: sentViaMeta,
    message: sentViaMeta
        ? 'HandiHub verified your request. A secure reset link has been sent to your WhatsApp chat.'
        : replyMessage,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    return jsonResponse(
      {
        success: false,
        error: 'Missing Supabase service configuration for WhatsApp recovery.',
      },
      500,
    );
  }

  try {
    if (req.method === 'GET') {
      const url = new URL(req.url);
      const mode = url.searchParams.get('hub.mode') ?? '';
      const token = url.searchParams.get('hub.verify_token') ?? '';
      const challenge = url.searchParams.get('hub.challenge') ?? '';

      if (mode === 'subscribe' && token === VERIFY_TOKEN) {
        return new Response(challenge, {
          status: 200,
          headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        });
      }

      return new Response('Verification token mismatch', { status: 403 });
    }

    if (req.method !== 'POST') {
      return jsonResponse({ success: false, error: 'Method not allowed.' }, 405);
    }

    const contentType = req.headers.get('content-type')?.toLowerCase() ?? '';
    const rawBody = await req.text();

    if (contentType.includes('application/x-www-form-urlencoded')) {
      const inbound = parseWebhookPayload(rawBody, contentType);
      const result = await processInboundRecoveryMessage(
        inbound.from,
        inbound.body,
      );
      return twimlResponse(result.message, result.status);
    }

    let body: Record<string, unknown> = {};
    if (rawBody.trim().length > 0) {
      try {
        body = JSON.parse(rawBody) as Record<string, unknown>;
      } catch (_) {
        body = {};
      }
    }

    if (
      body.object === 'whatsapp_business_account' ||
      Array.isArray((body as { entry?: unknown[] }).entry)
    ) {
      const inbound = parseWebhookPayload(rawBody, contentType);
      const result = await processInboundRecoveryMessage(
        inbound.from,
        inbound.body,
      );
      return jsonResponse(
        {
          success: result.ok,
          message: result.message,
        },
        result.status,
      );
    }
    const action = String(body?.action ?? '').trim().toLowerCase();

    if (action === 'start') {
      const email = String(body?.email ?? '').trim().toLowerCase();
      const phone = normalizePhone(String(body?.phone ?? ''));

      if (!email || !email.includes('@')) {
        return jsonResponse({ success: false, error: 'Enter a valid email address.' }, 400);
      }
      if (phone.length < 10) {
        return jsonResponse(
          { success: false, error: 'Enter your registered WhatsApp number.' },
          400,
        );
      }

      const accountMatch = await verifyRegisteredAccount(email, phone);
      if (!accountMatch) {
        return jsonResponse(
          {
            success: false,
            error: 'The WhatsApp number does not match the registered account for that email.',
          },
          403,
        );
      }

      await expirePendingRequests(email, phone);

      let token = generateToken();
      let existing = await findRecoveryRequest(token);
      while (existing != null) {
        token = generateToken();
        existing = await findRecoveryRequest(token);
      }

      const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
      await createRecoveryRequest(email, phone, token, expiresAt);

      return jsonResponse({
        success: true,
        token,
        expiresAt,
        businessNumber: BUSINESS_NUMBER,
        whatsappUrl: buildWhatsAppUrl(token),
        message:
          'Send the pre-filled WhatsApp message from your registered number. We will verify it and reply with a secure reset link.',
      });
    }

    if (action === 'status') {
      const email = String(body?.email ?? '').trim().toLowerCase();
      const phone = normalizePhone(String(body?.phone ?? ''));
      const token = String(body?.token ?? '').trim().toUpperCase();
      const redirectTo =
        String(body?.redirectTo ?? '').trim() || DEFAULT_REDIRECT;

      if (!email || !phone || !token) {
        return jsonResponse(
          {
            success: false,
            error: 'Email, phone number, and recovery ID are required.',
          },
          400,
        );
      }

      const recovery = await findRecoveryRequest(token, email, phone);
      if (!recovery) {
        return jsonResponse({
          success: true,
          verified: false,
          status: 'missing',
          message: 'No WhatsApp recovery request was found. Start again from the app.',
        });
      }

      if (new Date(recovery.expires_at).getTime() < Date.now() &&
          recovery.status === 'pending') {
        await updateRecoveryRequest(recovery.id, { status: 'expired' });
        return jsonResponse({
          success: true,
          verified: false,
          status: 'expired',
          message: 'This WhatsApp recovery token has expired. Request a new one.',
        });
      }

      if (recovery.status === 'verified' || recovery.status === 'used') {
        const link = recovery.recovery_link ||
          await generateRecoveryLink(recovery.email, redirectTo);
        if (!recovery.recovery_link) {
          await updateRecoveryRequest(recovery.id, {
            recovery_link: link,
            replied_at: new Date().toISOString(),
          });
        }

        const whatsappDelivered =
          META_PHONE_NUMBER_ID.length > 0 && META_ACCESS_TOKEN.length > 0;

        return jsonResponse({
          success: true,
          verified: true,
          status: recovery.status,
          delivery: whatsappDelivered ? 'whatsappLink' : 'otp',
          whatsappDelivered,
          message: whatsappDelivered
              ? 'Verified. A secure reset link has been sent to your WhatsApp chat.'
              : 'Verified. WhatsApp delivery is not fully configured yet, so we will continue with email recovery in the app.',
        });
      }

      return jsonResponse({
        success: true,
        verified: false,
        status: recovery.status,
        message:
          'We are still waiting for your WhatsApp message from the registered number. Send it, then tap Check Status again.',
      });
    }

    return jsonResponse({ success: false, error: 'Unsupported action.' }, 400);
  } catch (error) {
    console.error('whatsappRecovery error:', error);
    return jsonResponse(
      {
        success: false,
        error: error instanceof Error ? error.message : 'WhatsApp recovery failed.',
      },
      500,
    );
  }
});
