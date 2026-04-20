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

    // ─── Stripe routes Connect events via a dedicated webhook endpoint with
    // its OWN signing secret (different from the platform secret). We try the
    // Connect secret first, then fall back to the platform secret, so a single
    // deployment supports both endpoints without reconfiguration. ───
    const connectSecret = Deno.env.get("STRIPE_CONNECT_WEBHOOK_SECRET") ?? "";
    const platformSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
    const secrets = [connectSecret, platformSecret].filter(Boolean);
    if (secrets.length === 0) {
      console.error("No Stripe webhook secret configured in env");
      return jsonResponse(
        { error: "server_misconfigured", detail: "webhook_secret_missing" },
        500,
      );
    }

    let event: Stripe.Event | null = null;
    let lastVerifyErr: unknown = null;
    // ─── Deno utilise SubtleCrypto (async) pour HMAC. Le SDK Stripe bloque
    // `constructEvent()` sync et impose `constructEventAsync()` dans ce runtime.
    // Cf. erreur : "SubtleCryptoProvider cannot be used in a synchronous context". ───
    for (const secret of secrets) {
      try {
        event = await stripe.webhooks.constructEventAsync(rawBody, sig, secret);
        break;
      } catch (err) {
        lastVerifyErr = err;
      }
    }
    if (!event) {
      const msg =
        lastVerifyErr instanceof Error ? lastVerifyErr.message : "unknown";
      console.error("Signature verification failed:", msg);
      return jsonResponse(
        { error: "signature_verification_failed", detail: msg },
        400,
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // ─── Idempotency : Stripe peut rejouer un event (retry sur 5xx, timeout
    // ou erreur réseau). `record_stripe_event` renvoie TRUE si l'event est
    // nouveau, FALSE s'il a déjà été traité. On renvoie 200 immédiatement
    // dans le second cas pour que Stripe arrête les retries, mais sans
    // réexécuter les side-effects (tickets, emails, sold_count). ───
    const { data: isNew, error: dedupErr } = await supabase.rpc(
      "record_stripe_event",
      { p_event_id: event.id, p_event_type: event.type },
    );
    if (dedupErr) {
      // Fail-safe : si la dédup n'est pas dispo, on continue mais on loggue.
      // Les guards de statut (.eq("status", "pending_payment")) atténuent
      // le risque sur le flux booking ; pour tickets c'est plus exposé.
      console.error("record_stripe_event failed:", dedupErr.message);
    } else if (isNew === false) {
      console.log(`[webhook] duplicate event ignored: ${event.id} (${event.type})`);
      return new Response(JSON.stringify({ received: true, duplicate: true }), {
        headers: { ...securityHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    switch (event.type) {
      case "payment_intent.succeeded": {
        const pi = event.data.object as Stripe.PaymentIntent;

        // ─── TIP FLOW (priority #3) ──────────────────────────
        // Tip PaymentIntents are created by the `process-tip` function with
        // metadata.spotbook_type = 'tip'. On success, mark the tip row as
        // succeeded and notify the pro. Tips have no Spotbook commission.
        if (pi.metadata.spotbook_type === "tip") {
          const tipBookingId = pi.metadata.booking_id;
          const proId = pi.metadata.pro_id;
          if (!tipBookingId || !isValidUuid(tipBookingId)) break;

          await supabase
            .from("tips")
            .update({
              status: "succeeded",
              completed_at: new Date().toISOString(),
            })
            .eq("stripe_payment_intent_id", pi.id)
            .eq("status", "pending");

          // Notify the pro that a tip was received
          if (proId && isValidUuid(proId)) {
            const amountDollars = (pi.amount / 100).toFixed(2);
            await supabase.from("notifications").insert({
              user_id: proId,
              type: "tip_received",
              title: "Pourboire reçu",
              body: `Tu as reçu ${amountDollars}$ de pourboire.`,
              resource_id: tipBookingId,
              idempotency_key: `${event.id}:tip_received:${proId}`,
            });
          }
          break;
        }

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

        // Sign QR code for booking — non-blocking
        let bookingQrCodeUrl: string | undefined;
        try {
          const { data: signData } = await supabase.functions.invoke(
            "sign-qr-booking",
            { body: { bookingId } },
          );
          bookingQrCodeUrl = signData?.qrCodeUrl;
        } catch (e) {
          console.error("QR signing failed for booking:", bookingId, e);
        }

        // Trigger payout via edge function
        try {
          await supabase.functions.invoke("process-payout", {
            body: { bookingId },
          });
        } catch (_) {
          // Payout failure is non-blocking for confirmation
        }

        // Priority #9 — Award loyalty points (idempotent, non-blocking).
        // The edge function checks the loyalty_programs row and only awards
        // if the pro has an active program. Safe to call on every confirmed
        // booking — double-calls are rejected by the ledger's unique check.
        try {
          await supabase.functions.invoke("award-loyalty", {
            body: { bookingId },
          });
        } catch (e) {
          console.error("award-loyalty failed:", bookingId, e);
        }

        // Priority #12 — Generate digital receipt (idempotent via UNIQUE
        // constraint on receipts.booking_id). This is the "source of truth"
        // record for the client's purchase — safe to call as soon as payment
        // succeeds (pre-service) because we snapshot line items at this moment.
        try {
          await supabase.functions.invoke("generate-receipt", {
            body: { bookingId },
          });
        } catch (e) {
          console.error("generate-receipt failed:", bookingId, e);
        }

        // Push notification + email to client
        const { data: booking } = await supabase
          .from("bookings")
          .select(
            "client_id, pro_id, booking_code, deposit_amount, " +
            "services(name), time_slots(date, start_time), " +
            "users!bookings_client_id_fkey(email, full_name), " +
            "profiles_pro!bookings_pro_id_fkey(business_name, address)"
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

          // Email — booking confirmed (with QR code)
          const clientUser = booking.users as Record<string, unknown> | null;
          const clientEmail = clientUser?.email as string | undefined;
          const clientName = clientUser?.full_name as string | undefined;
          const service = booking.services as Record<string, unknown> | null;
          const slot = booking.time_slots as Record<string, unknown> | null;
          const proProfile = booking.profiles_pro as Record<string, unknown> | null;

          if (clientEmail) {
            await sendEmail("booking_confirmed", clientEmail, {
              clientName: clientName ?? "Client",
              serviceName: service?.name ?? "Service",
              providerName: proProfile?.business_name ?? "",
              date: slot?.date ?? "",
              time: slot?.start_time ?? "",
              address: proProfile?.address ?? "",
              amountPaid: booking.deposit_amount
                ? Math.round(Number(booking.deposit_amount) * 100)
                : 0,
              bookingId,
              qrCodeUrl: bookingQrCodeUrl ?? undefined,
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

      /** Checkout Sessions (si utilisé) : fire-and-link. Les side-effects
       * (tickets, emails, notifications) sont gérés par `payment_intent.succeeded`
       * qui arrive en parallèle — ici on se contente de lier le PI à la réservation
       * et de logguer, pour couvrir le cas où Checkout est utilisé à la place de
       * PaymentSheet. */
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        // On n'agit que sur les sessions payées. Les `mode: 'setup'` ou
        // sessions expirées passent en no-op.
        if (session.payment_status !== "paid") break;

        const bookingId = session.metadata?.bookingId;
        const piId =
          typeof session.payment_intent === "string"
            ? session.payment_intent
            : session.payment_intent?.id;

        // Si la session porte un bookingId, on relie le PI (si pas déjà fait
        // par le flux PaymentSheet) pour garantir le lookup ultérieur.
        if (bookingId && isValidUuid(bookingId) && piId) {
          await supabase
            .from("bookings")
            .update({ stripe_payment_intent_id: piId })
            .eq("id", bookingId)
            .is("stripe_payment_intent_id", null);
        }

        await supabase.rpc("log_audit_action", {
          p_user_id:
            session.metadata?.userId ??
            session.metadata?.clientId ??
            null,
          p_action: "checkout_session_completed",
          p_resource_type: bookingId ? "booking" : "checkout",
          p_resource_id: bookingId ?? session.metadata?.eventId ?? null,
          p_metadata: {
            session_id: session.id,
            payment_intent_id: piId,
            amount_total: session.amount_total,
            mode: session.mode,
          },
        });
        break;
      }

      /** Transfer reversed : Stripe confirme qu'un virement déjà envoyé au pro
       * a été annulé (typiquement suite à `stripe.refunds.create({..., reverse_transfer: true})`
       * pour un remboursement >48h après le payout). Ici on met à jour la
       * réservation et on prévient le pro que l'argent a été repris. */
      case "transfer.reversed": {
        const transfer = event.data.object as Stripe.Transfer;

        type ReversalBooking = {
          id: string;
          client_id: string;
          pro_id: string;
          booking_code: string;
          refund_amount: number | null;
        };

        // Lookup direct via transfer_id (chemin nominal : on a stocké le
        // transfer_id lors de la création du transfer côté process-payout).
        let target: ReversalBooking | null = null;
        const { data: byTransfer } = await supabase
          .from("bookings")
          .select("id, client_id, pro_id, booking_code, refund_amount")
          .eq("transfer_id", transfer.id)
          .maybeSingle();

        if (byTransfer) {
          target = byTransfer as ReversalBooking;
          await supabase
            .from("bookings")
            .update({ refund_status: "reversed" })
            .eq("id", target.id);
        } else {
          // Fallback : résoudre via source_transaction → charge → PI.
          // Utile si le transfer_id n'a pas été persisté au moment du payout
          // (ancienne version de process-payout, ou race condition).
          const sourceTxn =
            typeof transfer.source_transaction === "string"
              ? transfer.source_transaction
              : transfer.source_transaction?.id;
          if (!sourceTxn) {
            console.error(
              "transfer.reversed: no transfer_id match and no source_transaction",
              transfer.id,
            );
            break;
          }
          try {
            const charge = await stripe.charges.retrieve(sourceTxn);
            const piId =
              typeof charge.payment_intent === "string"
                ? charge.payment_intent
                : charge.payment_intent?.id;
            if (!piId) break;
            const { data: byPi } = await supabase
              .from("bookings")
              .select("id, client_id, pro_id, booking_code, refund_amount")
              .eq("stripe_payment_intent_id", piId)
              .maybeSingle();
            if (!byPi) break;
            target = byPi as ReversalBooking;
            // Persiste le transfer_id + marque reversed pour cohérence future.
            await supabase
              .from("bookings")
              .update({
                transfer_id: transfer.id,
                refund_status: "reversed",
              })
              .eq("id", target.id);
          } catch (e) {
            console.error("transfer.reversed: charge retrieve failed:", e);
            break;
          }
        }

        if (target) {
          await supabase.rpc("log_audit_action", {
            p_user_id: target.client_id,
            p_action: "transfer_reversed",
            p_resource_type: "booking",
            p_resource_id: target.id,
            p_metadata: {
              transfer_id: transfer.id,
              amount_reversed: transfer.amount_reversed,
              currency: transfer.currency,
            },
          });

          // Notifie le pro (son argent a été repris)
          await supabase.from("notifications").insert({
            user_id: target.pro_id,
            type: "transfer_reversed",
            title: "Virement annulé",
            body: `Un virement lié à ${target.booking_code} a été annulé suite à un remboursement.`,
            resource_id: target.id,
            idempotency_key: `${event.id}:transfer_reversed:${target.pro_id}`,
          });
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
    const msg = error instanceof Error ? error.message : String(error);
    const name = error instanceof Error ? error.name : "UnknownError";
    console.error("Webhook error:", name, msg, error);
    return jsonResponse(
      { error: "webhook_processing_failed", name, detail: msg },
      400,
    );
  }
});
