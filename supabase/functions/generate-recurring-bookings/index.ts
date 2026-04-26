// generate-recurring-bookings — Cron-only Edge Function (verify_jwt=false).
// Auth: Vault-stored shared secret via get_cron_shared_secret() RPC.
//
// Logic (unchanged): for each active recurring_bookings whose
// next_booking_date <= now+7d, attempt to create the next individual booking,
// then advance next_booking_date by frequency_weeks.

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
      console.error("[generate-recurring-bookings] vault read failed:", error);
      return jsonResponse({ error: "server_misconfigured" }, 500);
    }
    _cachedCronSecret = data;
  }
  if (!timingSafeEqual(auth, `Bearer ${_cachedCronSecret}`)) {
    return jsonResponse({ error: "forbidden" }, 403);
  }
  return null;
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
    const horizon = new Date(now.getTime() + 7 * 24 * 3600 * 1000);
    const horizonIso = horizon.toISOString().split("T")[0];

    const { data: dueRecurring } = await admin
      .from("recurring_bookings")
      .select(
        "id, client_id, pro_id, service_id, day_of_week, start_time, frequency_weeks, next_booking_date",
      )
      .eq("is_active", true)
      .lte("next_booking_date", horizonIso)
      .limit(100);

    let generated = 0;
    let skipped = 0;

    for (const r of (dueRecurring ?? []) as Array<{
      id: string;
      client_id: string;
      pro_id: string;
      service_id: string;
      start_time: string;
      frequency_weeks: number;
      next_booking_date: string;
    }>) {
      const { data: existing } = await admin
        .from("bookings")
        .select("id")
        .eq("client_id", r.client_id)
        .eq("pro_id", r.pro_id)
        .eq("date", r.next_booking_date)
        .eq("start_time", r.start_time)
        .maybeSingle();

      if (existing) {
        skipped++;
      } else {
        const { data: svc } = await admin
          .from("services")
          .select("id, price, duration_minutes, currency")
          .eq("id", r.service_id)
          .single();

        if (!svc) {
          skipped++;
          continue;
        }

        const startTime = r.start_time;
        const [h, m] = startTime.split(":").map(Number);
        const endMin = h * 60 + m + (svc.duration_minutes as number);
        const endTime = `${String(Math.floor(endMin / 60)).padStart(2, "0")}:${String(endMin % 60).padStart(2, "0")}:00`;

        const { data: newBooking, error } = await admin
          .from("bookings")
          .insert({
            client_id: r.client_id,
            pro_id: r.pro_id,
            service_id: r.service_id,
            date: r.next_booking_date,
            start_time: startTime,
            end_time: endTime,
            total_price: svc.price,
            total_amount: svc.price,
            currency: svc.currency ?? "CAD",
            status: "pending",
            payment_status: "pending",
          })
          .select("id")
          .single();

        if (error) {
          console.error("[generate-recurring-bookings] insert failed:", error);
          continue;
        }

        const nextDate = new Date(`${r.next_booking_date}T00:00:00`);
        nextDate.setDate(nextDate.getDate() + r.frequency_weeks * 7);
        const nextIso = nextDate.toISOString().split("T")[0];

        await admin
          .from("recurring_bookings")
          .update({
            next_booking_date: nextIso,
            last_generated_booking_id: newBooking?.id,
          })
          .eq("id", r.id);

        generated++;
      }
    }

    return jsonResponse({ ok: true, generated, skipped });
  } catch (err) {
    console.error("[generate-recurring-bookings] error", err);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
