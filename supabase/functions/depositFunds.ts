
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function withCors(response) {
  const headers = new Headers(response.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  headers.set("Access-Control-Allow-Headers", "authorization, content-type");
  return new Response(response.body, {
    status: response.status,
    headers,
  });
}

serve(async (req) => {


  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return withCors(new Response(null, { status: 204 }));
  }

  // Extract Authorization header
  const authHeader = req.headers.get("authorization") || req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return withCors(new Response(JSON.stringify({ success: false, error: "Missing or invalid authorization header" }), { status: 401 }));
  }
  const jwt = authHeader.replace("Bearer ", "").trim();


  const { artisanId, amount } = await req.json();
  if (!artisanId || !amount || amount <= 0) {
    return withCors(new Response(JSON.stringify({ success: false, error: "Invalid input" }), { status: 400 }));
  }

  // Get environment variables for Supabase (Deno only)
  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return withCors(new Response(JSON.stringify({ success: false, error: "Missing Supabase environment variables" }), { status: 500 }));
  }
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // Get wallet
  let { data: wallet, error: walletError } = await supabase
    .from("wallets")
    .select("available_balance, total_earned")
    .eq("artisan_id", artisanId)
    .maybeSingle();

  // If wallet doesn't exist, create it
  if (!wallet) {
    const { data: newWallet, error: createError } = await supabase
      .from("wallets")
      .insert({
        artisan_id: artisanId,
        available_balance: 0,
        total_earned: 0,
        total_withdrawn: 0,
        pending_balance: 0,
        updated_at: new Date().toISOString(),
      })
      .select()
      .maybeSingle();
    if (createError) {
      return withCors(new Response(JSON.stringify({ success: false, error: createError.message }), { status: 500 }));
    }
    if (!newWallet) {
      return withCors(new Response(JSON.stringify({ success: false, error: "Could not create wallet (unknown error)" }), { status: 500 }));
    }
    wallet = newWallet;
  }

  // Update wallet balance
  const { error: updateError } = await supabase
    .from("wallets")
    .update({
      available_balance: (wallet.available_balance || 0) + amount,
      total_earned: (wallet.total_earned || 0) + amount,
      updated_at: new Date().toISOString(),
    })
    .eq("artisan_id", artisanId);

  if (updateError) {
    return withCors(new Response(JSON.stringify({ success: false, error: updateError.message }), { status: 500 }));
  }

  return withCors(new Response(JSON.stringify({ success: true }), { status: 200 }));
});