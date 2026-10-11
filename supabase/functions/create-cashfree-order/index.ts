// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS Preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { amount, userId, userName, userEmail, userPhone, orderId, planName } = body;

    // 1. Fetch credentials from Deno/Supabase environment
    // @ts-ignore
    const appId = (Deno.env.get("CASHFREE_APP_ID") || "TEST11126249ee0a29c851378c6515fe94262111").trim();
    // @ts-ignore
    const secretKey = (Deno.env.get("CASHFREE_SECRET_KEY") || "cfsk_ma_test_56dcce3661b2d5519f688c23f01540c4_10bea3ee").trim();
    // @ts-ignore
    const environment = (Deno.env.get("CASHFREE_ENVIRONMENT") || "SANDBOX").trim().toUpperCase();

    const isProduction = environment === "PROD" || environment === "PRODUCTION";
    const baseUrl = isProduction
      ? "https://api.cashfree.com/pg/orders"
      : "https://sandbox.cashfree.com/pg/orders";

    // 2. Validate and format inputs
    let cleanPhone = String(userPhone || "9999999999").replace(/\D/g, "");
    if (cleanPhone.length > 10) cleanPhone = cleanPhone.slice(-10);
    if (cleanPhone.length < 10) cleanPhone = "9999999999";

    const validOrderId = String(orderId || `order_${Date.now()}`)
      .replace(/[^a-zA-Z0-9_-]/g, "_")
      .slice(0, 45);

    const validAmount = Number(Number(amount || 1).toFixed(2));
    if (validAmount <= 0) {
      throw new Error("Order amount must be greater than zero.");
    }

    const customerId = String(userId || `cust_${Date.now()}`)
      .replace(/[^a-zA-Z0-9_-]/g, "_")
      .slice(0, 45);
    const customerName = String(userName || "Customer").trim() || "Customer";
    const customerEmail = String(userEmail || "user@kurichiyarmatrimony.in").trim();

    const payload = {
      order_id: validOrderId,
      order_amount: validAmount,
      order_currency: "INR",
      order_note: planName ? `Plan: ${planName}` : "Subscription Payment",
      customer_details: {
        customer_id: customerId,
        customer_phone: cleanPhone,
        customer_email: customerEmail,
        customer_name: customerName,
      },
      order_meta: {
        return_url: "https://kuricharmatrimony.vercel.app/#/payment-status?order_id={order_id}",
      },
    };

    console.log(`[create-cashfree-order] Requesting ${baseUrl} (${isProduction ? "PRODUCTION" : "SANDBOX"})`);
    console.log(`[create-cashfree-order] Payload:`, JSON.stringify(payload));

    // 3. Call Cashfree PG API v2023-08-01
    const response = await fetch(baseUrl, {
      method: "POST",
      headers: {
        "x-client-id": appId,
        "x-client-secret": secretKey,
        "x-api-version": "2023-08-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json();
    console.log(`[create-cashfree-order] Cashfree Response (${response.status}):`, JSON.stringify(data));

    // 4. Handle errors from Cashfree API
    if (!response.ok || !data.payment_session_id) {
      const errorMsg = data.message || data.error || `Cashfree API rejected request with HTTP ${response.status}`;
      return new Response(
        JSON.stringify({
          success: false,
          error: errorMsg,
          cashfree_error: data,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 5. Success: return session info
    return new Response(
      JSON.stringify({
        success: true,
        order_id: data.order_id || validOrderId,
        payment_session_id: data.payment_session_id,
        order_status: data.order_status,
        environment: isProduction ? "PRODUCTION" : "SANDBOX",
        checkout_url: isProduction
          ? `https://api.cashfree.com/pg/view/sessions/${data.payment_session_id}`
          : `https://sandbox.cashfree.com/pg/view/sessions/${data.payment_session_id}`,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error: any) {
    console.error("[create-cashfree-order] Internal error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message || "Failed to create Cashfree order" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
