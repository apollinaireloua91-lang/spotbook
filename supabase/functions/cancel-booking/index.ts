import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  checkRateLimit,
  getClientIp,
  isValidUuid,
  jsonResponse,
  securityHeaders,
} from "../_shared/security.ts";
import { sendResendEmail } from "../_shared/send_resend_email.ts";

const corsHeaders = securityHeaders;

// ── Paramètres policy ──────────────────────────────────────────────────────
// Documenté dans CLAUDE.md. 'moderate' est la politique par défaut depuis
// que 'flexible' a été retiré (cf. 20260420170000_remove_flexible_cancellation).
//
// ⚠ NE PAS CONFONDRE avec le seuil de 48h lié au payout Stripe (au-delà de
// 48h, les fonds sont transférés au pro → un refund nécessite un
// `transfers.createReversal`). Ce code gère justement ce cas en L144-149.
// Le seuil ci-dessous concerne uniquement la fraction remboursée au client.
const POLICY = {
  moderate: {
    hoursThreshold: 24,
    aboveRefundFraction: 1.0, // >24h : 100 %
    belowRefundFraction: 0.5, // ≤24h : 50 %
  },
  strict: {
    hoursThreshold: 0,
    aboveRefundFraction: 0.0, // 0 % dans tous les cas
    belowRefundFraction: 0.0,
  },
} as const;

// ── Type du row de query avec FK embeds ───────────────────────────────────
// Cast explicite : Supabase SDK ne résout pas les FK embeds typés (bug connu
// v2.x) — sans ce cast, tous les champs reviennent comme `GenericStringError`
// et cascade dans l'ensemble du handler. Champs listés explicitement (au
// lieu de `*`) pour documenter ce que le reste du handler consomme.
interface CancelBookingRow {
  id: string;
  client_id: string;
  pro_id: string;
  status: string;
  deposit_amount: number | null;
  booking_code: string;
  stripe_payment_intent_id: string | null;
  transfer_id: string | null;
  time_slot_id: string | null;
  time_slots: { date: string | null; start_time: string | null } | null;
  services: {
    cancellation_policy: string | null;
    name: string | null;
  } | null;
  client: { email: string | null } | null;
  pro: { email: string | null } | null;
  profiles_pro: { business_name: string | null } | null;
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

    const { bookingId } = await req.json();
    if (!bookingId || !isValidUuid(String(bookingId))) {
      return jsonResponse({ error: "bookingId doit être un UUID valide" }, 400);
    }

    // Rate limit : 5 annulations / minute par user+IP. Protège contre les
    // boucles accidentelles (refresh bouton) et les tentatives de race
    // avec le refund Stripe. Key composite user+ip évite qu'un user
    // bypass en changeant d'IP seul, ou inversement.
    try {
      const rl = await checkRateLimit({
        scope: "booking",
        key: `cancel:${user.id}:${getClientIp(req)}`,
      });
      if (!rl.allowed) {
        return jsonResponse(
          {
            error: "rate_limited",
            retryInMinutes: rl.retryInMinutes,
          },
          429,
        );
      }
    } catch (rlErr) {
      // Best-effort — si le rate limiter est KO, on laisse passer plutôt
      // que bloquer une annulation légitime.
      console.warn("cancel-booking rate limiter error", (rlErr as Error).message);
    }

    // Fetch booking with service cancellation policy
    const { data: bookingRaw, error: bErr } = await supabase
      .from("bookings")
      .select(
        "id, client_id, pro_id, status, deposit_amount, booking_code, " +
        "stripe_payment_intent_id, transfer_id, time_slot_id, " +
        "time_slots(date, start_time), " +
        "services(cancellation_policy, name), " +
        "client:users!bookings_client_id_fkey(email), " +
        "pro:users!bookings_pro_id_fkey(email), " +
        "profiles_pro!bookings_pro_id_fkey(business_name)"
      )
      .eq("id", bookingId)
      .single();

    // Cast explicite : Supabase SDK ne résout pas les FK embeds typés (bug
    // connu v2.x).
    const booking = bookingRaw as unknown as CancelBookingRow | null;

    if (bErr || !booking) {
      return jsonResponse({ error: "booking_not_found" }, 404);
    }

    // Verify ownership (client or pro)
    if (booking.client_id !== user.id && booking.pro_id !== user.id) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    // Only allow cancellation from valid states
    const cancellableStatuses = ["confirmed", "pending_payment"];
    if (!cancellableStatuses.includes(booking.status)) {
      return jsonResponse(
        { error: "booking_not_cancellable", currentStatus: booking.status },
        400
      );
    }

    // Calculate hours until appointment
    const slotDate = new Date(
      `${booking.time_slots?.date ?? ""}T${booking.time_slots?.start_time ?? "00:00:00"}`
    );
    const hoursUntil =
      (slotDate.getTime() - Date.now()) / (1000 * 60 * 60);

    // Determine cancellation policy via la table POLICY (haut du fichier).
    // 'flexible' a été retiré en migration 20260420170000 — toute valeur
    // non reconnue tombe sur 'moderate' par défaut.
    const rawPolicy = booking.services?.cancellation_policy ?? "moderate";
    const policy = (rawPolicy === "strict" ? "strict" : "moderate") as keyof typeof POLICY;
    const params = POLICY[policy];

    const fraction = hoursUntil > params.hoursThreshold
      ? params.aboveRefundFraction
      : params.belowRefundFraction;
    const refundAmount =
      Math.round((booking.deposit_amount ?? 0) * fraction * 100) / 100;

