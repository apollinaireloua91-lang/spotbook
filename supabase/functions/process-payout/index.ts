// ════════════════════════════════════════════════════════════════════════════
// process-payout — RECONCILER (mode Option A)
// ────────────────────────────────────────────────────────────────────────────
// Spotbook a choisi `transfer_data` sur la création du PaymentIntent : le
// transfer vers le pro se fait AUTOMATIQUEMENT par Stripe lors du capture.
//
// Cette fonction ne crée JAMAIS de nouveau transfer. Elle sert uniquement à :
//   1. Retrouver le transfer_id auto-créé par Stripe (via le charge du PI)
//   2. L'enregistrer sur bookings.transfer_id (TOCTOU guard via WHERE IS NULL)
//   3. Logger un audit action pour tracabilité
//
// Appel : service role uniquement (webhook Stripe "charge.succeeded" ou cron
// de réconciliation). Refuse les appels clients.
// ════════════════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  assertServiceRoleOnly,
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";
import { sendResendEmail } from "../_shared/send_resend_email.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    const forbidden = assertServiceRoleOnly(req);
    if (forbidden) return forbidden;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { bookingId } = await req.json();
    if (!bookingId || !isValidUuid(String(bookingId))) {
      return jsonResponse(
        { error: "bookingId doit être un UUID valide" },
        400,
        undefined,
        req,
      );
    }

    const { data: booking, error: bErr } = await supabase
      .from("bookings")
      .select(
        "id, status, pro_id, transfer_id, stripe_payment_intent_id, booking_code, deposit_amount",
      )
      .eq("id", bookingId)
      .single();

    if (bErr || !booking) {
      return jsonResponse({ error: "booking_not_found" }, 404, undefined, req);
    }

    // Idempotence : si déjà réconcilié, on renvoie le transfer_id existant.
    if (booking.transfer_id) {
      return jsonResponse(
        {
          success: true,
          transferId: booking.transfer_id,
          reconciled: true,
          alreadyRecorded: true,
        },
        200,
        undefined,
        req,
      );
    }

    if (!booking.stripe_payment_intent_id) {
      return jsonResponse(
        { error: "no_payment_intent" },
        400,
        undefined,
        req,
      );
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    // Récupération du PaymentIntent avec son charge pour extraire le
    // transfer auto-créé par Stripe (via transfer_data à la création).
    const pi = await stripe.paymentIntents.retrieve(
      booking.stripe_payment_intent_id,
      { expand: ["latest_charge"] },
    );

    // Le transfer n'existe qu'après capture réussi du PI.
    if (pi.status !== "succeeded") {
      return jsonResponse(
        {
          error: "payment_not_captured",
          paymentStatus: pi.status,
        },
        409,
        undefined,
        req,
      );
    }

    const latestCharge = pi.latest_charge as Stripe.Charge | null;
    const transferId = latestCharge?.transfer
      ? (typeof latestCharge.transfer === "string"
        ? latestCharge.transfer
        : latestCharge.transfer.id)
      : null;

    if (!transferId) {
      // Cas anormal : PI succeeded sans transfer. Probablement un booking
      // sans stripe_account_id côté pro au moment de la création (pro pas
      // encore onboardé Stripe Connect). On log pour investigation manuelle.
      console.error(
        JSON.stringify({
          level: "warn",
          code: "PAYOUT_NO_TRANSFER_FOUND",
          message:
            "PI capturé mais pas de transfer — pro probablement non-onboardé à la création",
          bookingId: booking.id,
          paymentIntentId: pi.id,
        }),
      );
      return jsonResponse(
        {
          error: "no_transfer_found",
          paymentIntentId: pi.id,
          hint:
            "Le PaymentIntent a été capturé sans transfer_data — vérifier que le pro était onboardé Stripe Connect au moment de la création du booking",
        },
        409,
        undefined,
        req,
      );
    }

    // Enregistrement atomique : WHERE transfer_id IS NULL évite l'écrasement
    // d'un transfer_id déjà posé par un appel concurrent.
    const { data: updatedRows, error: updateErr } = await supabase
      .from("bookings")
      .update({ transfer_id: transferId })
      .eq("id", bookingId)
      .is("transfer_id", null)
      .select("id");

    if (updateErr) {
      console.error("process-payout: DB update failed", updateErr.message);
      return jsonResponse({ error: "db_update_failed" }, 500, undefined, req);
    }

    // Si aucune ligne modifiée : un autre worker a gagné la course — c'est OK.
    const raceLost = !updatedRows?.length;

    await supabase.rpc("log_audit_action", {
      p_user_id: booking.pro_id,
      p_action: "pro_payout_reconciled",
      p_resource_type: "booking",
      p_resource_id: booking.id,
      p_metadata: { transfer_id: transferId, race_lost: raceLost },
    });

    // ─── Email Pro : paiement reçu (transfer vers compte Connect) ────────
    // Best-effort : si l'email échoue, la réconcilation reste valide.
    // Si `raceLost`, on n'envoie pas (un autre worker a déjà notifié).
    if (!raceLost) {
      try {
        const { data: proUser } = await supabase
          .from("users")
          .select("email")
          .eq("id", booking.pro_id)
          .maybeSingle();
        const proEmail = (proUser as { email: string | null } | null)?.email;
        if (proEmail) {
          await sendResendEmail({
            event: "pro_payment_received",
            to: proEmail,
            variables: {
              bookingCode: booking.booking_code ?? "",
              bookingId: booking.id,
              transferId,
              amount: booking.deposit_amount
                ? Math.round(Number(booking.deposit_amount) * 100)
                : 0,
              currency: "cad",
            },
          });
        }
      } catch (emailErr) {
        console.warn(
          "process-payout: pro_payment_received email failed",
          (emailErr as Error).message,
        );
      }
    }

    return jsonResponse(
      {
        success: true,
        transferId,
        reconciled: true,
        raceLost,
      },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("process-payout error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
