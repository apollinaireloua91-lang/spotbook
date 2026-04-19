// ════════════════════════════════════════════════════════════════════════════
// send-reminders — Priority #4 (cron-triggered)
// ────────────────────────────────────────────────────────────────────────────
// Runs every 15 minutes (via pg_cron or external scheduler).
// Finds upcoming bookings that haven't received their 24h / 2h / 30min
// reminder yet and dispatches push notifications + emails.
//
// Security: service_role only.
// ════════════════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  assertServiceRoleOnly,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

interface BookingForReminder {
  id: string;
  client_id: string;
  pro_id: string;
  date: string;
  start_time: string;
  status: string;
}

/**
 * Returns the ISO datetime for the booking's start, combining date+time.
 */
function bookingStartAt(b: BookingForReminder): Date {
  return new Date(`${b.date}T${b.start_time}`);
}

/**
 * Attempts to send a push notification + email via existing `send-email` and
 * the push notification table. We insert into `notifications` which triggers
 * the existing push pipeline.
 */
async function dispatchReminder(opts: {
  admin: ReturnType<typeof createClient>;
  userId: string;
  title: string;
  body: string;
  bookingId: string;
  kind: "reminder_24h" | "reminder_2h" | "reminder_30min" | "reminder_pro_30min";
}) {
  await opts.admin.from("notifications").insert({
    user_id: opts.userId,
    type: opts.kind,
    title: opts.title,
    body: opts.body,
    ref_id: opts.bookingId,
    is_read: false,
  }).select();
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: securityHeadersFor(req) });
  }

  try {
    const forbidden = assertServiceRoleOnly(req);
    if (forbidden) return forbidden;

    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const now = new Date();
    const in24h = new Date(now.getTime() + 24 * 3600 * 1000);
    const in2h = new Date(now.getTime() + 2 * 3600 * 1000);
    const in30m = new Date(now.getTime() + 30 * 60 * 1000);
    const todayIso = now.toISOString().split("T")[0];

    let sent24 = 0, sent2 = 0, sent30 = 0;

    // ── 24h reminders ────────────────────────────────────────
    {
      const { data: rows } = await admin
        .from("bookings")
        .select("id, client_id, pro_id, date, start_time, status")
        .eq("status", "confirmed")
        .is("reminder_j1_sent", null)
        .gte("date", todayIso)
        .limit(200);

      for (const b of (rows ?? []) as BookingForReminder[]) {
        const startAt = bookingStartAt(b);
        const diffMs = startAt.getTime() - now.getTime();
        // Fire if booking is within 22-26 hours from now
        if (diffMs <= 26 * 3600 * 1000 && diffMs >= 22 * 3600 * 1000) {
          await dispatchReminder({
            admin,
            userId: b.client_id,
            title: "Ton RDV est demain",
            body: `N'oublie pas ton rendez-vous à ${b.start_time.slice(0, 5)} demain.`,
            bookingId: b.id,
            kind: "reminder_24h",
          });
          await admin
            .from("bookings")
            .update({ reminder_j1_sent: now.toISOString() })
            .eq("id", b.id)
            .is("reminder_j1_sent", null);
          sent24++;
        }
      }
    }

    // ── 2h reminders ─────────────────────────────────────────
    {
      const { data: rows } = await admin
        .from("bookings")
        .select("id, client_id, pro_id, date, start_time, status")
        .eq("status", "confirmed")
        .is("reminder_h2_sent", null)
        .eq("date", todayIso)
        .limit(200);

      for (const b of (rows ?? []) as BookingForReminder[]) {
        const startAt = bookingStartAt(b);
        const diffMs = startAt.getTime() - now.getTime();
        if (diffMs <= 130 * 60 * 1000 && diffMs >= 110 * 60 * 1000) {
          await dispatchReminder({
            admin,
            userId: b.client_id,
            title: "RDV dans 2 heures",
            body: `Ton rendez-vous est dans 2h — à ${b.start_time.slice(0, 5)}.`,
            bookingId: b.id,
            kind: "reminder_2h",
          });
          await admin
            .from("bookings")
            .update({ reminder_h2_sent: now.toISOString() })
            .eq("id", b.id)
            .is("reminder_h2_sent", null);
          sent2++;
        }
      }
    }

    // ── 30 min reminders ─────────────────────────────────────
    {
      const { data: rows } = await admin
        .from("bookings")
        .select("id, client_id, pro_id, date, start_time, status")
        .eq("status", "confirmed")
        .is("reminder_m30_sent", null)
        .eq("date", todayIso)
        .limit(200);

      for (const b of (rows ?? []) as BookingForReminder[]) {
        const startAt = bookingStartAt(b);
        const diffMs = startAt.getTime() - now.getTime();
        if (diffMs <= 40 * 60 * 1000 && diffMs >= 20 * 60 * 1000) {
          await dispatchReminder({
            admin,
            userId: b.client_id,
            title: "RDV dans 30 minutes",
            body: "Prépare-toi — ton RDV commence dans 30 minutes.",
            bookingId: b.id,
            kind: "reminder_30min",
          });
          // Also remind the pro (next client incoming)
          await dispatchReminder({
            admin,
            userId: b.pro_id,
            title: "Prochain client dans 30 min",
            body: "Ton prochain RDV commence dans 30 minutes.",
            bookingId: b.id,
            kind: "reminder_pro_30min",
          });
          await admin
            .from("bookings")
            .update({
              reminder_m30_sent: now.toISOString(),
              reminder_pro_m30_sent: now.toISOString(),
            })
            .eq("id", b.id)
            .is("reminder_m30_sent", null);
          sent30++;
        }
      }
    }

    return jsonResponse(
      { ok: true, sent24, sent2, sent30 },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("send-reminders error", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
