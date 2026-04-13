import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  jsonResponse,
  securityHeaders,
  isValidUuid,
} from "../_shared/security.ts";

/** Fire-and-forget email via send-email Edge Function. */
async function sendEmail(
  type: string,
  to: string,
  data: Record<string, unknown>,
) {
  try {
    await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/send-email`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ type, to, data }),
      },
    );
  } catch (e) {
    console.error("sendEmail failed:", type, e);
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: securityHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  try {
    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    // rawBody as TEXT — never JSON — for signature verification
    const rawBody = await req.text();
    const sig = req.headers.get("stripe-signature");

    if (!sig) {
      return jsonResponse({ error: "Missing stripe-signature" }, 400);
    }

    // Rate limit webhook signature attempts by signature hash
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
          cardFingerprint: `webhook:${sig.slice(0, 24)}`,
        }),
      }
    );
    if (rateLimitResp.status === 429) {
      const data = await rateLimitResp.json();
      return jsonResponse({ error: data.error }, 429);
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

        // ─── TICKET PURCHASE FLOW ─────────────────────────────
        if (pi.metadata.type === "ticket") {
          const ticketTypeId = pi.metadata.ticketTypeId;
          const eventId = pi.metadata.eventId;
          const userId = pi.metadata.userId;
          const quantity = parseInt(pi.metadata.quantity ?? "1", 10);

          if (!ticketTypeId || !eventId || !userId) break;
          if (!isValidUuid(ticketTypeId) || !isValidUuid(eventId) || !isValidUuid(userId)) break;

          // Create tickets, sign QR, and collect first ticket info for email
          let firstTicketId: string | undefined;
          let firstQrCodeUrl: string | undefined;

          for (let i = 0; i < quantity; i++) {
            const { data: ticket, error: ticketErr } = await supabase
              .from("tickets")
              .insert({
                event_id: eventId,
                ticket_type_id: ticketTypeId,
                user_id: userId,
                stripe_payment_intent_id: pi.id,
                status: "valid",
              })
              .select("id")
              .single();

            if (ticketErr || !ticket) {
              console.error("Ticket creation failed:", ticketErr?.message);
              continue;
            }

            // Sign QR via edge function — capture response for QR image URL
            try {
              const { data: signData } = await supabase.functions.invoke(
                "sign-qr-ticket",
                { body: { ticketId: ticket.id } },
              );
              // Keep the first ticket's info for the email
              if (i === 0) {
                firstTicketId = ticket.id;
                firstQrCodeUrl = signData?.qrCodeUrl;
              }
            } catch (e) {
              console.error("QR signing failed for ticket:", ticket.id, e);
              if (i === 0) firstTicketId = ticket.id;
            }
          }

          // Increment sold_count
          await supabase.rpc("increment_sold_count", {
            p_ticket_type_id: ticketTypeId,
            p_quantity: quantity,
          });

          // Fetch event details for notifications + email
          const { data: eventData } = await supabase
            .from("events")
            .select("title, pro_id, event_date, location")
            .eq("id", eventId)
            .single();

          const eventTitle = eventData?.title ?? "un événement";

          // Notify client
          await supabase.from("notifications").insert({
            user_id: userId,
            type: "ticket_purchased",
            title: "Billet confirmé",
            body: `Votre achat de ${quantity} billet(s) pour ${eventTitle} est confirmé.`,
            resource_id: eventId,
            data: { ticket_type_id: ticketTypeId, quantity },
            idempotency_key: `${event.id}:ticket_purchased:${userId}`,
          });

          // Notify pro/organizer
          if (eventData?.pro_id) {
            await supabase.from("notifications").insert({
              user_id: eventData.pro_id,
              type: "ticket_sold",
              title: "Billet vendu",
              body: `${quantity} billet(s) vendu(s) pour ${eventTitle}.`,
              resource_id: eventId,
              data: { ticket_type_id: ticketTypeId, quantity, buyer_id: userId },
              idempotency_key: `${event.id}:ticket_sold:${eventData.pro_id}`,
            });
          }

          // Email — ticket purchased (with QR code + client name)
          const { data: buyerUser } = await supabase
            .from("users")
            .select("email, full_name")
            .eq("id", userId)
            .single();

          if (buyerUser?.email) {
            await sendEmail("ticket_purchased", buyerUser.email, {
              clientName: buyerUser.full_name ?? "Client",
              eventName: eventTitle,
              eventDate: eventData?.event_date ?? "",
              venue: eventData?.location ?? "",
              ticketId: firstTicketId ?? "",
              qrCodeUrl: firstQrCodeUrl ?? undefined,
            });
          }

          await supabase.rpc("log_audit_action", {
            p_user_id: userId,
            p_action: "ticket_purchased",
            p_resource_type: "event",
            p_resource_id: eventId,
            p_metadata: { payment_intent_id: pi.id, quantity, ticket_type_id: ticketTypeId },
          });

          break;
        }

        // ─── BOOKING PAYMENT FLOW ─────────────────────────────
        const bookingId = pi.metadata.bookingId;
        if (!bookingId) break;
        if (!isValidUuid(bookingId)) break;

        // Update booking status (only if still pending_payment — guards against webhook replays)
        await supabase
          .from("bookings")
          .update({ status: "confirmed" })
          .eq("id", bookingId)
          .eq("status", "pending_payment");
        await supabase.rpc("log_audit_action", {
          p_user_id: pi.metadata.clientId ?? null,
          p_action: "booking_confirmed",
          p_resource_type: "booking",
          p_resource_id: bookingId,
        });
        await supabase.rpc("log_audit_action", {
          p_user_id: pi.metadata.clientId ?? null,
          p_action: "payment_succeeded",
          p_resource_type: "booking",
          p_resource_id: bookingId,
          p_metadata: { payment_intent_id: pi.id },
        });

        // Trigger payout via edge function
        try {
          await supabase.functions.invoke("process-payout", {
            body: { bookingId },
          });
        } catch (_) {
          // Payout failure is non-blocking for confirmation
        }

        // Push notification + email to client
        const { data: booking } = await supabase
          .from("bookings")
          .select(
            "client_id, pro_id, booking_code, deposit_amount, " +
            "services(name), time_slots(date, start_time), " +
            "users!bookings_client_id_fkey(email), " +
            "profiles_pro!bookings_pro_id_fkey(business_name)"
          )
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
              idempotency_key: `${event.id}:booking_confirmed:${booking.client_id}`,
            },
            {
              user_id: booking.pro_id,
              type: "new_booking",
              title: "Nouveau RDV",
              body: `Nouvelle réservation ${booking.booking_code} reçue.`,
              resource_id: bookingId,
              idempotency_key: `${event.id}:new_booking:${booking.pro_id}`,
            },
          ]);

          // Email — booking confirmed
          const clientUser = booking.users as Record<string, unknown> | null;
          const clientEmail = clientUser?.email as string | undefined;
          const service = booking.services as Record<string, unknown> | null;
          const slot = booking.time_slots as Record<string, unknown> | null;
          const proProfile = booking.profiles_pro as Record<string, unknown> | null;

          if (clientEmail) {
            await sendEmail("booking_confirmed", clientEmail, {
              serviceName: service?.name ?? "Service",
              proName: proProfile?.business_name ?? "",
              date: slot?.date ?? "",
              time: slot?.start_time ?? "",
              bookingCode: booking.booking_code,
              amount: booking.deposit_amount
                ? Number(booking.deposit_amount).toFixed(2)
                : "",
            });

            // Payment receipt email
            await sendEmail("payment_receipt", clientEmail, {
              amount: booking.deposit_amount
                ? Number(booking.deposit_amount).toFixed(2)
                : "0",
              currency: pi.currency?.toUpperCase() ?? "CAD",
              description: `Acompte — ${service?.name ?? "Réservation"}`,
              bookingCode: booking.booking_code,
            });
          }
        }
        break;
      }

      case "payment_intent.payment_failed": {
        const pi = event.data.object as Stripe.PaymentIntent;
        const bookingId = pi.metadata.bookingId;
        if (!bookingId) break;
        if (!isValidUuid(bookingId)) break;

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
        await supabase.rpc("log_audit_action", {
          p_user_id: booking?.client_id ?? pi.metadata.clientId ?? null,
          p_action: "payment_failed",
          p_resource_type: "booking",
          p_resource_id: bookingId,
          p_metadata: { payment_intent_id: pi.id },
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
            idempotency_key: `${event.id}:payment_failed:${booking.client_id}`,
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
          .select(
            "id, client_id, booking_code, deposit_amount, " +
            "services(name), users!bookings_client_id_fkey(email)"
          )
          .eq("stripe_payment_intent_id", piId)
          .single();

        if (booking) {
          await supabase
            .from("bookings")
            .update({ refund_status: "completed" })
            .eq("id", booking.id);
          await supabase.rpc("log_audit_action", {
            p_user_id: booking.client_id,
            p_action: "refund_completed",
            p_resource_type: "booking",
            p_resource_id: booking.id,
          });

          await supabase.from("notifications").insert({
            user_id: booking.client_id,
            type: "refund_completed",
            title: "Remboursement effectué",
            body: `Le remboursement pour ${booking.booking_code} a été traité.`,
            resource_id: booking.id,
            idempotency_key: `${event.id}:refund_completed:${booking.client_id}`,
          });

          // Email — booking cancelled with refund
          const refundUser = booking.users as Record<string, unknown> | null;
          const refundEmail = refundUser?.email as string | undefined;
          const refundService = booking.services as Record<string, unknown> | null;

          if (refundEmail) {
            await sendEmail("booking_cancelled", refundEmail, {
              serviceName: refundService?.name ?? "Service",
              bookingCode: booking.booking_code,
              refundAmount: booking.deposit_amount
                ? Number(booking.deposit_amount).toFixed(2)
                : undefined,
            });
          }
        }
        break;
      }

      /** Connect Express : garde `profiles_pro.stripe_onboarded` aligné sur Stripe. */
      case "account.updated": {
        const account = event.data.object as Stripe.Account;
        const stripeAccountId = account.id;
        if (!stripeAccountId) break;

        const onboarded =
          account.details_submitted === true &&
          account.charges_enabled === true &&
          account.payouts_enabled === true;

        const { error: updErr } = await supabase
          .from("profiles_pro")
          .update({ stripe_onboarded: onboarded })
          .eq("stripe_account_id", stripeAccountId);

        if (updErr) {
          console.error("account.updated profiles_pro:", updErr.message);
        }
        break;
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...securityHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Webhook error:", error);
    return jsonResponse({ error: "webhook_processing_failed" }, 400);
  }
});
