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

    const { ticketTypeId, quantity, purchaseNonce } = await req.json();
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

    // Idempotency : accepter un nonce client (UUID généré côté app au tap
    // sur "Acheter") pour que les retries réseau renvoient le même PI.
    // Fallback : fenêtre de 5 minutes pour éviter les doubles charges sur
    // retries rapides si le client n'envoie pas de nonce (ancienne version).
    const clientNonce =
      typeof purchaseNonce === "string" &&
      purchaseNonce.length >= 8 &&
      purchaseNonce.length <= 64 &&
      /^[A-Za-z0-9_\-]+$/.test(purchaseNonce)
        ? purchaseNonce
        : `bucket-${Math.floor(Date.now() / (5 * 60 * 1000))}`;

    // Fetch ticket type + event (commission_rate/service_fee sont stockés
    // au niveau event, pas hardcodés — permet de tuner par événement).
    const { data: ticketType, error: ttErr } = await supabase
      .from("ticket_types")
      .select(
        "*, events(pro_id, commission_rate, service_fee, profiles_pro:pro_id(stripe_account_id, country))",
      )
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
    // Commission + service fee lus depuis events (fallback défauts CLAUDE.md).
    // Une borne 0 ≤ rate ≤ 1 évite qu'une valeur aberrante (ex: 2.5 au lieu
    // de 0.25) vide involontairement le payout du pro.
    const eventCommissionRaw = Number(ticketType.events?.commission_rate ?? 0.12);
    const eventCommissionRate = Math.min(Math.max(eventCommissionRaw, 0), 1);
    const eventServiceFee = Number(ticketType.events?.service_fee ?? 2.50);
    const serviceFeeCents = Math.round(eventServiceFee * quantity * 100);
    const chargeAmount = totalCents + serviceFeeCents;
    // commission events + service fee → Spotbook (application_fee)
    const commission =
      Math.round(totalCents * eventCommissionRate) + serviceFeeCents;

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
    const proCountry =
      ticketType.events?.profiles_pro?.country as string | null | undefined;

    const params: Record<string, unknown> = {
      amount: chargeAmount,
      currency: currencyForCountry(proCountry),
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
        idempotencyKey: `ticket-${ticketTypeId}-${user.id}-${quantity}-${clientNonce}`,
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
