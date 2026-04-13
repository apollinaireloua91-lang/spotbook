import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  getClientIp,
  isValidAmount,
  isValidUuid,
  jsonResponse,
  securityHeaders,
} from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    );
    const {
      data: { user },
    } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const { bookingId } = await req.json();
    if (!bookingId || !isValidUuid(String(bookingId))) {
      return jsonResponse({ error: "bookingId must be a valid UUID" }, 400);
    }

    // Fetch booking
    const { data: booking, error: bErr } = await supabase
      .from("bookings")
      .select("*, profiles_pro(stripe_account_id, commission_rate)")
      .eq("id", bookingId)
      .single();

    if (bErr || !booking) {
      return jsonResponse({ error: "booking_not_found" }, 404);
    }

    // Verify ownership
    if (booking.client_id !== user.id) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    // Verify status
    if (booking.status !== "pending_payment") {
      return jsonResponse({ error: "booking_not_pending" }, 400);
    }

    if (!isValidAmount(Number(booking.deposit_amount))) {
      return jsonResponse(
        { error: "deposit_amount must be > 0 and < 99999" },
        400
      );
    }

    // Rate limit payment attempts by card/user fingerprint
    const fingerprint = `${user.id}:${booking.id}:${getClientIp(req)}`;
    const rateLimitResp = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/rate-limiter`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          type: "payment",
          cardFingerprint: fingerprint,
        }),
      }
    );
    if (rateLimitResp.status === 429) {
      const data = await rateLimitResp.json();
      return jsonResponse({ error: data.error }, 429);
    }

    // Already has a PaymentIntent — return existing clientSecret
    if (booking.stripe_payment_intent_id) {
      const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
        apiVersion: "2023-10-16",
      });
      const existing = await stripe.paymentIntents.retrieve(
        booking.stripe_payment_intent_id
      );
      return new Response(
        JSON.stringify({ clientSecret: existing.client_secret }),
        {
          headers: { ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const totalPriceCents = Math.round((booking.total_amount ?? 0) * 100);
    const depositCents = Math.round(booking.deposit_amount * 100);
    const serviceFeeCents = Math.round((booking.service_fee ?? 2.50) * 100);
    const chargeAmount = depositCents + serviceFeeCents;
    const pro = booking.profiles_pro;
    const commissionRate = pro?.commission_rate ?? 0.18;
    // FULL commission on total price taken upfront from the deposit
    const fullCommission = Math.round(totalPriceCents * commissionRate);
    // application_fee = commission + service fee — ALL goes to Spotbook
    const applicationFee = fullCommission + serviceFeeCents;

    const params: Record<string, unknown> = {
      amount: chargeAmount,
      currency: (booking.currency || "cad").toLowerCase(),
      automatic_payment_methods: { enabled: true },
      metadata: {
        bookingId: booking.id,
        clientId: user.id,
        proId: booking.pro_id,
        type: "deposit",
      },
    };

    if (pro?.stripe_account_id) {
      params.transfer_data = { destination: pro.stripe_account_id };
      params.application_fee_amount = applicationFee;
    }

    const paymentIntent = await stripe.paymentIntents.create(
      params as Stripe.PaymentIntentCreateParams,
      { idempotencyKey: `${bookingId}-deposit-${user.id}` }
    );

    // Store PaymentIntent ID on booking
    await supabase
      .from("bookings")
      .update({ stripe_payment_intent_id: paymentIntent.id })
      .eq("id", bookingId);

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      {
        headers: { ...securityHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("stripe-create-intent error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
