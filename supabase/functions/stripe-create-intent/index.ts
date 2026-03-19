import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Auth check
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

    const { bookingId } = await req.json();
    if (!bookingId) {
      return new Response(
        JSON.stringify({ error: "bookingId required" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

    // Fetch booking
    const { data: booking, error: bErr } = await supabase
      .from("bookings")
      .select("*, profiles_pro(stripe_account_id, commission_rate)")
      .eq("id", bookingId)
      .single();

    if (bErr || !booking) {
      return new Response(JSON.stringify({ error: "booking_not_found" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 404,
      });
    }

    // Verify ownership
    if (booking.client_id !== user.id) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    // Verify status
    if (booking.status !== "pending_payment") {
      return new Response(
        JSON.stringify({ error: "booking_not_pending" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
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
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const depositCents = Math.round(booking.deposit_amount * 100);
    const pro = booking.profiles_pro;
    const commissionRate = pro?.commission_rate ?? 0.12;
    const applicationFee = Math.round(depositCents * commissionRate);

    const params: Record<string, unknown> = {
      amount: depositCents,
      currency: (booking.currency || "cad").toLowerCase(),
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
