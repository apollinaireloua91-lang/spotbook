import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  getClientIp,
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

/** Montant en centimes (Stripe). */
const MIN_AMOUNT_CENTS = 50;
const MAX_AMOUNT_CENTS = 99_999_999;

function isValidAmountCents(n: number) {
  return Number.isInteger(n) && n >= MIN_AMOUNT_CENTS && n <= MAX_AMOUNT_CENTS;
}

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: securityHeadersFor(req) });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: authHeader },
        },
      },
    );

    const {
      data: { user },
    } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const body = await req.json().catch(() => ({}));
    const bookingId = String(body.bookingId ?? "");
    const providerId = String(body.providerId ?? "");

    if (!providerId || !isValidUuid(providerId)) {
      return jsonResponse(
        { error: "providerId doit être un UUID valide" },
        400,
        undefined,
        req,
      );
    }

    if (!bookingId || !isValidUuid(bookingId)) {
      return jsonResponse(
        { error: "bookingId doit être un UUID valide" },
        400,
        undefined,
        req,
      );
    }

    if (user.id === providerId) {
      return jsonResponse(
        { error: "cannot_pay_self" },
        400,
        undefined,
        req,
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Fetch booking to compute amount server-side
    const { data: booking, error: bookingErr } = await supabase
      .from("bookings")
      .select("id, client_id, pro_id, deposit_amount, total_amount, service_fee, status, service_id")
      .eq("id", bookingId)
      .single();

    if (bookingErr || !booking) {
      return jsonResponse({ error: "booking_not_found" }, 404, undefined, req);
    }
    if (booking.client_id !== user.id) {
      return jsonResponse({ error: "forbidden" }, 403, undefined, req);
    }
    if (booking.pro_id !== providerId) {
      return jsonResponse({ error: "provider_mismatch" }, 400, undefined, req);
    }
    if (booking.status !== "pending_payment") {
      return jsonResponse({ error: "booking_not_payable" }, 400, undefined, req);
    }

    // Server-calculated amount: deposit + service fee (in cents)
    const depositCents = Math.round(booking.deposit_amount * 100);
    const serviceFeeCents = Math.round((booking.service_fee ?? 2.50) * 100);
    const amount = depositCents + serviceFeeCents;
    if (!isValidAmountCents(amount)) {
      return jsonResponse(
        { error: "invalid_booking_amount" },
        400,
        undefined,
        req,
      );
    }

    const { data: pro, error: proErr } = await supabase
      .from("profiles_pro")
      .select("stripe_account_id, commission_rate")
      .eq("id", providerId)
      .maybeSingle();

    if (proErr || !pro) {
      return jsonResponse({ error: "provider_not_found" }, 404, undefined, req);
    }

    if (!pro.stripe_account_id) {
      return jsonResponse(
        { error: "provider_not_connected" },
        400,
        undefined,
        req,
      );
    }

    const fingerprint = `${user.id}:${providerId}:${getClientIp(req)}`;
    const rateLimitResp = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/rate-limiter`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get(
            "SUPABASE_SERVICE_ROLE_KEY",
          )}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          type: "payment",
          cardFingerprint: fingerprint,
        }),
      },
    );
    if (rateLimitResp.status === 429) {
      const data = await rateLimitResp.json();
      return jsonResponse({ error: data.error }, 429, undefined, req);
    }

    const totalPriceCents = Math.round((booking.total_amount ?? 0) * 100);
    const commissionRate = Number(pro.commission_rate ?? 0.18);
    // Commission on FULL booking price + service fee — ALL goes to Spotbook
    const fullCommission = Math.round(totalPriceCents * commissionRate);
    const applicationFeeAmount = fullCommission + serviceFeeCents;

    const idempotencyKey =
      typeof body.idempotencyKey === "string" &&
        body.idempotencyKey.length > 8 &&
        body.idempotencyKey.length < 200
        ? body.idempotencyKey
        : crypto.randomUUID();

    const paymentIntent = await stripe.paymentIntents.create(
      {
        amount,
        currency: "cad",
        automatic_payment_methods: { enabled: true },
        application_fee_amount: applicationFeeAmount,
        transfer_data: {
          destination: pro.stripe_account_id,
        },
        metadata: {
          clientId: user.id,
          proId: providerId,
          type: "spotbook_connect",
        },
      },
      { idempotencyKey },
    );

    return jsonResponse(
      {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("create-payment-intent error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
