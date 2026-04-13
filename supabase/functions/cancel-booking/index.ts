import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import { isValidUuid, jsonResponse, securityHeaders } from "../_shared/security.ts";

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

    const { bookingId } = await req.json();
    if (!bookingId || !isValidUuid(String(bookingId))) {
      return jsonResponse({ error: "bookingId doit être un UUID valide" }, 400);
    }

    // Fetch booking with service cancellation policy
    const { data: booking, error: bErr } = await supabase
      .from("bookings")
      .select("*, time_slots(*), services(cancellation_policy)")
      .eq("id", bookingId)
      .single();
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
      `${booking.time_slots.date}T${booking.time_slots.start_time}`
    );
    const hoursUntil =
      (slotDate.getTime() - Date.now()) / (1000 * 60 * 60);

    // Determine cancellation policy: flexible (>12h), moderate (>24h / 50%), strict (no refund)
    const policy = (booking.services as Record<string, unknown> | null)?.cancellation_policy as string ?? "flexible";

    let newStatus: string;
    let refundAmount = 0;

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    if (policy === "strict") {
      // Strict: no refund regardless of timing
      newStatus = "cancelled_no_refund";
      refundAmount = 0;
    } else if (policy === "moderate") {
      if (hoursUntil > 24) {
        // Moderate >24h: full refund
        newStatus = "cancelled_full_refund";
        refundAmount = booking.deposit_amount;
      } else {
        // Moderate ≤24h: 50% kept by pro
        newStatus = "cancelled_partial_refund";
        refundAmount = Math.round(booking.deposit_amount * 0.5 * 100) / 100;
      }
    } else {
      // Flexible (default): >12h = full refund, ≤12h = no refund
      if (hoursUntil > 12) {
        newStatus = "cancelled_full_refund";
        refundAmount = booking.deposit_amount;
      } else {
        newStatus = "cancelled_no_refund";
        refundAmount = 0;
      }
    }

    // Process refund via Stripe if applicable
    if (refundAmount > 0 && booking.stripe_payment_intent_id) {
      const refundAmountCents = Math.round(refundAmount * 100);
      await stripe.refunds.create({
        payment_intent: booking.stripe_payment_intent_id,
        amount: refundAmountCents,
      });

      // Transfer Reversal to reclaim pro payout
      if (booking.transfer_id) {
        await stripe.transfers.createReversal(booking.transfer_id, {
          amount: refundAmountCents,
        });
      }

      await supabase.rpc("log_audit_action", {
        p_user_id: user.id,
        p_action: "refund_initiated",
        p_resource_type: "booking",
        p_resource_id: bookingId,
        p_metadata: { refund_amount: refundAmount, policy },
      });
    }

    // Atomic update — guard against TOCTOU race (concurrent cancel requests)
    const { data: updatedRows, error: updateErr } = await supabase
      .from("bookings")
      .update({
        status: newStatus,
        refund_amount: refundAmount,
        refund_status: refundAmount > 0 ? "refunded" : "no_refund",
      })
      .eq("id", bookingId)
      .in("status", cancellableStatuses)
      .select("id");

    if (updateErr || !updatedRows?.length) {
      return jsonResponse({ error: "booking_already_cancelled" }, 409);
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

    return new Response(
      JSON.stringify({
        success: true,
        status: newStatus,
        hoursUntil: Math.round(hoursUntil),
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
