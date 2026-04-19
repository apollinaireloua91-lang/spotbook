// ════════════════════════════════════════════════════════════════════════════
// request-instant-payout — Get Paid Faster (Stripe Instant Payouts)
// ────────────────────────────────────────────────────────────────────────────
// Pro-initiated payout request. Triggers a Stripe Instant Payout on the
// connected account, which lands in ~30 minutes vs 2-7 days for standard.
//
// Flow:
//   1. Verify caller is authenticated & owns a profiles_pro row
//   2. Validate requested amount vs Stripe connected account's available balance
//   3. Call Stripe `payouts.create({ method: 'instant' })` on connected account
//   4. Insert a payout_requests row (service_role) with fee/net breakdown
//   5. Return confirmation + expected arrival
//
// Errors handled:
//   - No stripe_account_id → 400 "Stripe Connect not configured"
//   - Amount > balance → 400 "Insufficient balance"
//   - No eligible debit card → 400 "No instant-eligible destination"
//   - Stripe API failure → 500 with safe error
//
// Auth: Pro JWT required. Never service_role.
// ════════════════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

const STRIPE_INSTANT_FEE_PCT = 0.015; // 1.5%
const STRIPE_INSTANT_FEE_CAP_USD = 1500; // $15 USD in cents

/**
 * Compute the Stripe Instant Payout fee in cents.
 * Stripe charges 1.5% of the payout amount, capped at $15 USD equivalent.
 */
function computeInstantFeeCents(amountCents: number): number {
  const pct = Math.ceil(amountCents * STRIPE_INSTANT_FEE_PCT);
  return Math.min(pct, STRIPE_INSTANT_FEE_CAP_USD);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: securityHeadersFor(req),
    });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    // Authenticated client — NOT service role
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();
    if (!jwt) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // Use JWT-scoped client to verify the caller
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }
    const proId = userData.user.id;

    // Parse body
    let body: { amountCents?: number; method?: string };
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: "invalid_body" }, 400, undefined, req);
    }
    const amountCents = Number(body.amountCents);
    const method = body.method === "standard" ? "standard" : "instant";

    if (!Number.isInteger(amountCents) || amountCents < 100) {
      return jsonResponse(
        { error: "amount_too_low", minimumCents: 100 },
        400,
        undefined,
        req,
      );
    }

    // Fetch the Pro's Stripe connected account id (service_role for RLS bypass)
    const admin = createClient(supabaseUrl, serviceKey);
    const { data: proRow } = await admin
      .from("profiles_pro")
      .select("stripe_account_id")
      .eq("id", proId)
      .single();

    const stripeAccountId = proRow?.stripe_account_id as string | undefined;
    if (!stripeAccountId) {
      return jsonResponse(
        { error: "stripe_connect_not_configured" },
        400,
        undefined,
        req,
      );
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    // Check connected account balance
    const balance = await stripe.balance.retrieve({
      stripeAccount: stripeAccountId,
    });
    const available = balance.available.find((b) =>
      ["cad", "usd"].includes(b.currency)
    );
    const availableCents = available?.amount ?? 0;
    const currency = (available?.currency ?? "cad").toUpperCase();

    if (amountCents > availableCents) {
      return jsonResponse(
        {
          error: "insufficient_balance",
          availableCents,
          requestedCents: amountCents,
        },
        400,
        undefined,
        req,
      );
    }

    // Compute fee & net
    const feeCents = method === "instant"
      ? computeInstantFeeCents(amountCents)
      : 0;
    const netCents = amountCents - feeCents;

    // Create the payout on the connected account
    let stripePayoutId: string | undefined;
    let expectedArrival: Date | undefined;
    try {
      const payout = await stripe.payouts.create(
        {
          amount: amountCents,
          currency: currency.toLowerCase(),
          method,
          metadata: { pro_id: proId },
        },
        { stripeAccount: stripeAccountId },
      );
      stripePayoutId = payout.id;
      if (payout.arrival_date) {
        expectedArrival = new Date(payout.arrival_date * 1000);
      }
    } catch (err) {
      const e = err as { code?: string; message?: string };
      const msg = e.code ?? e.message ?? "stripe_error";
      // Map common Stripe errors to clean UX codes
      const userCode =
        msg.includes("no_eligible_debit") ||
        msg.includes("instant_payouts_unsupported")
          ? "no_instant_destination"
          : "stripe_error";
      return jsonResponse(
        { error: userCode, reason: msg },
        400,
        undefined,
        req,
      );
    }

    // Persist audit row via service_role
    const { error: insertErr } = await admin.from("payout_requests").insert({
      pro_id: proId,
      amount_cents: amountCents,
      currency,
      method,
      fee_cents: feeCents,
      net_cents: netCents,
      status: "processing",
      stripe_payout_id: stripePayoutId,
      expected_arrival: expectedArrival?.toISOString(),
    });

    if (insertErr) {
      // Don't fail the user — Stripe already accepted the payout.
      // Log this for monitoring instead.
      console.error("payout_requests insert failed", insertErr);
    }

    return jsonResponse(
      {
        ok: true,
        payoutId: stripePayoutId,
        amountCents,
        feeCents,
        netCents,
        currency,
        expectedArrival: expectedArrival?.toISOString(),
        method,
      },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("request-instant-payout error", err);
    return jsonResponse(
      { error: "internal_error" },
      500,
      undefined,
      req,
    );
  }
});
