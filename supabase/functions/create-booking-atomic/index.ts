import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function generateBookingCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "SPT-";
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );
    const {
      data: { user },
    } = await authClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    const { slotId, serviceId, promoCodeId } = await req.json();

    if (!slotId || !serviceId) {
      return new Response(
        JSON.stringify({ error: "slotId and serviceId required" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
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
        return new Response(
          JSON.stringify({ error: "slot_unavailable" }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 409,
          }
        );
      }
      throw error;
    }

    const bookingId = data.booking_id;
    const depositAmount = data.deposit_amount;

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
    const commissionRate = pro?.commission_rate ?? 0.12;
    const applicationFee = Math.round(amountCents * commissionRate);

    const paymentIntentParams: Record<string, unknown> = {
      amount: amountCents,
      currency: "cad",
      metadata: {
        bookingId,
        clientId: user.id,
        proId: slot.pro_id,
        type: "deposit",
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

    return new Response(
      JSON.stringify({
        success: true,
        bookingId,
        bookingCode: data.booking_code,
        clientSecret: paymentIntent.client_secret,
        depositAmount,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
