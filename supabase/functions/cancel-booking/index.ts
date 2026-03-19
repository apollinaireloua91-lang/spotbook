import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );
    const {
      data: { user },
    } = await authClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    const { bookingId } = await req.json();
    if (!bookingId) {
      return new Response(
        JSON.stringify({ error: "bookingId required" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

    // Fetch booking
    const { data: booking, error: bErr } = await supabase
      .from("bookings")
      .select("*, time_slots(*)")
      .eq("id", bookingId)
      .single();
    if (bErr || !booking) {
      return new Response(JSON.stringify({ error: "booking_not_found" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 404,
      });
    }

    // Verify ownership (client or pro)
    if (booking.client_id !== user.id && booking.pro_id !== user.id) {
      return new Response(JSON.stringify({ error: "forbidden" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 403,
      });
    }

    // Calculate hours until appointment
    const slotDate = new Date(
      `${booking.time_slots.date}T${booking.time_slots.start_time}`
    );
    const hoursUntil =
      (slotDate.getTime() - Date.now()) / (1000 * 60 * 60);

    let newStatus: string;

    if (hoursUntil > 48) {
      // Full refund via Stripe
      const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
        apiVersion: "2023-10-16",
      });

      if (booking.stripe_payment_intent_id) {
        await stripe.refunds.create({
          payment_intent: booking.stripe_payment_intent_id,
        });

        // Transfer Reversal to reclaim pro payout
        if (booking.transfer_id) {
          await stripe.transfers.createReversal(booking.transfer_id);
        }
      }

      newStatus = "cancelled_full_refund";
      await supabase
        .from("bookings")
        .update({
          status: newStatus,
          refund_amount: booking.deposit_amount,
          refund_status: "refunded",
        })
        .eq("id", bookingId);
    } else {
      // No refund — pro keeps deposit
      newStatus = "cancelled_no_refund";
      await supabase
        .from("bookings")
        .update({
          status: newStatus,
          refund_amount: 0,
          refund_status: "no_refund",
        })
        .eq("id", bookingId);
    }

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
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
