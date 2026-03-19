import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import { jsonHeaders, securityHeaders } from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: securityHeaders });
  }

  try {
    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    // rawBody as TEXT — never JSON — for signature verification
    const rawBody = await req.text();
    const sig = req.headers.get("stripe-signature");

    if (!sig) {
      return new Response(
        JSON.stringify({ error: "Missing stripe-signature" }),
        { status: 400, headers: jsonHeaders },
      );
    }

    // Rate limiting webhook replay attempts (3 / hour) by signature
    const limiter = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/rate-limiter`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          scope: "payment",
          identifier: `stripe:${sig.slice(0, 24)}`,
        }),
      },
    );
    if (limiter.status === 429) {
      const body = await limiter.json();
      return new Response(
        JSON.stringify({ error: body.message ?? "Trop de tentatives." }),
        { headers: jsonHeaders, status: 429 },
      );
    }

    const event = stripe.webhooks.constructEvent(
      rawBody,
      sig,
      Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? ""
    );

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    switch (event.type) {
      case "payment_intent.succeeded": {
        const pi = event.data.object as Stripe.PaymentIntent;
        const bookingId = pi.metadata.bookingId;
        if (!bookingId) break;

        // Update booking status
        await supabase
          .from("bookings")
          .update({ status: "confirmed" })
          .eq("id", bookingId);
        await supabase.rpc("insert_audit_log", {
          p_user_id: null,
          p_action: "booking_confirmed",
          p_resource_type: "booking",
          p_resource_id: bookingId,
          p_metadata: {},
          p_ip_address: "stripe_webhook",
        });
        await supabase.rpc("insert_audit_log", {
          p_user_id: null,
          p_action: "payment_succeeded",
          p_resource_type: "booking",
          p_resource_id: bookingId,
          p_metadata: { payment_intent_id: pi.id },
          p_ip_address: "stripe_webhook",
        });

        // Trigger payout via edge function
        try {
          await supabase.functions.invoke("process-payout", {
            body: { bookingId },
          });
        } catch (_) {
          // Payout failure is non-blocking for confirmation
        }

        // Push notification to client
        const { data: booking } = await supabase
          .from("bookings")
          .select("client_id, pro_id, booking_code")
          .eq("id", bookingId)
          .single();

        if (booking) {
          await supabase.from("notifications").insert([
            {
              user_id: booking.client_id,
              type: "booking_confirmed",
              title: "Réservation confirmée",
              body: `Votre réservation ${booking.booking_code} est confirmée.`,
              resource_id: bookingId,
            },
            {
              user_id: booking.pro_id,
              type: "new_booking",
              title: "Nouveau RDV",
              body: `Nouvelle réservation ${booking.booking_code} reçue.`,
              resource_id: bookingId,
            },
          ]);
        }
        break;
      }

      case "payment_intent.payment_failed": {
        const pi = event.data.object as Stripe.PaymentIntent;
        const bookingId = pi.metadata.bookingId;
        if (!bookingId) break;

        // Fetch booking to get slot
        const { data: booking } = await supabase
          .from("bookings")
          .select("time_slot_id, client_id, booking_code")
          .eq("id", bookingId)
          .single();

        // Update booking status
        await supabase
          .from("bookings")
          .update({ status: "payment_failed" })
          .eq("id", bookingId);
        await supabase.rpc("insert_audit_log", {
          p_user_id: null,
          p_action: "payment_failed",
          p_resource_type: "booking",
          p_resource_id: bookingId,
          p_metadata: { payment_intent_id: pi.id },
          p_ip_address: "stripe_webhook",
        });

        // Release the time slot
        if (booking?.time_slot_id) {
          await supabase
            .from("time_slots")
            .update({ is_available: true, locked_by: null })
            .eq("id", booking.time_slot_id);
        }

        // Notify client
        if (booking) {
          await supabase.from("notifications").insert({
            user_id: booking.client_id,
            type: "payment_failed",
            title: "Paiement échoué",
            body: `Le paiement pour ${booking.booking_code} a échoué. Le créneau a été libéré.`,
            resource_id: bookingId,
          });
        }
        break;
      }

      case "charge.refunded": {
        const charge = event.data.object as Stripe.Charge;
        const piId =
          typeof charge.payment_intent === "string"
            ? charge.payment_intent
            : charge.payment_intent?.id;

        if (!piId) break;

        const { data: booking } = await supabase
          .from("bookings")
          .select("id, client_id, booking_code")
          .eq("stripe_payment_intent_id", piId)
          .single();

        if (booking) {
          await supabase
            .from("bookings")
            .update({ refund_status: "completed" })
            .eq("id", booking.id);
          await supabase.rpc("insert_audit_log", {
            p_user_id: booking.client_id,
            p_action: "refund_completed",
            p_resource_type: "booking",
            p_resource_id: booking.id,
            p_metadata: { payment_intent_id: piId },
            p_ip_address: "stripe_webhook",
          });

          await supabase.from("notifications").insert({
            user_id: booking.client_id,
            type: "refund_completed",
            title: "Remboursement effectué",
            body: `Le remboursement pour ${booking.booking_code} a été traité.`,
            resource_id: booking.id,
          });
        }
        break;
      }

      case "customer.subscription.created": {
        const sub = event.data.object as Stripe.Subscription;
        const proId = sub.metadata.proId;
        if (!proId) break;

        await supabase.from("pro_subscriptions").upsert({
          pro_id: proId,
          stripe_subscription_id: sub.id,
          status: sub.status,
          current_period_end: new Date(
            sub.current_period_end * 1000
          ).toISOString(),
        });

        // Premium commission rate
        await supabase
          .from("profiles_pro")
          .update({ commission_rate: 0.08 })
          .eq("id", proId);
        break;
      }

      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const proId = sub.metadata.proId;
        if (!proId) break;

        await supabase
          .from("pro_subscriptions")
          .update({ status: "cancelled" })
          .eq("stripe_subscription_id", sub.id);

        // Revert to standard commission
        await supabase
          .from("profiles_pro")
          .update({ commission_rate: 0.12 })
          .eq("id", proId);
        break;
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: jsonHeaders,
      status: 200,
    });
  } catch (error) {
    console.error("Webhook error:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: jsonHeaders,
      status: 400,
    });
  }
});
