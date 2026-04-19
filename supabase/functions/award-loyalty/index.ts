// ════════════════════════════════════════════════════════════════════════════
// award-loyalty — Priority #9
// ────────────────────────────────────────────────────────────────────────────
// Credits loyalty points to a client after a completed booking.
// Called by the stripe-webhook-handler or a post-completion trigger.
//
// Idempotent: won't double-credit if a row already exists for (booking_id, earned).
// ════════════════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  assertServiceRoleOnly,
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

    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const body = await req.json().catch(() => ({}));
    const bookingId = String(body.bookingId ?? "");
    if (!isValidUuid(bookingId)) {
      return jsonResponse({ error: "invalid_booking_id" }, 400, undefined, req);
    }

    const { data: booking } = await admin
      .from("bookings")
      .select("id, client_id, pro_id, total_price")
      .eq("id", bookingId)
      .single();

    if (!booking) {
      return jsonResponse({ error: "booking_not_found" }, 404, undefined, req);
    }

    // Fetch program config
    const { data: program } = await admin
      .from("loyalty_programs")
      .select("points_per_dollar, is_active")
      .eq("pro_id", booking.pro_id)
      .maybeSingle();

    if (!program || !program.is_active) {
      return jsonResponse(
        { ok: true, skipped: "no_program" },
        200,
        undefined,
        req,
      );
    }

    // Idempotency check
    const { data: existing } = await admin
      .from("loyalty_points_ledger")
      .select("id")
      .eq("booking_id", bookingId)
      .eq("type", "earned")
      .maybeSingle();

    if (existing) {
      return jsonResponse(
        { ok: true, skipped: "already_awarded" },
        200,
        undefined,
        req,
      );
    }

    const pointsEarned = Math.floor(
      (booking.total_price as number) * (program.points_per_dollar as number),
    );
    if (pointsEarned < 1) {
      return jsonResponse(
        { ok: true, skipped: "amount_too_low" },
        200,
        undefined,
        req,
      );
    }

    const { error: insertErr } = await admin
      .from("loyalty_points_ledger")
      .insert({
        client_id: booking.client_id,
        pro_id: booking.pro_id,
        booking_id: bookingId,
        points: pointsEarned,
        type: "earned",
        description: "Réservation complétée",
      });

    if (insertErr) {
      console.error("loyalty insert failed", insertErr);
      return jsonResponse({ error: "insert_failed" }, 500, undefined, req);
    }

    return jsonResponse(
      { ok: true, pointsEarned },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("award-loyalty error", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
