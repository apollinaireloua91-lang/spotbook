// Edge Function: send-pos-receipt
//
// Sends a digital receipt (email) for a completed POS transaction. The Pro
// (authenticated via JWT) must own the transaction. Marks
// `pos_transactions.receipt_sent = true` + `receipt_sent_at = now()` on
// success.
//
// Request body (JSON):
//   {
//     transaction_id: string (uuid)   // required, owned by the caller
//     email:          string | null   // optional; if null, we reuse
//                                     // pos_transactions.customer_email
//     phone:          string | null   // optional, reserved for future SMS
//   }
//
// Response 200:  { success: true, email_id?: string }
// Response 4xx:  { error: '<code>' }
//
// Notes:
//   - SMS receipts are not wired yet (no SMS provider configured in the
//     project). The `phone` parameter is accepted and stored but the
//     function returns 200 with `email_sent: false, sms_sent: false` if
//     only a phone was provided. See doc.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  isValidEmail,
  isValidUuid,
  jsonResponse,
  sanitizeText,
  securityHeadersFor,
} from "../_shared/security.ts";
import { buildEmail } from "../_shared/email_templates.ts";

const FROM = "Spotbook <noreply@getspotbook.app>";

function frenchDate(iso: string): string {
  // "20 avril 2026, 15 h 42" style, explicit French formatting.
  try {
    const d = new Date(iso);
    const fmt = new Intl.DateTimeFormat("fr-CA", {
      day: "2-digit",
      month: "long",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "America/Toronto",
    });
    return fmt.format(d);
  } catch {
    return iso;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    let body: Record<string, unknown>;
    try {
      body = (await req.json()) as Record<string, unknown>;
    } catch {
      return jsonResponse({ error: "invalid_json" }, 400, undefined, req);
    }

    const transactionId = String(body.transaction_id ?? "");
    if (!isValidUuid(transactionId)) {
      return jsonResponse(
        { error: "transaction_id must be a valid UUID" },
        400,
        undefined,
        req,
      );
    }

    const providedEmail = typeof body.email === "string" ? body.email.trim() : "";
    const providedPhone = typeof body.phone === "string" ? body.phone.trim() : "";

    // Service-role client for the privileged read/update.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: tx, error: txErr } = await supabase
      .from("pos_transactions")
      .select(`
        id, pro_id, status, currency, created_at,
        amount_subtotal_cents, tip_cents, tps_cents, tvq_cents,
        amount_total_cents, payment_method_brand, payment_method_last4,
        customer_email, receipt_sent
      `)
      .eq("id", transactionId)
      .maybeSingle();

    if (txErr) {
      console.error("pos_transactions read error:", txErr);
      return jsonResponse({ error: "internal_error" }, 500, undefined, req);
    }
    if (!tx) {
      return jsonResponse({ error: "transaction_not_found" }, 404, undefined, req);
    }
    if (tx.pro_id !== user.id) {
      return jsonResponse({ error: "forbidden" }, 403, undefined, req);
    }
    if (tx.status !== "succeeded" && tx.status !== "partially_refunded") {
      return jsonResponse(
        { error: "transaction_not_succeeded" },
        409,
        undefined,
        req,
      );
    }

    // Pull the Pro's display name + optional tax numbers.
    const { data: proProfile } = await supabase
      .from("profiles_pro")
      .select("business_name, tax_number_tps, tax_number_tvq")
      .eq("id", user.id)
      .maybeSingle();

    const { data: proUser } = await supabase
      .from("users")
      .select("display_name, full_name")
      .eq("id", user.id)
      .maybeSingle();

    const proName =
      (proProfile?.business_name as string | undefined) ??
      (proUser?.display_name as string | undefined) ??
      (proUser?.full_name as string | undefined) ??
      "Spotbook Pro";

    // Resolve recipient email.
    const targetEmail = providedEmail || (tx.customer_email as string | null) || "";
    if (!targetEmail) {
      if (providedPhone) {
        // SMS channel not configured — acknowledge without sending.
        return jsonResponse(
          {
            success: true,
            email_sent: false,
            sms_sent: false,
            note: "sms_channel_not_configured",
          },
          200,
          undefined,
          req,
        );
      }
      return jsonResponse(
        { error: "no_recipient_provided" },
        400,
        undefined,
        req,
      );
    }
    if (!isValidEmail(targetEmail)) {
      return jsonResponse({ error: "invalid_email" }, 400, undefined, req);
    }

    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (!resendKey) {
      console.error("RESEND_API_KEY not configured");
      return jsonResponse(
        { error: "email_service_unavailable" },
        503,
        undefined,
        req,
      );
    }

    const { subject, html } = buildEmail("pos_receipt", {
      proName: sanitizeText(proName),
      date: frenchDate(tx.created_at as string),
      subtotalCents: tx.amount_subtotal_cents as number,
      tipCents: tx.tip_cents as number,
      tpsCents: tx.tps_cents as number,
      tvqCents: tx.tvq_cents as number,
      totalCents: tx.amount_total_cents as number,
      cardBrand: (tx.payment_method_brand as string | null) ?? undefined,
      cardLast4: (tx.payment_method_last4 as string | null) ?? undefined,
      taxNumberTps:
        (proProfile?.tax_number_tps as string | null) ?? undefined,
      taxNumberTvq:
        (proProfile?.tax_number_tvq as string | null) ?? undefined,
      transactionId: tx.id as string,
    });

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM,
        to: [targetEmail],
        subject,
        html,
      }),
    });

    if (!resendRes.ok) {
      const errBody = await resendRes.text();
      console.error("Resend API error:", resendRes.status, errBody);
      return jsonResponse(
        { error: "email_send_failed", detail: resendRes.status },
        502,
        undefined,
        req,
      );
    }

    const resendData = await resendRes.json();

    const { error: updateErr } = await supabase
      .from("pos_transactions")
      .update({
        receipt_sent: true,
        receipt_sent_at: new Date().toISOString(),
        // Backfill the email on the row if it wasn't set at creation.
        customer_email: targetEmail,
      })
      .eq("id", tx.id);

    if (updateErr) {
      // Receipt already went out — don't fail the whole request, but log.
      console.error(
        JSON.stringify({
          level: "warn",
          code: "POS_RECEIPT_FLAG_UPDATE_FAILED",
          transactionId: tx.id,
          dbError: updateErr.message,
        }),
      );
    }

    return jsonResponse(
      {
        success: true,
        email_sent: true,
        email_id: resendData.id,
        sms_sent: false,
      },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("send-pos-receipt error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
