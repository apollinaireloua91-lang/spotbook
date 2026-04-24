// Edge Function: refund-pos-transaction
//
// Issues a full or partial refund for a POS transaction. The Pro
// (authenticated via JWT) must own the transaction. The corresponding
// application_fee portion is automatically reversed via
// `refund_application_fee: true`, so Spotbook's commission is returned
// proportionally to the refunded amount.
//
// Request body (JSON):
//   {
//     transaction_id: string (uuid)   // required, owned by the caller
//     amount_cents:   number | null   // optional; if null or >= remaining,
//                                     // refunds the full remaining amount
//     reason:         string | null   // optional, one of
//                                     // 'requested_by_customer' (default)
//                                     // | 'duplicate' | 'fraudulent'
//   }
//
// Response 200:
//   {
//     success: true,
//     refund_id: string,
//     refunded_amount_cents: number,
//     status: 'refunded' | 'partially_refunded'
//   }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

const VALID_REASONS = new Set([
  "requested_by_customer",
  "duplicate",
  "fraudulent",
]);

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

    const rawAmount = body.amount_cents;
    let requestedAmountCents: number | null = null;
    if (rawAmount !== null && rawAmount !== undefined) {
      const n = Number(rawAmount);
      if (!Number.isInteger(n) || n <= 0) {
        return jsonResponse(
          { error: "amount_cents must be a positive integer or null" },
          400,
          undefined,
          req,
        );
      }
      requestedAmountCents = n;
    }

    const rawReason =
      typeof body.reason === "string" && body.reason.length > 0
        ? body.reason
        : "requested_by_customer";
    if (!VALID_REASONS.has(rawReason)) {
      return jsonResponse(
        {
          error: `reason must be one of: ${[...VALID_REASONS].join(", ")}`,
        },
        400,
        undefined,
        req,
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: tx, error: txErr } = await supabase
      .from("pos_transactions")
      .select(
        "id, pro_id, stripe_payment_intent_id, amount_total_cents, refunded_amount_cents, status",
      )
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
        { error: "transaction_not_refundable", current_status: tx.status },
        409,
        undefined,
        req,
      );
    }

    const totalCents = tx.amount_total_cents as number;
    const alreadyRefunded = tx.refunded_amount_cents as number;
    const remaining = totalCents - alreadyRefunded;
    if (remaining <= 0) {
      return jsonResponse(
        { error: "already_fully_refunded" },
        409,
        undefined,
        req,
      );
    }

    // Clamp to remaining — a caller asking for more than what's left gets
    // the rest, not an error. Mirrors Stripe's own behaviour.
    const refundCents = requestedAmountCents && requestedAmountCents < remaining
      ? requestedAmountCents
      : remaining;

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const refund = await stripe.refunds.create(
      {
        payment_intent: tx.stripe_payment_intent_id as string,
        amount: refundCents,
        reason: rawReason as Stripe.RefundCreateParams.Reason,
        // Reverse the proportional application_fee so Spotbook returns its
        // cut alongside the Pro's share.
        refund_application_fee: true,
        reverse_transfer: true,
        metadata: {
          spotbook_pos_transaction_id: tx.id as string,
          initiated_by_pro_id: user.id,
        },
      },
      { idempotencyKey: `refund-${tx.id}-${alreadyRefunded + refundCents}` },
    );

    const newRefunded = alreadyRefunded + refundCents;
    const newStatus = newRefunded >= totalCents ? "refunded" : "partially_refunded";

    const { error: updateErr } = await supabase
      .from("pos_transactions")
      .update({
        refunded_amount_cents: newRefunded,
        status: newStatus,
      })
      .eq("id", tx.id);

    if (updateErr) {
      // Stripe already refunded — don't fail the request, but log so the
      // state can be reconciled via the Stripe webhook handler.
      console.error(
        JSON.stringify({
          level: "error",
          code: "POS_REFUND_DB_UPDATE_FAILED",
          transactionId: tx.id,
          refundId: refund.id,
          dbError: updateErr.message,
        }),
      );
    }

    return jsonResponse(
      {
        success: true,
        refund_id: refund.id,
        refunded_amount_cents: newRefunded,
        status: newStatus,
      },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("refund-pos-transaction error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
