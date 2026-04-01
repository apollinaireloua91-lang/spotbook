import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  assertServiceRoleOnly,
  isValidAmount,
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: securityHeadersFor(req) });
  }

  try {
    const forbidden = assertServiceRoleOnly(req);
    if (forbidden) return forbidden;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
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
        "id, status, deposit_amount, currency, pro_id, transfer_id, profiles_pro(stripe_account_id, commission_rate)"
      )
      .eq("id", bookingId)
      .single();

    if (bErr || !booking) {
      return jsonResponse({ error: "booking_not_found" }, 404, undefined, req);
    }

    if (booking.status !== "confirmed") {
      return jsonResponse({ error: "booking_not_confirmed" }, 400, undefined, req);
    }

    if (booking.transfer_id) {
      return jsonResponse(
        { error: "payout_already_processed", transferId: booking.transfer_id },
        409,
        undefined,
        req,
      );
    }

    const pro = booking.profiles_pro;
    if (!pro?.stripe_account_id) {
      return jsonResponse({ error: "pro_not_connected" }, 400, undefined, req);
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const commissionRate = pro.commission_rate ?? 0.12;
    const proAmount = booking.deposit_amount * (1 - commissionRate);
    if (!isValidAmount(Number(proAmount))) {
      return jsonResponse({ error: "amount invalide" }, 400, undefined, req);
    }
    const proAmountCents = Math.floor(proAmount * 100);

    const transfer = await stripe.transfers.create(
      {
        amount: proAmountCents,
        currency: (booking.currency || "cad").toLowerCase(),
        destination: pro.stripe_account_id,
        metadata: {
          bookingId: booking.id,
          proId: booking.pro_id,
          type: "payout",
        },
      },
      { idempotencyKey: `payout-${booking.id}` }
    );

    await supabase
      .from("bookings")
      .update({ transfer_id: transfer.id })
      .eq("id", bookingId);
    await supabase.rpc("log_audit_action", {
      p_user_id: booking.pro_id,
      p_action: "pro_payout_sent",
      p_resource_type: "booking",
      p_resource_id: booking.id,
      p_metadata: { transfer_id: transfer.id },
    });

    return jsonResponse({ success: true, transferId: transfer.id }, 200, undefined, req);
  } catch (error) {
    console.error("process-payout error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
