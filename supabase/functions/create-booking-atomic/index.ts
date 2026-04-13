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

const corsHeaders = securityHeaders;

function generateBookingCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const randomBytes = crypto.getRandomValues(new Uint8Array(8));
  let code = "SPT-";
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(randomBytes[i] % chars.length);
  }
  return code;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
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

    // Rate limit — max 5 booking attempts per minute per user
    const fingerprint = `${user.id}:${getClientIp(req)}`;
    const rateLimitResp = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/rate-limiter`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          type: "booking",
          cardFingerprint: fingerprint,
        }),
      },
    );
    if (rateLimitResp.status === 429) {
      const rlData = await rateLimitResp.json();
      return jsonResponse({ error: rlData.error }, 429);
    }

    const { slotId, serviceId, promoCodeId } = await req.json();

    if (
      !slotId ||
      !serviceId ||
      !isValidUuid(String(slotId)) ||
      !isValidUuid(String(serviceId)) ||
      (promoCodeId && !isValidUuid(String(promoCodeId)))
    ) {
      return jsonResponse(
        { error: "slotId/serviceId/promoCodeId doivent être des UUID valides" },
        400
      );
    }

    // Atomic transaction via RPC
    const bookingCode = generateBookingCode();
    const { data, error } = await supabase.rpc("create_booking_atomic", {
      p_client_id: user.id,
      p_slot_id: slotId,
      p_service_id: serviceId,
      p_promo_code_id: promoCodeId || null,
      p_booking_code: bookingCode,
    });

    if (error) {
      if (error.message?.includes("slot_unavailable")) {
        return jsonResponse({ error: "slot_unavailable" }, 409);
      }
      throw error;
    }

    const bookingId = data.booking_id;
    const depositAmount = data.deposit_amount;
    const remainingAmount = data.remaining_amount ?? 0;
    const paymentMode = data.payment_mode ?? "full";

    // Fetch pro Stripe account for Connect transfer
    const { data: slot } = await supabase
      .from("time_slots")
      .select("pro_id")
      .eq("id", slotId)
      .single();

    const { data: pro } = await supabase
      .from("profiles_pro")
      .select("stripe_account_id, commission_rate")
      .eq("id", slot.pro_id)
      .single();

    // Create Stripe PaymentIntent — amount in cents
    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const amountCents = Math.round(depositAmount * 100);
    if (!isValidAmount(Number(depositAmount))) {
      return jsonResponse(
        { error: "deposit_amount doit être > 0 et < 99999" },
        400
      );
    }
    const commissionRate = pro?.commission_rate ?? 0.18;
    const applicationFee = Math.round(amountCents * commissionRate);

    const paymentIntentParams: Record<string, unknown> = {
      amount: amountCents,
      currency: "cad",
      automatic_payment_methods: { enabled: true },
      metadata: {
        bookingId,
        clientId: user.id,
        proId: slot.pro_id,
        type: paymentMode === "deposit" ? "deposit" : "full_payment",
        paymentMode,
      },
    };

    // If pro has Stripe Connect, use transfer_data + application_fee
    if (pro?.stripe_account_id) {
      paymentIntentParams.transfer_data = {
        destination: pro.stripe_account_id,
      };
      paymentIntentParams.application_fee_amount = applicationFee;
    }

    const paymentIntent = await stripe.paymentIntents.create(
      paymentIntentParams as Stripe.PaymentIntentCreateParams,
      { idempotencyKey: `booking-${bookingId}-deposit` }
    );

    // Store payment intent ID on booking
    await supabase
      .from("bookings")
      .update({ stripe_payment_intent_id: paymentIntent.id })
      .eq("id", bookingId);
    await supabase.rpc("log_audit_action", {
      p_user_id: user.id,
      p_action: "booking_created",
      p_resource_type: "booking",
      p_resource_id: bookingId,
      p_metadata: { payment_intent_id: paymentIntent.id },
    });
    await supabase.rpc("log_audit_action", {
      p_user_id: user.id,
      p_action: "payment_initiated",
      p_resource_type: "booking",
      p_resource_id: bookingId,
      p_metadata: { amount: depositAmount },
    });

    return new Response(
      JSON.stringify({
        success: true,
        bookingId,
        bookingCode: data.booking_code,
        clientSecret: paymentIntent.client_secret,
        depositAmount,
        remainingAmount,
        paymentMode,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("create-booking-atomic error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
