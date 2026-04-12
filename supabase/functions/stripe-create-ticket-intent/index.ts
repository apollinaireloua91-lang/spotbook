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

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
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

    const { ticketTypeId, quantity } = await req.json();
    if (
      !ticketTypeId ||
      !isValidUuid(String(ticketTypeId)) ||
      !quantity ||
      quantity < 1 ||
      quantity > 4
    ) {
      return jsonResponse(
        { error: "ticketTypeId UUID valide et quantity (1-4) requis" },
        400
      );
    }

    // Fetch ticket type + event pro
    const { data: ticketType, error: ttErr } = await supabase
      .from("ticket_types")
      .select("*, events(pro_id, profiles_pro:pro_id(stripe_account_id))")
      .eq("id", ticketTypeId)
      .single();

    if (ttErr || !ticketType) {
      return jsonResponse({ error: "ticket_type_not_found" }, 404);
    }

    // Check availability
    const remaining =
      (ticketType.quantity ?? 0) - (ticketType.sold_count ?? 0);
    if (remaining < quantity) {
      return jsonResponse({ error: "not_enough_tickets" }, 409);
    }

    const unitPrice = ticketType.price ?? 0;
    const totalCents = Math.round(unitPrice * quantity * 100);
    if (!isValidAmount(Number(unitPrice))) {
      return jsonResponse({ error: "ticket amount invalide" }, 400);
    }
    const serviceFeeCents = Math.round(2.50 * quantity * 100); // $2.50/ticket
    const chargeAmount = totalCents + serviceFeeCents;
    // 12% event commission + service fee — ALL goes to Spotbook
    const commission = Math.round(totalCents * 0.12) + serviceFeeCents;

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
          cardFingerprint: `${user.id}:${ticketTypeId}:${getClientIp(req)}`,
        }),
      }
    );
    if (rateLimitResp.status === 429) {
      const data = await rateLimitResp.json();
      return jsonResponse({ error: data.error }, 429);
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const proStripeId =
      ticketType.events?.profiles_pro?.stripe_account_id;

    const params: Record<string, unknown> = {
      amount: chargeAmount,
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
        idempotencyKey: `ticket-${ticketTypeId}-${user.id}-${quantity}`,
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
    console.error("stripe-create-ticket-intent error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
