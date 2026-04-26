// send-reminders — Cron-only Edge Function (verify_jwt=false on the gateway).
//
// Auth pattern: Vault-stored shared secret. Both pg_cron and this function
// read `cron_service_role_key` from Vault (function via the
// public.get_cron_shared_secret() RPC). Bypassing the gateway lets us avoid
// the UNAUTHORIZED_LEGACY_JWT errors that started appearing once Supabase
// migrated this project to asymmetric JWT signing.
//
// Logic (unchanged from the original send-reminders):
//   - Runs every 15 minutes
//   - Finds upcoming bookings that haven't received their 24h / 2h / 30min
//     reminder yet
//   - Inserts notification rows (push pipeline picks these up downstream)
//   - Marks the bookings.reminder_*_sent timestamps idempotently

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

function securityHeadersFor(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "https://getspotbook.app",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
  };
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...securityHeadersFor(), "Content-Type": "application/json" },
  });
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

let _cachedCronSecret: string | null = null;
async function assertCronAuth(req: Request): Promise<Response | null> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!_cachedCronSecret) {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!url || !key) return jsonResponse({ error: "server_misconfigured" }, 500);
    const c = createClient(url, key);
    const { data, error } = await c.rpc("get_cron_shared_secret");
    if (error || typeof data !== "string" || !data.length) {
      console.error("[send-reminders] vault read failed:", error);
      return jsonResponse({ error: "server_misconfigured" }, 500);
    }
    _cachedCronSecret = data;
  }
  if (!timingSafeEqual(auth, `Bearer ${_cachedCronSecret}`)) {
    return jsonResponse({ error: "forbidden" }, 403);
  }
  return null;
}

interface BookingForReminder {
  id: string;
  client_id: string;
  pro_id: string;
  date: string;
  start_time: string;
  status: string;
}

function bookingStartAt(b: BookingForReminder): Date {
  return new Date(`${b.date}T${b.start_time}`);
}

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
    return new Response("ok", { status: 200, headers: securityHeadersFor() });
  }

  try {
    const forbidden = await assertCronAuth(req);
    if (forbidden) return forbidden;

    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const now = new Date();
    const todayIso = now.toISOString().split("T")[0];

    let sent24 = 0, sent2 = 0, sent30 = 0;

    // ── 24h reminders ──
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

    // ── 2h reminders ──
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

    // ── 30 min reminders (client + pro) ──
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

    return jsonResponse({ ok: true, sent24, sent2, sent30 });
  } catch (err) {
    console.error("[send-reminders] error", err);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
