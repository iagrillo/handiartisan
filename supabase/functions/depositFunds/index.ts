import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const debug: any = {};
  try {
    const { artisanId, amount } = await req.json();
    debug.input = { artisanId, amount };
    if (!artisanId || !amount || amount <= 0) {
      debug.error = "Invalid input";
      return new Response(JSON.stringify({ success: false, error: "Invalid input", debug }), { status: 400 });
    }

    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    debug.env = {
      SUPABASE_URL: Deno.env.get("SUPABASE_URL"),
      SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ? "set" : "missing"
    };

    // Get wallet
    let { data: wallet, error: walletError } = await supabase
      .from("wallets")
      .select("available_balance, total_earned")
      .eq("artisan_id", artisanId)
      .maybeSingle();
    debug.walletLookup = { wallet, walletError };

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
      debug.walletCreate = { newWallet, createError };
      if (createError || !newWallet) {
        debug.error = "Could not create wallet";
        return new Response(JSON.stringify({ success: false, error: "Could not create wallet", debug }), { status: 500 });
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
    debug.walletUpdate = { updateError };

    if (updateError) {
      debug.error = updateError.message;
      return new Response(JSON.stringify({ success: false, error: updateError.message, debug }), { status: 500 });
    }

    return new Response(JSON.stringify({ success: true, debug }), { status: 200 });
  } catch (e) {
    debug.exception = e?.toString?.() || e;
    return new Response(JSON.stringify({ success: false, error: "Exception thrown", debug }), { status: 500 });
  }
});