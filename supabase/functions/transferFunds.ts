import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { fromArtisanId, toArtisanId, amount } = await req.json();
  if (!fromArtisanId || !toArtisanId || !amount || amount <= 0) {
    return new Response(JSON.stringify({ success: false, error: "Invalid input" }), { status: 400 });
  }

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Get sender wallet
  const { data: fromWallet, error: fromError } = await supabase
    .from("wallets")
    .select("available_balance")
    .eq("artisan_id", fromArtisanId)
    .maybeSingle();

  if (fromError || !fromWallet || fromWallet.available_balance < amount) {
    return new Response(JSON.stringify({ success: false, error: "Insufficient balance" }), { status: 400 });
  }

  // Get recipient wallet
  const { data: toWallet, error: toError } = await supabase
    .from("wallets")
    .select("available_balance")
    .eq("artisan_id", toArtisanId)
    .maybeSingle();

  if (toError || !toWallet) {
    return new Response(JSON.stringify({ success: false, error: "Recipient not found" }), { status: 400 });
  }

  // Deduct from sender, add to recipient
  const { error: updateError } = await supabase
    .from("wallets")
    .upsert([
      { artisan_id: fromArtisanId, available_balance: fromWallet.available_balance - amount },
      { artisan_id: toArtisanId, available_balance: toWallet.available_balance + amount }
    ]);

  if (updateError) {
    return new Response(JSON.stringify({ success: false, error: updateError.message }), { status: 500 });
  }

  return new Response(JSON.stringify({ success: true }), { status: 200 });
});