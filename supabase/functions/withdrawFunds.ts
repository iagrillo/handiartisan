import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { artisanId, amount, bankName, accountNumber, accountName } = await req.json();
  if (!artisanId || !amount || amount <= 0 || !bankName || !accountNumber || !accountName) {
    return new Response(JSON.stringify({ success: false, error: "Invalid input" }), { status: 400 });
  }

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Check balance
  const { data: wallet, error: walletError } = await supabase
    .from("wallets")
    .select("available_balance, total_withdrawn")
    .eq("artisan_id", artisanId)
    .maybeSingle();

  if (walletError || !wallet || wallet.available_balance < amount) {
    return new Response(JSON.stringify({ success: false, error: "Insufficient balance" }), { status: 400 });
  }

  // Deduct balance
  const { error } = await supabase
    .from("wallets")
    .update({
      available_balance: wallet.available_balance - amount,
      total_withdrawn: (wallet.total_withdrawn || 0) + amount,
      updated_at: new Date().toISOString(),
    })
    .eq("artisan_id", artisanId);

  if (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), { status: 500 });
  }

  // Optionally, log withdrawal request in a separate table for manual/automated payout processing

  return new Response(JSON.stringify({ success: true }), { status: 200 });
});