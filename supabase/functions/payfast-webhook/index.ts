import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase configuration" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

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

    const url = new URL(req.url);
    const queryTx = url.searchParams.get("tx") || url.searchParams.get("transaction_id");
    const queryBasket = url.searchParams.get("basket_id") || url.searchParams.get("ref");
    const queryStatus = (url.searchParams.get("status") || "").toLowerCase();

    let payload: Record<string, any> = {};
    if (req.method === "POST") {
      try {
        payload = await req.json();
      } catch (_) {
        const formData = await req.formData();
        formData.forEach((val, key) => {
          payload[key] = val;
        });
      }
    }

    const txId = (payload.transaction_id || payload.tx || queryTx || "").toString().trim();
    const basketId = (payload.basket_id || payload.reference_id || queryBasket || "").toString().trim();

    // Locate matching pending payment in the database
    let paymentRecord: any = null;
    if (txId) {
      const { data } = await supabaseAdmin.from("payments").select("*").eq("transaction_id", txId).maybeSingle();
      paymentRecord = data;
    }
    if (!paymentRecord && basketId) {
      const { data } = await supabaseAdmin.from("payments").select("*").eq("reference_id", basketId).maybeSingle();
      paymentRecord = data;
    }

    // =========================================================================
    // SECURITY ENFORCEMENT: SERVER-TO-SERVER VERIFICATION
    // Browser GET requests MUST NEVER directly mark payment as 'completed'.
    // We must query PayFast's official API to verify that the transaction was paid!
    // =========================================================================
    let isOfficiallyVerified = false;
    let verificationMethod = "unverified";
    let verificationDetails: Record<string, any> = {};

    if (paymentRecord && paymentRecord.status !== "completed") {
      const effectiveBasket = paymentRecord.reference_id || basketId;

      // 1. Check PayFast Transaction Status via official Gateway API
      if (effectiveBasket && securedKey && securedKey !== "dummy") {
        try {
          const statusCheckRes = await fetch(
            "https://ipg1.apps.net.pk/Ecommerce/api/Transaction/GetTransactionStatus",
            {
              method: "POST",
              headers: { "Content-Type": "application/x-www-form-urlencoded" },
              body: new URLSearchParams({
                MERCHANT_ID: merchantId,
                SECURED_KEY: securedKey,
                BASKET_ID: effectiveBasket,
              }),
              signal: AbortSignal.timeout(3000),
            }
          );

          if (statusCheckRes.ok) {
            const statusData = await statusCheckRes.json();
            verificationDetails = statusData;

            const respCode = (
              statusData.Response_Code ||
              statusData.response_code ||
              statusData.ResponseCode ||
              statusData.err_code ||
              ""
            ).toString().trim();

            const txStatus = (
              statusData.transaction_status ||
              statusData.status ||
              statusData.Status ||
              ""
            ).toString().toLowerCase().trim();

            if (respCode === "000" || respCode === "00" || respCode === "0" || txStatus === "paid" || txStatus === "approved" || txStatus === "completed") {
              isOfficiallyVerified = true;
              verificationMethod = "payfast_api_inquiry";
            }
          }
        } catch (e) {
          console.warn("Notice: PayFast Status inquiry timeout or network unreachable:", e);
        }
      }

      // 2. Direct Server-to-Server IPN POST webhook validation (with signature check)
      if (!isOfficiallyVerified && req.method === "POST") {
        const postErrCode = (payload.err_code || payload.ResponseCode || "").toString().trim();
        const postSig = (payload.SIGNATURE || payload.signature || "").toString().trim();

        if (postSig && securedKey) {
          // Verify SHA256 signature according to PayFast specification
          try {
            const expectedRaw = `${securedKey}|${effectiveBasket}|${Number(paymentRecord.amount).toFixed(2)}`;
            const hashBuffer = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(expectedRaw));
            const calculatedSig = Array.from(new Uint8Array(hashBuffer)).map((b) => b.toString(16).padStart(2, "0")).join("");

            if (calculatedSig.toLowerCase() === postSig.toLowerCase() && (postErrCode === "000" || postErrCode === "00")) {
              isOfficiallyVerified = true;
              verificationMethod = "ipn_signature_hash";
            }
          } catch (_) {}
        }
      }

      // 3. If verified, transition payment state atomically and idempotently
      if (isOfficiallyVerified) {
        const { data: updatedPayment } = await supabaseAdmin
          .from("payments")
          .update({
            status: "completed",
            gateway_response: {
              ...paymentRecord.gateway_response,
              verified_by: verificationMethod,
              verification_details: verificationDetails,
              verified_at: new Date().toISOString(),
            },
            updated_at: new Date().toISOString(),
          })
          .eq("id", paymentRecord.id)
          .select()
          .single();

        // Idempotently activate directory unlock if applicable
        if (updatedPayment) {
          const listingId = (updatedPayment.listing_id ?? "").toLowerCase();
          if (listingId.includes("job") || listingId.includes("scholarship")) {
            const directoryType = listingId.includes("scholarship") ? "scholarships" : "sponsored_jobs";
            await supabaseAdmin.from("user_directory_unlocks").upsert(
              {
                user_id: updatedPayment.user_id,
                directory_type: directoryType,
                payment_id: updatedPayment.id,
                is_active: true,
              },
              { onConflict: "user_id, directory_type" }
            );
          }
        }
      } else if (queryStatus === "cancelled" || queryStatus === "cancel") {
        await supabaseAdmin
          .from("payments")
          .update({
            status: "failed",
            updated_at: new Date().toISOString(),
          })
          .eq("id", paymentRecord.id);
      }
    }

    const currentStatus = paymentRecord ? (isOfficiallyVerified ? "completed" : paymentRecord.status) : (isOfficiallyVerified ? "completed" : "pending");

    // =========================================================================
    // RESPONSES: User HTML redirect page or Server JSON response
    // =========================================================================
    if (req.method === "GET") {
      const isSuccess = currentStatus === "completed";
      const isCancelled = currentStatus === "failed" || queryStatus === "cancelled";

      const html = `<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Status - SB Consultants</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #F7F9FF; text-align: center; }
    .card { background: white; padding: 32px; border-radius: 20px; box-shadow: 0 10px 30px rgba(27,58,92,0.08); max-width: 360px; width: 90%; }
    .icon { font-size: 56px; margin-bottom: 16px; }
    h2 { color: #171C21; margin: 0 0 8px; font-size: 20px; }
    p { color: #5A626A; font-size: 14px; margin: 0 0 24px; line-height: 1.45; }
    .btn { display: inline-block; background: #002444; color: white; padding: 12px 24px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 14px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${isSuccess ? "✅" : (isCancelled ? "❌" : "⏳")}</div>
    <h2>${isSuccess ? "Payment Confirmed" : (isCancelled ? "Payment Cancelled" : "Processing Verification")}</h2>
    <p>${isSuccess ? "Your payment has been securely confirmed by PayFast. Please return to the app." : (isCancelled ? "The payment was cancelled. No charges were made." : "Awaiting authoritative settlement confirmation from PayFast.")}</p>
    <a href="sbconsultants://payment-callback?status=${currentStatus}&tx=${txId || ""}" class="btn">Return to App</a>
  </div>
</body>
</html>`;

      return new Response(html, {
        headers: { "Content-Type": "text/html" },
        status: 200,
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        transaction_id: txId,
        status: currentStatus,
        verified: isOfficiallyVerified,
        method: verificationMethod,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ success: false, error: (err as Error).message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
