// Edge Function: create-pos-payment-intent
//
// Creates a Stripe PaymentIntent with `payment_method_types: ['card_present']`
// for a Pro-initiated in-person (Tap to Pay) transaction, and persists a
// matching row in `public.pos_transactions` with status `pending`.
//
// Request body (JSON):
//   {
//     amount_subtotal_cents: number        // required, > 0
//     tip_cents:             number        // optional, default 0
//     tps_cents:             number        // optional, default 0
//     tvq_cents:             number        // optional, default 0
//     currency:              string        // optional, default 'cad'
//     customer_email:        string | null // optional, for digital receipt
//     customer_phone:        string | null // optional, for SMS receipt (future)
//     client_request_id:     string (uuid) // required — drives Stripe idempotency
//   }
//
// Response 200:
//   { client_secret: string, transaction_id: string, payment_intent_id: string }
//
// Returns 4xx for bad input / missing Stripe Connect account, 500 for internal
// errors. The Pro MUST have completed Stripe Connect onboarding with
// card_present_payments capability enabled — see doc.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

// Spotbook POS pricing: 18% commission (or per-pro override) + 50 ¢ fixed
// service fee. Both are captured via `application_fee_amount`.
const POS_FIXED_SERVICE_FEE_CENTS = 50;
const DEFAULT_COMMISSION_RATE = 0.18;

// Stripe's minimum charge in CAD is 50 ¢.
const STRIPE_MIN_CHARGE_CENTS = 50;

interface PosPayload {
  amount_subtotal_cents: number;
  tip_cents: number;
  tps_cents: number;
  tvq_cents: number;
  currency: string;
  customer_email: string | null;
  customer_phone: string | null;
  client_request_id: string;
}

