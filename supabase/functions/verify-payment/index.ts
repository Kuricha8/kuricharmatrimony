// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// @ts-ignore
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function calculateSubscription(planType: string = '') {
  const planLower = planType.toLowerCase();

  let monthsToAdd = 3;
  if (planLower.includes("diamond")) {
    monthsToAdd = 6;
  } else if (planLower.includes("platinum")) {
    monthsToAdd = 12;
  } else if (planLower.includes("lifetime") || planLower.includes("marriage")) {
    monthsToAdd = 120; // 10 years for Till Marriage
  }

  const expiresAt = new Date();
  expiresAt.setMonth(expiresAt.getMonth() + monthsToAdd);

  const isStealth = planLower.includes("stealth");

  let subTier = "tier1";
  if (planLower.includes("platinum") || planLower.includes("lifetime") || planLower.includes("marriage")) {
    subTier = "tier3";
  } else if (planLower.includes("diamond")) {
    subTier = "tier2";
  } else if (isStealth) {
    subTier = "stealth";
  }

  let planTier = subTier;
  if (isStealth) {
    planTier = "stealth";
  } else if (planLower.includes("lifetime") || planLower.includes("marriage")) {
    planTier = "platinum";
  }

  return { isStealth, subTier, planTier, expiresAt };
}

async function verifyCashfreeOrder(orderId: string, appId: string, secretKey: string, baseUrl: string) {
  console.log(`Verifying order ${orderId} at ${baseUrl}/${orderId}`);
  const cfResponse = await fetch(`${baseUrl}/${orderId}`, {
    method: "GET",
    headers: {
      "x-client-id": appId,
      "x-client-secret": secretKey,
      "x-api-version": "2023-08-01",
      "Content-Type": "application/json",
    },
  });

  const orderData = await cfResponse.json();
  console.log("Cashfree Verification Response:", orderData);

  const isPaid = orderData.order_status === "PAID" || orderData.order_status === "SUCCESS";
  return { isPaid, status: orderData.order_status };
}

async function updateUserProfile(supabase: any, userId: string, planType: string) {
  if (!userId || planType === "COIN_SLOT") {
    return;
  }

  const { isStealth, subTier, planTier, expiresAt } = calculateSubscription(planType);
  const expiresIso = expiresAt.toISOString();

  const { error: dbError } = await supabase
    .from("kurichiyar_profiles")
    .update({
      is_premium: true,
      subscription_plan: planType || "Premium",
      subscription_tier: subTier,
      plan_tier: planTier,
      plan_expires_at: expiresIso,
      subscription_end_date: expiresIso,
      is_stealth_active: isStealth,
      stealth_expiry_date: isStealth ? expiresIso : null,
    })
    .eq("id", userId);

  if (dbError) {
    console.error("Database update error on kurichiyar_profiles:", dbError);
  }
}

// @ts-ignore
serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { orderId, userId, planType } = await req.json();

    // @ts-ignore
    const appId = (Deno.env.get("CASHFREE_APP_ID") || "TEST11126249ee0a29c851378c6515fe94262111").trim();
    // @ts-ignore
    const secretKey = (Deno.env.get("CASHFREE_SECRET_KEY") || "cfsk_ma_test_56dcce3661b2d5519f688c23f01540c4_10bea3ee").trim();
    // @ts-ignore
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
    // @ts-ignore
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SUPABASE_ANON_KEY") || "";

    // @ts-ignore
    const environment = (Deno.env.get("CASHFREE_ENVIRONMENT") || "SANDBOX").trim();
    const isProduction = environment.toUpperCase() === "PROD" || environment.toUpperCase() === "PRODUCTION";
    const baseUrl = isProduction ? "https://api.cashfree.com/pg/orders" : "https://sandbox.cashfree.com/pg/orders";

    // 1. Fetch Order Status from Cashfree
    const { isPaid, status } = await verifyCashfreeOrder(orderId, appId, secretKey, baseUrl);

    if (!isPaid) {
      return new Response(
        JSON.stringify({ success: false, message: `Payment verification failed. Order status is ${status || 'not PAID'}.` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Update Supabase User Profile to Premium
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    await updateUserProfile(supabase, userId, planType);

    return new Response(
      JSON.stringify({ success: true, message: "Payment verified and subscription activated successfully!" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Verification Catch Error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

