import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

async function sendPush(
  supabaseUrl: string,
  serviceKey: string,
  payload: {
    userId: string;
    title: string;
    body: string;
    type: string;
    data?: Record<string, string>;
  }
) {
  await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const now = new Date();
    let sentCount = 0;

    // ─── J-1 : bookings tomorrow, status=confirmed ───
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split("T")[0];

    const { data: tomorrowBookings } = await supabase
      .from("bookings")
      .select(
        "id, client_id, time_slots(pro_id, date, start_time), services(name)"
      )
      .eq("status", "confirmed")
      .not("reminder_j1_sent", "is", null)
      .is("reminder_j1_sent", null);

    // Filter to tomorrow's date on joined time_slots
    const j1Bookings = (tomorrowBookings ?? []).filter(
      (b: Record<string, unknown>) => {
        const slot = b.time_slots as Record<string, unknown> | null;
        return slot && (slot.date as string) === tomorrowStr;
      }
    );

    for (const booking of j1Bookings) {
      const slot = booking.time_slots as Record<string, unknown>;
      const service = booking.services as Record<string, unknown> | null;
      const serviceName = (service?.name as string) ?? "votre rendez-vous";

      // Push to client
      await sendPush(supabaseUrl, serviceKey, {
        userId: booking.client_id as string,
        title: "Rappel — Demain",
        body: `Votre rendez-vous « ${serviceName} » est demain à ${slot.start_time}`,
        type: "booking_reminder",
        data: { bookingId: booking.id as string },
      });

      // Push to pro
      await sendPush(supabaseUrl, serviceKey, {
        userId: slot.pro_id as string,
        title: "Rappel — Client demain",
        body: `Rendez-vous « ${serviceName} » demain à ${slot.start_time}`,
        type: "booking_reminder",
        data: { bookingId: booking.id as string },
      });

      await supabase
        .from("bookings")
        .update({ reminder_j1_sent: now.toISOString() })
        .eq("id", booking.id);

      sentCount += 2;
    }

    // ─── H-2 : bookings within next 2 hours ───
    const twoHoursLater = new Date(now.getTime() + 2 * 60 * 60 * 1000);
    const nowTime = now.toTimeString().slice(0, 5);
    const h2Time = twoHoursLater.toTimeString().slice(0, 5);
    const todayStr = now.toISOString().split("T")[0];

    const { data: h2Bookings } = await supabase
      .from("bookings")
      .select(
        "id, client_id, time_slots!inner(pro_id, date, start_time), services(name)"
      )
      .eq("status", "confirmed")
      .eq("time_slots.date", todayStr)
      .gte("time_slots.start_time", nowTime)
      .lte("time_slots.start_time", h2Time)
      .is("reminder_h2_sent", null);

    for (const booking of h2Bookings ?? []) {
      const slot = booking.time_slots as Record<string, unknown>;
      const service = booking.services as Record<string, unknown> | null;
      const serviceName = (service?.name as string) ?? "votre rendez-vous";

      await sendPush(supabaseUrl, serviceKey, {
        userId: booking.client_id as string,
        title: "Rappel — Dans 2h",
        body: `Votre rendez-vous « ${serviceName} » commence à ${slot.start_time}`,
        type: "booking_reminder",
        data: { bookingId: booking.id as string },
      });

      await sendPush(supabaseUrl, serviceKey, {
        userId: slot.pro_id as string,
        title: "Rappel — Client dans 2h",
        body: `Rendez-vous « ${serviceName} » à ${slot.start_time}`,
        type: "booking_reminder",
        data: { bookingId: booking.id as string },
      });

      await supabase
        .from("bookings")
        .update({ reminder_h2_sent: now.toISOString() })
        .eq("id", booking.id);

      sentCount += 2;
    }

    return new Response(
      JSON.stringify({ success: true, reminders_sent: sentCount }),
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
