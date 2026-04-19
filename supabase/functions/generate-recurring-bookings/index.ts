// ════════════════════════════════════════════════════════════════════════════
// generate-recurring-bookings — Priority #7 (cron-triggered)
// ────────────────────────────────────────────────────────────────────────────
// Runs daily. For each active recurring_bookings row whose next_booking_date
// is within the next 7 days, attempt to generate the next individual booking.
//
// Notes:
//   - Does NOT charge payment — the recurring model charges 24h before each
//     occurrence via a separate job (not in scope of this MVP).
//   - Skips if a booking already exists for the slot.
//   - Advances next_booking_date by frequency_weeks after success.
// ════════════════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  assertServiceRoleOnly,
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
      // Check for existing booking at the same slot
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
        // Fetch service details
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
        const endTime =
          `${String(Math.floor(endMin / 60)).padStart(2, "0")}:${
            String(endMin % 60).padStart(2, "0")
          }:00`;

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
          console.error("recurring booking insert failed", error);
          continue;
        }

        // Advance next_booking_date by frequency_weeks
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

    return jsonResponse(
      { ok: true, generated, skipped },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("generate-recurring-bookings error", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
