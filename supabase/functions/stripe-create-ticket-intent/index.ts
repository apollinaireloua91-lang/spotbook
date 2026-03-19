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

    const { ticketTypeId, quantity } = await req.json();
    if (!ticketTypeId || !quantity || quantity < 1 || quantity > 4) {
      return new Response(
        JSON.stringify({ error: "ticketTypeId and quantity (1-4) required" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

    // Fetch ticket type + event pro
    const { data: ticketType, error: ttErr } = await supabase
      .from("ticket_types")
      .select("*, events(pro_id, profiles_pro:pro_id(stripe_account_id))")
      .eq("id", ticketTypeId)
      .single();

    if (ttErr || !ticketType) {
      return new Response(
        JSON.stringify({ error: "ticket_type_not_found" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 404,
        }
      );
    }

    // Check availability
    const remaining =
      (ticketType.quantity ?? 0) - (ticketType.sold_count ?? 0);
    if (remaining < quantity) {
      return new Response(
        JSON.stringify({ error: "not_enough_tickets" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 409,
        }
      );
    }

    const unitPrice = ticketType.price ?? 0;
    const totalCents = Math.round(unitPrice * quantity * 100);
    const commission = Math.round(totalCents * 0.07); // 7% event commission

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const proStripeId =
      ticketType.events?.profiles_pro?.stripe_account_id;

    const params: Record<string, unknown> = {
      amount: totalCents,
      currency: "cad",
      metadata: {
        ticketTypeId,
        eventId: ticketType.event_id,
        userId: user.id,
        quantity: String(quantity),
        type: "ticket",
      },
    };

    if (proStripeId) {
      params.transfer_data = { destination: proStripeId };
      params.application_fee_amount = commission;
    }

    const paymentIntent = await stripe.paymentIntents.create(
      params as Stripe.PaymentIntentCreateParams,
      {
        idempotencyKey: `ticket-${ticketTypeId}-${user.id}-${Date.now()}`,
      }
    );

    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        totalAmount: unitPrice * quantity,
        commission: commission / 100,
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