function parsePayload(raw: unknown): { ok: true; value: PosPayload } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") {
    return { ok: false, error: "invalid_body" };
  }
  const b = raw as Record<string, unknown>;

  const subtotal = Number(b.amount_subtotal_cents);
  if (!Number.isInteger(subtotal) || subtotal <= 0 || subtotal > 9_999_999) {
    return { ok: false, error: "amount_subtotal_cents must be an integer > 0 and < 9999999" };
  }

  const tip = Number(b.tip_cents ?? 0);
  const tps = Number(b.tps_cents ?? 0);
  const tvq = Number(b.tvq_cents ?? 0);
  for (const [name, v] of Object.entries({ tip_cents: tip, tps_cents: tps, tvq_cents: tvq })) {
    if (!Number.isInteger(v) || v < 0 || v > 9_999_999) {
      return { ok: false, error: `${name} must be a non-negative integer` };
    }
  }

  const currency = typeof b.currency === "string" && b.currency.length === 3
    ? b.currency.toLowerCase()
    : "cad";

  const clientRequestId = String(b.client_request_id ?? "");
  if (!isValidUuid(clientRequestId)) {
    return { ok: false, error: "client_request_id must be a valid UUID v4" };
  }

  const customerEmail =
    typeof b.customer_email === "string" && b.customer_email.trim().length > 0
      ? b.customer_email.trim()
      : null;
  const customerPhone =
    typeof b.customer_phone === "string" && b.customer_phone.trim().length > 0
      ? b.customer_phone.trim()
      : null;

  return {
    ok: true,
    value: {
      amount_subtotal_cents: subtotal,
      tip_cents: tip,
      tps_cents: tps,
      tvq_cents: tvq,
      currency,
      customer_email: customerEmail,
      customer_phone: customerPhone,
      client_request_id: clientRequestId,
    },
  };
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

    // Parse + validate.
    let raw: unknown;
    try {
      raw = await req.json();
    } catch {
      return jsonResponse({ error: "invalid_json" }, 400, undefined, req);
    }
    const parsed = parsePayload(raw);
    if (!parsed.ok) {
      return jsonResponse({ error: parsed.error }, 400, undefined, req);
    }
    const p = parsed.value;

    const amountTotalCents =
      p.amount_subtotal_cents + p.tip_cents + p.tps_cents + p.tvq_cents;
    if (amountTotalCents < STRIPE_MIN_CHARGE_CENTS) {
      return jsonResponse(
        { error: `amount_total_cents must be >= ${STRIPE_MIN_CHARGE_CENTS}` },
        400,
        undefined,
        req,
      );
    }

    // Service-role client for privileged reads + inserts.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: pro, error: proErr } = await supabase
      .from("profiles_pro")
      .select("id, stripe_account_id, commission_rate")
      .eq("id", user.id)
      .maybeSingle();

    if (proErr) {
      console.error("profiles_pro lookup error:", proErr);
      return jsonResponse({ error: "internal_error" }, 500, undefined, req);
    }
    if (!pro) {
      return jsonResponse({ error: "not_a_pro" }, 403, undefined, req);
    }
    if (!pro.stripe_account_id) {
      return jsonResponse(
        { error: "stripe_connect_not_onboarded" },
        409,
        undefined,
        req,
      );
    }

    const commissionRate = Number(pro.commission_rate ?? DEFAULT_COMMISSION_RATE);
    const commissionCents = Math.round(amountTotalCents * commissionRate);
    const applicationFeeCents = commissionCents + POS_FIXED_SERVICE_FEE_CENTS;

    // Sanity: application_fee must be strictly less than amount — otherwise
    // the transfer to the Pro is negative and Stripe rejects the PI.
    if (applicationFeeCents >= amountTotalCents) {
      return jsonResponse(
        { error: "application_fee_exceeds_amount" },
        400,
        undefined,
        req,
      );
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    // Create PaymentIntent with Connect destination charge.
    // card_present + Terminal SDK handles PM collection on-device.
    const pi = await stripe.paymentIntents.create(
      {
        amount: amountTotalCents,
        currency: p.currency,
        payment_method_types: ["card_present"],
        capture_method: "automatic",
        application_fee_amount: applicationFeeCents,
        transfer_data: { destination: pro.stripe_account_id },
        receipt_email: p.customer_email ?? undefined,
        metadata: {
          source: "spotbook_pos",
          pro_id: user.id,
          tip_cents: String(p.tip_cents),
          tps_cents: String(p.tps_cents),
          tvq_cents: String(p.tvq_cents),
          subtotal_cents: String(p.amount_subtotal_cents),
          client_request_id: p.client_request_id,
        },
      },
      // Deterministic idempotency so a client retry never double-charges.
      { idempotencyKey: `pos-${p.client_request_id}` },
    );

    // Persist a pending row. If the insert fails after the PI was created,
    // we cancel the PI so no charge can be initiated on an orphan.
    const { data: inserted, error: insertErr } = await supabase
      .from("pos_transactions")
      .insert({
        pro_id: user.id,
        stripe_payment_intent_id: pi.id,
        amount_subtotal_cents: p.amount_subtotal_cents,
        tip_cents: p.tip_cents,
        tps_cents: p.tps_cents,
        tvq_cents: p.tvq_cents,
        amount_total_cents: amountTotalCents,
        application_fee_cents: applicationFeeCents,
        currency: p.currency,
        status: "pending",
        customer_email: p.customer_email,
        customer_phone: p.customer_phone,
      })
      .select("id")
      .single();

    if (insertErr || !inserted) {
      console.error(
        JSON.stringify({
          level: "error",
          code: "POS_INSERT_FAILED",
          message: "pos_transactions insert failed after PaymentIntent creation",
          paymentIntentId: pi.id,
          dbError: insertErr?.message,
        }),
      );
      try {
        await stripe.paymentIntents.cancel(pi.id, {
          cancellation_reason: "abandoned",
        });
      } catch (cancelErr) {
        console.error(
          JSON.stringify({
            level: "error",
            code: "POS_ORPHAN_CANCEL_FAILED",
            paymentIntentId: pi.id,
            error: (cancelErr as Error).message,
          }),
        );
      }
      return jsonResponse({ error: "internal_error" }, 500, undefined, req);
    }

    return jsonResponse(
      {
        client_secret: pi.client_secret,
        transaction_id: inserted.id,
        payment_intent_id: pi.id,
      },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("create-pos-payment-intent error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
