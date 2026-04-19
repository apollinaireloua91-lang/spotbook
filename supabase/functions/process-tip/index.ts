// ════════════════════════════════════════════════════════════════════════════
// process-tip — Priority #3
// ────────────────────────────────────────────────────────────────────────────
// Creates a Stripe PaymentIntent for a tip amount, 100% transferred to the Pro
// via transfer_data.destination (no Spotbook commission on tips).
//
// Flow:
//   1. Auth: client JWT required
//   2. Verify booking exists, belongs to caller, is completed
//   3. Create PaymentIntent { amount, transfer_data: { destination: proAcct } }
//   4. Insert pending tip row
//   5. Return clientSecret for SDK confirmation
//   6. Webhook (stripe-webhook-handler) marks tip `succeeded` on charge success
// ════════════════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "").trim();
    if (!jwt) return jsonResponse({ error: "unauthorized" }, 401, undefined, req);

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData } = await userClient.auth.getUser();
    if (!userData.user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }
    const clientId = userData.user.id;

    const body = await req.json().catch(() => ({}));
    const bookingId = String(body.bookingId ?? "");
    const amountCents = Number(body.amountCents ?? 0);

    if (!isValidUuid(bookingId)) {
      return jsonResponse({ error: "invalid_booking_id" }, 400, undefined, req);
    }
    if (!Number.isInteger(amountCents) || amountCents < 100 || amountCents > 50000) {
      return jsonResponse(
        { error: "invalid_amount", minCents: 100, maxCents: 50000 },
        400,
        undefined,
        req,
      );
    }

    const admin = createClient(supabaseUrl, serviceKey);
    const { data: booking } = await admin
      .from("bookings")
      .select("id, client_id, pro_id, status, currency")
      .eq("id", bookingId)
      .single();

    if (!booking) {
      return jsonResponse({ error: "booking_not_found" }, 404, undefined, req);
    }
    if (booking.client_id !== clientId) {
      return jsonResponse({ error: "forbidden" }, 403, undefined, req);
    }
    if (booking.status !== "completed") {
      return jsonResponse(
        { error: "booking_not_completed" },
        400,
        undefined,
        req,
      );
    }

    // Get pro's Stripe Connect account
    const { data: proRow } = await admin
      .from("profiles_pro")
      .select("stripe_account_id")
      .eq("id", booking.pro_id)
      .single();

    const proAccountId = proRow?.stripe_account_id as string | undefined;
    if (!proAccountId) {
      return jsonResponse(
        { error: "pro_not_configured" },
        400,
        undefined,
        req,
      );
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    // 100% to pro: no application_fee
    const pi = await stripe.paymentIntents.create({
      amount: amountCents,
      currency: (booking.currency ?? "cad").toLowerCase(),
      transfer_data: { destination: proAccountId },
      metadata: {
        spotbook_type: "tip",
        booking_id: bookingId,
        client_id: clientId,
        pro_id: booking.pro_id,
      },
    });

    // Insert pending tip row
    const { error: insertErr } = await admin.from("tips").insert({
      booking_id: bookingId,
      client_id: clientId,
      pro_id: booking.pro_id,
      amount_cents: amountCents,
      currency: (booking.currency ?? "CAD").toUpperCase(),
      stripe_payment_intent_id: pi.id,
      status: "pending",
    });

    if (insertErr) {
      console.error("tip insert failed", insertErr);
      // Don't fail the user — webhook will reconcile
    }

    return jsonResponse(
      {
        ok: true,
        clientSecret: pi.client_secret,
        paymentIntentId: pi.id,
        amountCents,
      },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("process-tip error", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
