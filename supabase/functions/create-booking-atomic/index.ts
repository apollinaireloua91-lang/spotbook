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
import { currencyForCountry } from "../_shared/currency.ts";

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
      console.error("create-booking-atomic: missing Authorization header");
      return jsonResponse({ error: "unauthorized", reason: "no_header" }, 401);
    }

    // Extraire le token brut du header "Bearer ..."
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) {
      console.error("create-booking-atomic: empty bearer token");
      return jsonResponse({ error: "unauthorized", reason: "empty_token" }, 401);
    }

    // On passe directement le token à getUser() — plus robuste que
    // de passer par un authClient global qui peut échouer silencieusement
    // quand le SDK ne sait pas valider des JWT ES256.
    const { data: userData, error: userErr } = await supabase.auth.getUser(token);
    const user = userData?.user;
    if (userErr || !user) {
      console.error(
        "create-booking-atomic: getUser failed",
        JSON.stringify({ err: userErr?.message, hasUser: !!user }),
      );
      return jsonResponse(
        { error: "unauthorized", reason: "invalid_token" },
        401,
      );
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

    const body = await req.json();
    const {
      slotId: rawSlotId,
      serviceId,
      promoCodeId,
      proId,
      slotDate,
      slotStart,
      slotEnd,
    } = body;

    if (
      !serviceId ||
      !isValidUuid(String(serviceId)) ||
      (promoCodeId && !isValidUuid(String(promoCodeId)))
    ) {
      return jsonResponse(
        { error: "serviceId/promoCodeId doivent être des UUID valides" },
        400,
      );
    }

    // Résoudre le slot : soit un UUID existant (slotId), soit un spec
    // (proId + slotDate + slotStart + slotEnd) qu'on matche ou insère.
    let slotId: string | null = null;
    if (rawSlotId && isValidUuid(String(rawSlotId))) {
      slotId = String(rawSlotId);
    } else if (proId && slotDate && slotStart && slotEnd) {
      if (!isValidUuid(String(proId))) {
        return jsonResponse({ error: "proId invalide" }, 400);
      }
      // Chercher un slot existant pour ce créneau
      const { data: existing } = await supabase
        .from("time_slots")
        .select("id, is_available")
        .eq("pro_id", proId)
        .eq("date", slotDate)
        .eq("start_time", slotStart)
        .maybeSingle();

      if (existing) {
        if (!existing.is_available) {
          return jsonResponse({ error: "slot_unavailable" }, 409);
        }
        slotId = existing.id;
      } else {
        // Créer le slot via service-role (contourne la RLS pro-only)
        const { data: inserted, error: insertErr } = await supabase
          .from("time_slots")
          .insert({
            pro_id: proId,
            date: slotDate,
            start_time: slotStart,
            end_time: slotEnd,
            is_available: true,
          })
          .select("id")
          .single();
        if (insertErr || !inserted) {
          console.error("slot insert failed", insertErr);
          return jsonResponse({ error: "slot_insert_failed" }, 500);
        }
        slotId = inserted.id;
      }
    } else {
      return jsonResponse(
        { error: "slotId ou (proId+slotDate+slotStart+slotEnd) requis" },
        400,
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
      .select("stripe_account_id, commission_rate, country")
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

    const bookingCurrency = currencyForCountry(
      pro?.country as string | null | undefined,
    );
    const paymentIntentParams: Record<string, unknown> = {
      amount: amountCents,
      currency: bookingCurrency,
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

    // Store payment intent ID + currency on booking.
    // La devise est persistée pour que process-payout et cancel-booking
    // utilisent la même devise que le PaymentIntent original.
    // Si l'UPDATE échoue après la création du PI : on cancel le PI
    // (best-effort) + on log ORPHAN_BOOKING pour réconciliation manuelle.
    const { error: updateErr } = await supabase
      .from("bookings")
      .update({
        stripe_payment_intent_id: paymentIntent.id,
        currency: bookingCurrency,
      })
      .eq("id", bookingId);

    if (updateErr) {
      console.error(
        JSON.stringify({
          level: "error",
          code: "ORPHAN_BOOKING",
          message: "Stripe PaymentIntent created but booking.update failed",
          bookingId,
          paymentIntentId: paymentIntent.id,
          dbError: updateErr.message,
        }),
      );
      try {
        await stripe.paymentIntents.cancel(paymentIntent.id, {
          cancellation_reason: "abandoned",
        });
      } catch (cancelErr) {
        console.error(
          JSON.stringify({
            level: "error",
            code: "ORPHAN_BOOKING_CANCEL_FAILED",
            paymentIntentId: paymentIntent.id,
            error: (cancelErr as Error).message,
          }),
        );
      }
      return jsonResponse({ error: "internal_error" }, 500);
    }
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