    let newStatus: string;
    if (fraction >= 1) {
      newStatus = "cancelled_full_refund";
    } else if (fraction <= 0) {
      newStatus = "cancelled_no_refund";
    } else {
      newStatus = "cancelled_partial_refund";
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    // ── STEP 1 — Atomic DB flip FIRST ──
    // On "claime" la cancellation avant d'appeler Stripe. Si un second appel
    // concurrent arrive, il échouera ici (WHERE status IN cancellable) et ne
    // déclenchera PAS de refund. L'ordre DB-first évite les remboursements
    // orphelins quand la DB tombe après un refund réussi.
    const refundStatus = refundAmount > 0 ? "pending" : "no_refund";
    const { data: updatedRows, error: updateErr } = await supabase
      .from("bookings")
      .update({
        status: newStatus,
        refund_amount: refundAmount,
        refund_status: refundStatus,
      })
      .eq("id", bookingId)
      .in("status", cancellableStatuses)
      .select("id");

    if (updateErr || !updatedRows?.length) {
      return jsonResponse({ error: "booking_already_cancelled" }, 409);
    }

    // ── STEP 2 — Refund via Stripe (winner only) ──
    // Si cet appel échoue : la booking est déjà marquée cancelled avec
    // refund_status='pending' — un worker de réconciliation peut rejouer
    // le refund via l'idempotency key sans risque de double débit.
    if (refundAmount > 0 && booking.stripe_payment_intent_id) {
      const refundAmountCents = Math.round(refundAmount * 100);
      try {
        await stripe.refunds.create(
          {
            payment_intent: booking.stripe_payment_intent_id,
            amount: refundAmountCents,
          },
          { idempotencyKey: `refund-${bookingId}` },
        );

        if (booking.transfer_id) {
          await stripe.transfers.createReversal(
            booking.transfer_id,
            { amount: refundAmountCents },
            { idempotencyKey: `reversal-${bookingId}` },
          );
        }

        await supabase
          .from("bookings")
          .update({ refund_status: "refunded" })
          .eq("id", bookingId);

        await supabase.rpc("log_audit_action", {
          p_user_id: user.id,
          p_action: "refund_initiated",
          p_resource_type: "booking",
          p_resource_id: bookingId,
          p_metadata: { refund_amount: refundAmount, policy },
        });
      } catch (refundErr) {
        console.error(
          JSON.stringify({
            level: "error",
            code: "REFUND_PENDING_RETRY",
            message: "Booking cancelled but Stripe refund failed — needs retry",
            bookingId,
            paymentIntentId: booking.stripe_payment_intent_id,
            error: (refundErr as Error).message,
          }),
        );
        // On ne re-throw pas : la booking EST cancelled, et refund_status
        // reste 'pending' pour que le worker de reco retry avec la même clé.
      }
    }
    await supabase.rpc("log_audit_action", {
      p_user_id: user.id,
      p_action: "booking_cancelled",
      p_resource_type: "booking",
      p_resource_id: bookingId,
      p_metadata: { status: newStatus },
    });

    // Release the time slot
    await supabase
      .from("time_slots")
      .update({ is_available: true, locked_by: null })
      .eq("id", booking.time_slot_id);

    // ─── Emails : notifier la contre-partie ──────────────────────────────
    // Best-effort. Deux branches selon qui a initié l'annulation :
    //   - user.id === booking.client_id → email au Pro (`pro_cancellation_by_client`)
    //   - user.id === booking.pro_id    → email au Client (`appointment_cancelled_by_pro`)
    try {
      if (user.id === booking.client_id) {
        const proEmail = booking.pro?.email ?? null;
        if (proEmail) {
          await sendResendEmail({
            event: "pro_cancellation_by_client",
            to: proEmail,
            variables: {
              bookingCode: booking.booking_code ?? "",
              bookingId,
              serviceName: booking.services?.name ?? "Service",
              date: booking.time_slots?.date ?? "",
              time: booking.time_slots?.start_time ?? "",
              refundAmount: Math.round(refundAmount * 100),
              refundFraction: fraction,
            },
          });
        }
      } else if (user.id === booking.pro_id) {
        const clientEmail = booking.client?.email ?? null;
        if (clientEmail) {
          await sendResendEmail({
            event: "appointment_cancelled_by_pro",
            to: clientEmail,
            variables: {
              bookingCode: booking.booking_code ?? "",
              bookingId,
              serviceName: booking.services?.name ?? "votre prestation",
              providerName: booking.profiles_pro?.business_name ?? "",
              date: booking.time_slots?.date ?? "",
              time: booking.time_slots?.start_time ?? "",
              refundAmount: Math.round(refundAmount * 100),
            },
          });
        }
      }
    } catch (emailErr) {
      console.warn(
        "cancel-booking email dispatch failed",
        (emailErr as Error).message,
      );
    }

    // Réponse enrichie : UI peut afficher exactement ce qui a été retenu
    // (politique, seuil, fraction, montant). Évite que le client doive
    // re-calculer 48h vs 24h côté Flutter.
    return new Response(
      JSON.stringify({
        success: true,
        status: newStatus,
        hoursUntil: Math.round(hoursUntil),
        policy,
        hoursThreshold: params.hoursThreshold,
        refundFraction: fraction,
        refundAmount,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("cancel-booking error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
