import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import { assertAmount, assertUuid, jsonHeaders, securityHeaders } from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: securityHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { bookingId } = await req.json();
    if (!bookingId) {
      return new Response(
        JSON.stringify({ error: "bookingId required" }),
        { headers: jsonHeaders, status: 400 }
      );
    }
    assertUuid(bookingId, "bookingId");

    const { data: booking, error: bErr } = await supabase
      .from("bookings")
      .select(
        "id, deposit_amount, currency, pro_id, profiles_pro(stripe_account_id, commission_rate)"
      )
      .eq("id", bookingId)
      .single();

    if (bErr || !booking) {
      return new Response(
        JSON.stringify({ error: "booking_not_found" }),
        { headers: jsonHeaders, status: 404 }
      );
    }

    const pro = booking.profiles_pro;
    if (!pro?.stripe_account_id) {
      return new Response(
        JSON.stringify({ error: "pro_not_connected" }),
        { headers: jsonHeaders, status: 400 }
      );
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const commissionRate = pro.commission_rate ?? 0.12;
    const proAmount = booking.deposit_amount * (1 - commissionRate);
    assertAmount(Number(proAmount ?? 0), "proAmount");
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
    await supabase.rpc("insert_audit_log", {
      p_user_id: booking.pro_id,
      p_action: "pro_payout_sent",
      p_resource_type: "booking",
      p_resource_id: booking.id,
      p_metadata: { transfer_id: transfer.id },
      p_ip_address: "edge",
    });

    return new Response(
      JSON.stringify({ success: true, transferId: transfer.id }),
      { headers: jsonHeaders }
    );
  } catch (error) {
    console.error("Payout error:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: jsonHeaders,
      status: 400,
    });
  }
});
