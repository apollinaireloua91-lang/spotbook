import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  jsonResponse,
  securityHeaders,
  isValidUuid,
} from "../_shared/security.ts";
import { sendResendEmail } from "../_shared/send_resend_email.ts";

// ── Types de résultats pour les selects avec FK embeds ─────────────────────
// Cast explicite : Supabase SDK ne résout pas les FK embeds typés (bug connu
// v2.x) — sans ce cast, tous les champs reviennent comme `GenericStringError`
// et cascade dans tout le switch. On préserve la shape réelle de chaque query.
interface BookingConfirmedRow {
  client_id: string;
  pro_id: string;
  booking_code: string;
  deposit_amount: number | null;
  payment_mode: "full" | "deposit" | null;
  remaining_amount: number | null;
  services: { name: string | null } | null;
  time_slots: { date: string | null; start_time: string | null } | null;
  users: { email: string | null; full_name: string | null } | null;
  profiles_pro: { business_name: string | null; address: string | null } | null;
}

interface RefundBookingRow {
  id: string;
  client_id: string;
  booking_code: string;
  deposit_amount: number | null;
  services: { name: string | null } | null;
  users: { email: string | null } | null;
}

interface PaymentFailedBookingRow {
  time_slot_id: string | null;
  client_id: string;
  booking_code: string;
  users: { email: string | null } | null;
  services: { name: string | null } | null;
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
            await sendResendEmail({
              event: "ticket_purchased",
              to: buyerUser.email,
              variables: {
                clientName: buyerUser.full_name ?? "Client",
                eventName: eventTitle,
                eventDate: eventData?.event_date ?? "",
                venue: eventData?.location ?? "",
                ticketId: firstTicketId ?? "",
                qrCodeUrl: firstQrCodeUrl ?? undefined,
              },
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
        const { data: bookingRaw } = await supabase
          .from("bookings")
          .select(
            "client_id, pro_id, booking_code, deposit_amount, " +
            "payment_mode, remaining_amount, " +
            "services(name), time_slots(date, start_time), " +
            "users!bookings_client_id_fkey(email, full_name), " +
            "profiles_pro!bookings_pro_id_fkey(business_name, address)"
          )
          .eq("id", bookingId)
          .single();

        // Cast explicite : Supabase SDK ne résout pas les FK embeds typés
        // (bug connu v2.x).
        const booking = bookingRaw as unknown as BookingConfirmedRow | null;

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
          const clientEmail = booking.users?.email ?? undefined;
          const clientName = booking.users?.full_name ?? undefined;
          const service = booking.services;
          const slot = booking.time_slots;
          const proProfile = booking.profiles_pro;

          if (clientEmail) {
            // Dédup booking_confirmed (décision Commit 3) : scission explicite
            // entre « Pro accepte la demande » (update-booking-status) et
            // « paiement capturé + RDV verrouillé » (ici). Le template Resend
            // `booking-paid-and-confirmed` n'existe pas encore côté dashboard —
            // fallback HTML via `bookingConfirmed` en attendant (cf.
            // APOLLINAIRE_TODO §22).
            await sendResendEmail({
              event: "booking_paid_and_confirmed",
              to: clientEmail,
              variables: {
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
              },
            });

            // Payment receipt — scindé par mode (décision 4.2).
            // full   → `payment_receipt_full`  template `reu-de-paiement`
            // deposit → `payment_receipt_deposit` template `acompte-reu` (affiche le solde restant)
            const isDeposit = booking.payment_mode === "deposit";
            await sendResendEmail({
              event: isDeposit ? "payment_receipt_deposit" : "payment_receipt_full",
              to: clientEmail,
              variables: {
                amount: booking.deposit_amount
                  ? Number(booking.deposit_amount).toFixed(2)
                  : "0",
                currency: pi.currency?.toUpperCase() ?? "CAD",
                description: isDeposit
                  ? `Acompte — ${service?.name ?? "Réservation"}`
                  : `Paiement — ${service?.name ?? "Réservation"}`,
                bookingCode: booking.booking_code,
                // Exposé au template `acompte-reu` pour afficher le solde à payer.
                remainingAmount: booking.remaining_amount
                  ? Number(booking.remaining_amount).toFixed(2)
                  : undefined,
              },
            });
          }

          // ─── Email Pro : `pro_new_booking` ─────────────────────
          // Résolu via query séparée (pro_id → users.email). Éviter le nested
          // embed dans la query bookings pour ne pas casser l'inferrer de
          // types (cf. commentaire sur BookingConfirmedRow).
          const { data: proUser } = await supabase
            .from("users")
            .select("email, full_name")
            .eq("id", booking.pro_id)
            .maybeSingle();
          const proEmail =
            (proUser?.email as string | null | undefined) ?? undefined;
          if (proEmail) {
            await sendResendEmail({
              event: "pro_new_booking",
              to: proEmail,
              variables: {
                clientName: clientName ?? "Client",
                serviceName: service?.name ?? "Service",
                providerName: proProfile?.business_name ?? "",
                date: slot?.date ?? "",
                time: slot?.start_time ?? "",
                address: proProfile?.address ?? "",
                amountPaid: booking.deposit_amount
                  ? Math.round(Number(booking.deposit_amount) * 100)
                  : 0,
                bookingCode: booking.booking_code,
                bookingId,
              },
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

        // Fetch booking to get slot + client email for notification
        const { data: paymentFailedBookingRaw } = await supabase
          .from("bookings")
          .select(
            "time_slot_id, client_id, booking_code, " +
            "users!bookings_client_id_fkey(email), services(name)"
          )
          .eq("id", bookingId)
          .single();

        // Cast explicite : Supabase SDK ne résout pas les FK embeds typés
        // (bug connu v2.x).
        const booking = paymentFailedBookingRaw as
          unknown as PaymentFailedBookingRow | null;

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

          // Email client — `payment_failed` (alias `paiement-chou`).
          const failedClientEmail = booking.users?.email ?? undefined;
          if (failedClientEmail) {
            await sendResendEmail({
              event: "payment_failed",
              to: failedClientEmail,
              variables: {
                serviceName: booking.services?.name ?? "Service",
                bookingCode: booking.booking_code,
                bookingId,
                // `failure_reason` n'est pas toujours présent sur le PI côté
                // Stripe (rate-limit, réseau) — on remonte ce qu'on a, le
                // template affiche un fallback générique si vide.
                reason:
                  pi.last_payment_error?.message ??
                  "Le paiement n'a pas pu être traité.",
              },
            });
          }
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

        const { data: refundBookingRaw } = await supabase
          .from("bookings")
          .select(
            "id, client_id, booking_code, deposit_amount, " +
            "services(name), users!bookings_client_id_fkey(email)"
          )
          .eq("stripe_payment_intent_id", piId)
          .single();

        // Cast explicite : Supabase SDK ne résout pas les FK embeds typés
        // (bug connu v2.x).
        const booking = refundBookingRaw as unknown as RefundBookingRow | null;

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

          // Email — remboursement confirmé (décision 4.1 Option B).
          // Event distinct de `booking_cancelled` : l'annulation elle-même est
          // notifiée au moment de l'action (cancel-booking / rejet pro) ; ce
          // chemin-ci confirme uniquement que Stripe a traité le refund.
          const refundEmail = booking.users?.email ?? undefined;

          if (refundEmail) {
            await sendResendEmail({
              event: "refund_completed",
              to: refundEmail,
              variables: {
                serviceName: booking.services?.name ?? "Service",
                bookingCode: booking.booking_code,
                refundAmount: booking.deposit_amount
                  ? Number(booking.deposit_amount).toFixed(2)
                  : undefined,
              },
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

          // Email pro — `pro_transfer_reversed` (pas d'alias Resend publié,
          // fallback HTML via `bookingCancelled`. Cf. APOLLINAIRE_TODO §22).
          const { data: proUserRev } = await supabase
            .from("users")
            .select("email")
            .eq("id", target.pro_id)
            .maybeSingle();
          const proEmailRev =
            (proUserRev?.email as string | null | undefined) ?? undefined;
          if (proEmailRev) {
            await sendResendEmail({
              event: "pro_transfer_reversed",
              to: proEmailRev,
              variables: {
                bookingCode: target.booking_code,
                amountReversed: transfer.amount_reversed != null
                  ? (transfer.amount_reversed / 100).toFixed(2)
                  : undefined,
                currency: transfer.currency?.toUpperCase() ?? "CAD",
                transferId: transfer.id,
                bookingId: target.id,
              },
            });
          }
        }
        break;
      }

      /** Payout settled : Stripe a déposé les fonds sur le compte bancaire du
       * Pro (via le schedule de payout configuré au niveau de son compte
       * Connect). Event distinct du `transfer` (qui, lui, déplace des fonds
       * dans la balance Connect) : ici on notifie que l'argent est
       * effectivement arrivé. Lookup indirect : payout → account → Pro. */
      case "payout.paid": {
        const payout = event.data.object as Stripe.Payout;
        // Les events Connect portent `account` au niveau du wrapper, pas du
        // payload. On remonte via `(event as any).account` pour éviter de
        // dépendre d'un type strict Stripe absent de cette version SDK.
        const connectAccountId =
          (event as unknown as { account?: string }).account ?? undefined;
        if (!connectAccountId) {
          // Payout sur la plateforme elle-même (pas un Pro) — ignore.
          break;
        }

        const { data: proProfile } = await supabase
          .from("profiles_pro")
          .select("id, business_name")
          .eq("stripe_account_id", connectAccountId)
          .maybeSingle();

        const proId = proProfile?.id as string | undefined;
        if (!proId) break;

        const { data: proUserPayout } = await supabase
          .from("users")
          .select("email")
          .eq("id", proId)
          .maybeSingle();
        const proEmailPayout =
          (proUserPayout?.email as string | null | undefined) ?? undefined;

        await supabase.rpc("log_audit_action", {
          p_user_id: proId,
          p_action: "pro_payout_sent",
          p_resource_type: "payout",
          p_resource_id: payout.id,
          p_metadata: {
            amount: payout.amount,
            currency: payout.currency,
            arrival_date: payout.arrival_date,
          },
        });

        if (proEmailPayout) {
          await sendResendEmail({
            event: "pro_payout_sent",
            to: proEmailPayout,
            variables: {
              amount: (payout.amount / 100).toFixed(2),
              currency: payout.currency?.toUpperCase() ?? "CAD",
              arrivalDate: payout.arrival_date
                ? new Date(payout.arrival_date * 1000)
                  .toISOString()
                  .split("T")[0]
                : "",
              payoutId: payout.id,
            },
          });
        }
        break;
      }

      /** Connect Express : garde `profiles_pro.stripe_onboarded` aligné sur Stripe.
       *  Détection edge-triggered false→true pour envoyer `pro_stripe_connect_activated`
       *  une seule fois (Stripe pingue `account.updated` très fréquemment). */
      case "account.updated": {
        const account = event.data.object as Stripe.Account;
        const stripeAccountId = account.id;
        if (!stripeAccountId) break;

        const onboarded =
          account.details_submitted === true &&
          account.charges_enabled === true &&
          account.payouts_enabled === true;

        // Lecture de l'état actuel pour détecter la transition false→true.
        // Si la ligne n'existe pas (pro pas encore inscrit dans profiles_pro),
        // on laisse l'update no-op plus bas et on ne tente pas d'envoyer l'email.
        const { data: currentRow, error: readErr } = await supabase
          .from("profiles_pro")
          .select("user_id, stripe_onboarded, business_name")
          .eq("stripe_account_id", stripeAccountId)
          .maybeSingle();

        if (readErr) {
          console.error(
            "account.updated profiles_pro read:",
            readErr.message,
          );
        }

        const previousOnboarded = (currentRow as
          | { stripe_onboarded: boolean | null }
          | null)?.stripe_onboarded ?? false;

        const { error: updErr } = await supabase
          .from("profiles_pro")
          .update({ stripe_onboarded: onboarded })
          .eq("stripe_account_id", stripeAccountId);

        if (updErr) {
          console.error("account.updated profiles_pro:", updErr.message);
        }

        // Email edge-triggered : uniquement sur transition false→true.
        // Évite les envois répétés sur chaque `account.updated` (Stripe les
        // émet aussi pour des changements mineurs du profil du Pro).
        if (!previousOnboarded && onboarded && currentRow) {
          const proUserId = (currentRow as { user_id: string }).user_id;
          const businessName = (currentRow as { business_name: string | null })
            .business_name ?? "";
          const { data: proUserRaw } = await supabase
            .from("users")
            .select("email, full_name")
            .eq("id", proUserId)
            .maybeSingle();
          const proUser = proUserRaw as
            | { email: string | null; full_name: string | null }
            | null;
          if (proUser?.email) {
            await sendResendEmail({
              event: "pro_stripe_connect_activated",
              to: proUser.email,
              variables: {
                fullName: proUser.full_name ?? "",
                businessName,
                stripeAccountId,
              },
            });
            await supabase.rpc("log_audit_action", {
              p_user_id: proUserId,
              p_action: "pro_stripe_connect_activated_notified",
              p_resource_type: "profiles_pro",
              p_resource_id: proUserId,
              p_metadata: { stripe_account_id: stripeAccountId },
            });
          }
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
