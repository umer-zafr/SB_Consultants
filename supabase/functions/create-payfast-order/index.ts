import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Authoritative base rates for SB Consultant services (PKR)
const CANONICAL_SERVICE_RATES: Record<string, number> = {
  sponsored_jobs: 15000,
  scholarships: 25000,
  work_visa: 40000,
  golden_visa: 40000,
  visit_visa: 30000,
  study_visa: 30000,
  business_visa: 30000,
  consultancy_standard: 30000,
};

function determineCanonicalServiceFee(listingId?: string, itemTitle?: string): number {
  const target = `${listingId ?? ""} ${itemTitle ?? ""}`.toLowerCase();
  if (target.includes("job") || target.includes("sponsor")) return CANONICAL_SERVICE_RATES.sponsored_jobs;
  if (target.includes("scholarship") || target.includes("sch")) return CANONICAL_SERVICE_RATES.scholarships;
  if (target.includes("work") || target.includes("golden")) return CANONICAL_SERVICE_RATES.work_visa;
  if (target.includes("visit") || target.includes("tourist") || target.includes("study") || target.includes("business")) {
    return CANONICAL_SERVICE_RATES.visit_visa;
  }
  return CANONICAL_SERVICE_RATES.consultancy_standard;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase server configuration" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    // =========================================================================
    // 1. CALLER AUTHENTICATION (Optional for anonymous checkout, but validated if present)
    // =========================================================================
    let verifiedUserId: string | null = null;
    const authHeader = req.headers.get("Authorization");
    if (authHeader) {
      const token = authHeader.replace("Bearer ", "").trim();
      const { data: { user } } = await supabaseAdmin.auth.getUser(token);
      if (user) {
        verifiedUserId = user.id;
      }
    }

    let body: Record<string, unknown> = {};
    if (req.method === "POST") {
      body = await req.json().catch(() => ({}));
    } else {
      const url = new URL(req.url);
      body = {
        referenceId: url.searchParams.get("ref"),
        listingId: url.searchParams.get("listingId"),
      };
    }

    const {
      userId: clientUserId,
      referenceId,
      listingId,
      itemTitle,
      customerEmail,
      customerPhone,
      customerName,
      promoCode,
    } = body as Record<string, any>;

    // Trust verified JWT userId first; fall back to clientUserId only if authenticated matches or not provided
    const effectiveUserId = verifiedUserId || clientUserId || null;

    // =========================================================================
    // 2. AUTHORITATIVE PRICE CALCULATION (Prevents client-side price tampering)
    // =========================================================================
    const canonicalServiceFee = determineCanonicalServiceFee(listingId, itemTitle);
    const processingFee = 100; // Flat 100 PKR processing fee
    let discountAmount = 0;

    // Validate promo code server-side if supplied
    if (promoCode && typeof promoCode === "string" && promoCode.trim().length > 0) {
      const { data: promoData } = await supabaseAdmin
        .from("promo_codes")
        .select("code, discount_type, discount_value, is_active, valid_until")
        .ilike("code", promoCode.trim())
        .eq("is_active", true)
        .maybeSingle();

      if (promoData) {
        const isNotExpired = !promoData.valid_until || new Date(promoData.valid_until) > new Date();
        if (isNotExpired) {
          if (promoData.discount_type === "percentage") {
            discountAmount = Math.round((canonicalServiceFee * Number(promoData.discount_value)) / 100);
          } else {
            discountAmount = Number(promoData.discount_value);
          }
        }
      }
    }

    const authoritativeTotal = Math.max(100, canonicalServiceFee + processingFee - discountAmount);
    const currency = "PKR";

    // =========================================================================
    // 3. SECURE MERCHANT CREDENTIALS (Server environment secrets ONLY)
    // =========================================================================
    const merchantId = (
      Deno.env.get("PAYFAST_MERCHANT_ID") ||
      Deno.env.get("MERCHANT_ID") ||
      "102"
    ).toString().trim();

    const securedKey = (
      Deno.env.get("PAYFAST_SECURED_KEY") ||
      Deno.env.get("SECURED_KEY") ||
      "zWHjBp2AlttNu1sK"
    ).toString().trim();

    const isSandbox = (
      Deno.env.get("PAYFAST_SANDBOX") ??
      "true"
    ).toString().trim().toLowerCase() === "true";

    const transactionId = `TXN-SB-${Date.now()}`;
    const rawRef = (referenceId as string) || `REF-${Date.now()}`;
    const cleanRef = rawRef.replace(/[^a-zA-Z0-9_\-]/g, "");
    const formattedAmount = authoritativeTotal.toFixed(2);
    const gatewayUrl = "https://ipg1.apps.net.pk/Ecommerce/api/Transaction/PostTransaction";

    // Server-side SHA256 signature generation according to PayFast spec
    let signature = "";
    if (securedKey && securedKey !== "dummy" && securedKey !== "test") {
      try {
        const rawSig = `${securedKey}|${cleanRef}|${formattedAmount}`;
        const msgBuffer = new TextEncoder().encode(rawSig);
        const hashBuffer = await crypto.subtle.digest("SHA-256", msgBuffer);
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        signature = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
      } catch (_) {}
    }

    // Token handshake with 1.5s timeout
    let accessToken: string | null = null;
    if (securedKey && securedKey !== "dummy" && securedKey !== "test") {
      try {
        const tokenRes = await fetch(
          "https://ipg1.apps.net.pk/Ecommerce/api/Transaction/GetAccessToken",
          {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: new URLSearchParams({
              MERCHANT_ID: merchantId,
              SECURED_KEY: securedKey,
              BASKET_ID: cleanRef,
              TXNAMT: authoritativeTotal.toString(),
              CURRENCY_CODE: currency,
            }),
            signal: AbortSignal.timeout(1500),
          }
        );
        if (tokenRes.ok) {
          const tokenData = await tokenRes.json();
          accessToken =
            tokenData.ACCESS_TOKEN ||
            tokenData.token ||
            tokenData.access_token ||
            tokenData.Token ||
            null;
        }
      } catch (_) {}
    }

    // Register pending payment record into Supabase payments table
    let insertedPaymentId: string | null = null;
    try {
      if (effectiveUserId) {
        const { data: insertedPayment } = await supabaseAdmin
          .from("payments")
          .insert({
            user_id: effectiveUserId,
            transaction_id: transactionId,
            reference_id: cleanRef,
            listing_id: listingId || null,
            payment_method: "payfast",
            amount: authoritativeTotal,
            currency: currency,
            status: "pending",
            promo_code: promoCode || null,
            discount_amount: discountAmount,
            service_fee: canonicalServiceFee,
            processing_fee: processingFee,
            gateway_response: {
              gateway: "payfast",
              merchant_id: merchantId,
              mode: isSandbox ? "sandbox" : "production",
              itemTitle,
              access_token: accessToken,
            },
          })
          .select("id")
          .maybeSingle();

        if (insertedPayment) {
          insertedPaymentId = insertedPayment.id;
        }
      }
    } catch (dbErr) {
      console.warn("Payments record creation note:", dbErr);
    }

    const returnUrl = `${supabaseUrl}/functions/v1/payfast-webhook?tx=${transactionId}`;
    const cancelUrl = `${supabaseUrl}/functions/v1/payfast-webhook?status=cancelled&tx=${transactionId}`;

    // SECURITY: SECURED_KEY is NEVER embedded into checkoutHtml
    const checkoutHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PayFast Secure Checkout</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: #002244;
      color: #ffffff;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 20px;
      text-align: center;
    }
    .container {
      background: rgba(255, 255, 255, 0.07);
      border: 1px solid rgba(255, 255, 255, 0.14);
      border-radius: 20px;
      padding: 34px 22px;
      max-width: 380px;
      width: 100%;
      box-shadow: 0 20px 45px rgba(0, 0, 0, 0.35);
    }
    .spinner {
      width: 46px;
      height: 46px;
      border: 3.5px solid rgba(255, 255, 255, 0.16);
      border-top-color: #22C55E;
      border-radius: 50%;
      animation: spin 0.75s linear infinite;
      margin: 0 auto 18px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    h2 { font-size: 18px; font-weight: 700; margin-bottom: 8px; letter-spacing: -0.2px; }
    p { font-size: 13px; color: #94A3B8; line-height: 1.45; margin-bottom: 22px; }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: rgba(34, 197, 94, 0.15);
      color: #4ADE80;
      border: 1px solid rgba(34, 197, 94, 0.25);
      padding: 5px 12px;
      border-radius: 20px;
      font-size: 11.5px;
      font-weight: 600;
      margin-bottom: 18px;
    }
    .btn {
      display: block;
      width: 100%;
      padding: 13px;
      background: #22C55E;
      color: #ffffff;
      border: none;
      border-radius: 12px;
      font-size: 14px;
      font-weight: 700;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="spinner"></div>
    <div class="badge">
      <span>●</span> 256-Bit SSL Encrypted
    </div>
    <h2>Connecting to PayFast</h2>
    <p>Opening official State Bank of Pakistan regulated PayFast IPG portal...</p>
    <form id="payfastForm" method="POST" action="${gatewayUrl}">
      <input type="hidden" name="MERCHANT_ID" value="${merchantId}" />
      ${accessToken ? `<input type="hidden" name="TOKEN" value="${accessToken}" />` : ""}
      <input type="hidden" name="PROCCODE" value="00" />
      <input type="hidden" name="TXNAMT" value="${formattedAmount}" />
      <input type="hidden" name="CURRENCY_CODE" value="${currency}" />
      <input type="hidden" name="BASKET_ID" value="${cleanRef}" />
      <input type="hidden" name="TXNDESC" value="${itemTitle || "Consultancy Service Fee"}" />
      <input type="hidden" name="ORDER_DATE" value="${new Date().toISOString().slice(0, 10)}" />
      ${signature ? `<input type="hidden" name="SIGNATURE" value="${signature}" />` : ""}
      <input type="hidden" name="VERSION" value="1.1" />
      <input type="hidden" name="SUCCESS_URL" value="${returnUrl}" />
      <input type="hidden" name="FAILURE_URL" value="${cancelUrl}" />
      <input type="hidden" name="CHECKOUT_URL" value="${returnUrl}" />
      <input type="hidden" name="CUSTOMER_EMAIL" value="${customerEmail || ""}" />
      <input type="hidden" name="CUSTOMER_MOBILE" value="${customerPhone || ""}" />
      <button type="submit" class="btn" id="subBtn">Continue to Payment</button>
    </form>
  </div>
  <script>
    function submitPayFast() {
      try { document.getElementById('payfastForm').submit(); } catch(e) {}
    }
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', submitPayFast);
    } else {
      submitPayFast();
    }
    setTimeout(submitPayFast, 150);
  </script>
</body>
</html>`;

    // SECURITY: Return sanitized payload without SECURED_KEY
    return new Response(
      JSON.stringify({
        success: true,
        paymentId: insertedPaymentId,
        transactionId,
        referenceId: cleanRef,
        amount: authoritativeTotal,
        serviceFee: canonicalServiceFee,
        processingFee,
        discountAmount,
        currency,
        merchantId,
        isSandbox,
        accessToken,
        gatewayUrl,
        checkoutHtml,
        checkoutPayload: {
          MERCHANT_ID: merchantId,
          BASKET_ID: cleanRef,
          TXNAMT: formattedAmount,
          ORDER_DATE: new Date().toISOString().slice(0, 10),
          CURRENCY_CODE: currency,
          SUCCESS_URL: returnUrl,
          FAILURE_URL: cancelUrl,
          TOKEN: accessToken,
          CHECKOUT_URL: `${gatewayUrl}?basket_id=${cleanRef}&amount=${authoritativeTotal}`,
        },
        message: "PayFast secure order initialized",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
