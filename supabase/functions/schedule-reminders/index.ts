import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  assertServiceRoleOnly,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";
import { sendResendEmail } from "../_shared/send_resend_email.ts";

// ── Types de résultats pour les selects avec FK embeds ─────────────────────
// Cast explicite : Supabase SDK ne résout pas les FK embeds typés (bug connu
// v2.x) — sans ce cast, tous les champs reviennent comme `GenericStringError`
// et cascade dans tout le fichier. On préserve donc la shape réelle ici.
interface ReminderBookingJ1 {
  id: string;
  client_id: string;
  time_slots: { pro_id: string; date: string; start_time: string } | null;
  services: { name: string | null } | null;
  profiles_pro: { business_name: string | null } | null;
  users: { email: string | null } | null;
}

interface ReminderBookingH2 {
  id: string;
  client_id: string;
  time_slots: { pro_id: string; date: string; start_time: string } | null;
  services: { name: string | null } | null;
}

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
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    const forbidden = assertServiceRoleOnly(req);
    if (forbidden) return forbidden;

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

    const { data: tomorrowBookingsRaw } = await supabase
      .from("bookings")
      .select(
        "id, client_id, time_slots(pro_id, date, start_time), services(name), " +
        "profiles_pro!bookings_pro_id_fkey(business_name), " +
        // Ajout : l'email est nécessaire pour l'appel `sendResendEmail`
        // (l'ancien `send-email` EF résolvait userId → email en interne).
        "users!bookings_client_id_fkey(email)"
      )
      .eq("status", "confirmed")
      .is("reminder_j1_sent", null);

    // Cast explicite : Supabase SDK ne résout pas les FK embeds typés (bug
    // connu v2.x) — le résultat arrive comme `GenericStringError[]`.
    const tomorrowBookings =
      (tomorrowBookingsRaw as unknown as ReminderBookingJ1[] | null) ?? [];

    // Filter to tomorrow's date on joined time_slots
    const j1Bookings = tomorrowBookings.filter(
      (b) => b.time_slots?.date === tomorrowStr
    );

    for (const booking of j1Bookings) {
      const slot = booking.time_slots;
      if (!slot) continue;
      const serviceName = booking.services?.name ?? "votre rendez-vous";

      // Push to client
      await sendPush(supabaseUrl, serviceKey, {
        userId: booking.client_id,
        title: "Rappel — Demain",
        body: `Votre rendez-vous « ${serviceName} » est demain à ${slot.start_time}`,
        type: "booking_reminder",
        data: { bookingId: booking.id },
      });

      // Push to pro
      await sendPush(supabaseUrl, serviceKey, {
        userId: slot.pro_id,
        title: "Rappel — Client demain",
        body: `Rendez-vous « ${serviceName} » demain à ${slot.start_time}`,
        type: "booking_reminder",
        data: { bookingId: booking.id },
      });

      // Email — J-1 reminder to client only (avoid inbox flood for H-2)
      const proName = booking.profiles_pro?.business_name ?? "";
      const clientEmail = booking.users?.email ?? undefined;
      if (clientEmail) {
        await sendResendEmail({
          event: "booking_reminder_j1",
          to: clientEmail,
          variables: {
            serviceName,
            proName,
            date: slot.date,
            time: slot.start_time,
          },
        });
      }

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

    const { data: h2BookingsRaw } = await supabase
      .from("bookings")
      .select(
        "id, client_id, time_slots!inner(pro_id, date, start_time), services(name)"
      )
      .eq("status", "confirmed")
      .eq("time_slots.date", todayStr)
      .gte("time_slots.start_time", nowTime)
      .lte("time_slots.start_time", h2Time)
      .is("reminder_h2_sent", null);

    // Cast explicite : Supabase SDK ne résout pas les FK embeds typés (bug
    // connu v2.x) — le résultat arrive comme `GenericStringError[]`.
    const h2Bookings =
      (h2BookingsRaw as unknown as ReminderBookingH2[] | null) ?? [];

    for (const booking of h2Bookings) {
      const slot = booking.time_slots;
      if (!slot) continue;
      const serviceName = booking.services?.name ?? "votre rendez-vous";

      await sendPush(supabaseUrl, serviceKey, {
        userId: booking.client_id,
        title: "Rappel — Dans 2h",
        body: `Votre rendez-vous « ${serviceName} » commence à ${slot.start_time}`,
        type: "booking_reminder",
        data: { bookingId: booking.id },
      });

      await sendPush(supabaseUrl, serviceKey, {
        userId: slot.pro_id,
        title: "Rappel — Client dans 2h",
        body: `Rendez-vous « ${serviceName} » à ${slot.start_time}`,
        type: "booking_reminder",
        data: { bookingId: booking.id },
      });

      await supabase
        .from("bookings")
        .update({ reminder_h2_sent: now.toISOString() })
        .eq("id", booking.id);

      sentCount += 2;
    }

    return new Response(JSON.stringify({ success: true, reminders_sent: sentCount }), {
      headers: { ...securityHeadersFor(req), "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("schedule-reminders error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
