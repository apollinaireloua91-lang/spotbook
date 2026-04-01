import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
  sanitizeText,
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

/**
 * update-booking-status — Server-side booking state machine.
 *
 * Replaces direct .update() calls from Flutter so that status transitions
 * are validated, audit-logged, and notifications are sent atomically.
 *
 * Body: { bookingId: string, action: "accept" | "decline" | "complete", reason?: string }
 */

const VALID_TRANSITIONS: Record<string, Record<string, string>> = {
  // current status → { action → new status }
  pending: { accept: "confirmed", decline: "rejected" },
  pending_payment: { accept: "confirmed", decline: "rejected" },
  confirmed: { complete: "completed" },
  // mark_remaining_paid is valid only on completed bookings
  completed: { mark_remaining_paid: "completed" },
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }

  try {
    // ─── Auth ──────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );
    const {
      data: { user },
    } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    // ─── Parse & validate input ────────────────────────────────
    const { bookingId, action, reason } = await req.json();

    if (!bookingId || !isValidUuid(String(bookingId))) {
      return jsonResponse(
        { error: "bookingId must be a valid UUID" },
        400,
        undefined,
        req
      );
    }

    const validActions = ["accept", "decline", "complete", "mark_remaining_paid"];
    if (!action || !validActions.includes(action)) {
      return jsonResponse(
        { error: `action must be one of: ${validActions.join(", ")}` },
        400,
        undefined,
        req
      );
    }

    // ─── Fetch booking (service_role to bypass RLS) ────────────
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { data: booking, error: bErr } = await supabase
      .from("bookings")
      .select(
        "id, status, client_id, pro_id, service_id, time_slot_id, deposit_amount, booking_code, " +
        "payment_mode, remaining_amount, remaining_payment_status, " +
        "stripe_payment_intent_id, transfer_id, " +
        "services(name), time_slots(date, start_time), " +
        "users!bookings_client_id_fkey(email), " +
        "profiles_pro!bookings_pro_id_fkey(business_name)"
      )
      .eq("id", bookingId)
      .single();

    if (bErr || !booking) {
      return jsonResponse(
        { error: "booking_not_found" },
        404,
        undefined,
        req
      );
    }

    // ─── Verify caller is the pro ──────────────────────────────
    if (booking.pro_id !== user.id) {
      return jsonResponse(
        { error: "only the provider can update booking status" },
        403,
        undefined,
        req
      );
    }

    // ─── Validate state transition ─────────────────────────────
    const transitions = VALID_TRANSITIONS[booking.status];
    if (!transitions || !transitions[action]) {
      return jsonResponse(
        {
          error: `cannot ${action} a booking with status '${booking.status}'`,
          current_status: booking.status,
          allowed_actions: transitions ? Object.keys(transitions) : [],
        },
        400,
        undefined,
        req
      );
    }

    const newStatus = transitions[action];

    // ─── Handle mark_remaining_paid (special case — no status change) ───
    if (action === "mark_remaining_paid") {
      if (booking.payment_mode !== "deposit") {
        return jsonResponse(
          { error: "booking is not in deposit mode" },
          400,
          undefined,
          req
        );
      }
      if (booking.remaining_payment_status === "paid_on_site") {
        return jsonResponse(
          { error: "remaining already marked as paid" },
          400,
          undefined,
          req
        );
      }

      const { error: rpErr } = await supabase
        .from("bookings")
        .update({ remaining_payment_status: "paid_on_site" })
        .eq("id", bookingId);

      if (rpErr) {
        console.error("mark_remaining_paid failed:", rpErr);
        return jsonResponse(
          { error: "update_failed" },
          500,
          undefined,
          req
        );
      }

      await supabase.rpc("log_audit_action", {
        p_user_id: user.id,
        p_action: "booking_remaining_paid",
        p_resource_type: "booking",
        p_resource_id: bookingId,
        p_metadata: { remaining_amount: booking.remaining_amount },
      });

      // Notify client that remaining was collected
      await supabase.from("notifications").insert({
        user_id: booking.client_id,
        type: "booking_remaining_paid",
        title: "Paiement du solde confirmé",
        body: `Le prestataire a confirmé la réception du solde de ${Number(booking.remaining_amount).toFixed(2)} $ sur place.`,
        resource_id: bookingId,
      });

      return jsonResponse(
        { success: true, status: "completed", remaining_payment_status: "paid_on_site" },
        200,
        undefined,
        req
      );
    }

    // ─── Update booking ────────────────────────────────────────
    const updateData: Record<string, unknown> = { status: newStatus };

    if (newStatus === "rejected" && reason) {
      updateData.rejection_reason = sanitizeText(reason);
    }
    if (newStatus === "completed") {
      updateData.completed_at = new Date().toISOString();
    }

    const { error: updateErr } = await supabase
      .from("bookings")
      .update(updateData)
      .eq("id", bookingId);

    if (updateErr) {
      console.error("booking update failed:", updateErr);
      return jsonResponse(
        { error: "update_failed" },
        500,
        undefined,
        req
      );
    }

    // ─── Notify client ─────────────────────────────────────────
    const titles: Record<string, string> = {
      confirmed: "Réservation confirmée",
      rejected: "Réservation refusée",
      completed: "Service terminé",
    };
    const bodies: Record<string, string> = {
      confirmed: "Votre réservation a été confirmée par le prestataire.",
      rejected: reason
        ? `Votre réservation a été refusée : ${sanitizeText(reason)}`
        : "Votre réservation a été refusée par le prestataire.",
      completed:
        "Le service est terminé. N'hésitez pas à laisser un avis !",
    };

    await supabase.from("notifications").insert({
      user_id: booking.client_id,
      type: `booking_${newStatus}`,
      title: titles[newStatus] ?? "Mise à jour réservation",
      body: bodies[newStatus] ?? `Statut mis à jour : ${newStatus}`,
      resource_id: bookingId,
    });

    // ─── Email to client ─────────────────────────────────────────
    const clientUser = booking.users as Record<string, unknown> | null;
    const clientEmail = clientUser?.email as string | undefined;
    const service = booking.services as Record<string, unknown> | null;
    const slot = booking.time_slots as Record<string, unknown> | null;
    const proProfile = booking.profiles_pro as Record<string, unknown> | null;

    if (clientEmail) {
      if (newStatus === "confirmed") {
        await sendEmail("booking_confirmed", clientEmail, {
          serviceName: service?.name ?? "Service",
          proName: proProfile?.business_name ?? "",
          date: slot?.date ?? "",
          time: slot?.start_time ?? "",
          bookingCode: booking.booking_code ?? "",
          amount: booking.deposit_amount
            ? (Number(booking.deposit_amount) / 100).toFixed(2)
            : "",
        });
      } else if (newStatus === "rejected") {
        await sendEmail("booking_cancelled", clientEmail, {
          serviceName: service?.name ?? "Service",
          bookingCode: booking.booking_code ?? "",
          reason: reason ? sanitizeText(reason) : undefined,
          refundAmount: booking.deposit_amount
            ? (Number(booking.deposit_amount) / 100).toFixed(2)
            : undefined,
        });
      } else if (newStatus === "completed") {
        await sendEmail("review_request", clientEmail, {
          serviceName: service?.name ?? "votre prestation",
          proName: proProfile?.business_name ?? "votre prestataire",
        });
      }
    }

    // ─── Audit log ─────────────────────────────────────────────
    await supabase.rpc("log_audit_action", {
      p_user_id: user.id,
      p_action: `booking_${action}`,
      p_resource_type: "booking",
      p_resource_id: bookingId,
      p_metadata: { from_status: booking.status, to_status: newStatus },
    });

    // ─── If rejected and has payment, trigger refund ───────────
    if (
      newStatus === "rejected" &&
      booking.deposit_amount &&
      booking.deposit_amount > 0
    ) {
      // Release the time slot
      if (booking.time_slot_id) {
        await supabase
          .from("time_slots")
          .update({ is_available: true, locked_by: null })
          .eq("id", booking.time_slot_id);
      }

      // Trigger actual Stripe refund for rejected bookings
      if (booking.stripe_payment_intent_id) {
        const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
          apiVersion: "2023-10-16",
        });
        await stripe.refunds.create({
          payment_intent: booking.stripe_payment_intent_id,
        });
        if (booking.transfer_id) {
          await stripe.transfers.createReversal(booking.transfer_id);
        }
      }
      await supabase
        .from("bookings")
        .update({
          status: "cancelled_full_refund",
          refund_amount: booking.deposit_amount,
          refund_status: "refunded",
        })
        .eq("id", bookingId);
    }

    return jsonResponse(
      { success: true, status: newStatus },
      200,
      undefined,
      req
    );
  } catch (error) {
    console.error("update-booking-status error:", error);
    return jsonResponse(
      { error: "internal_error" },
      500,
      undefined,
      req
    );
  }
});
