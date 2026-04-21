// cancellation-policy
// ───────────────────
// GET endpoint de lecture seule : donne à l'UI Flutter le seuil et la
// fraction de remboursement qu'elle doit afficher. Évite la divergence
// historique (UI codait 48h en dur, backend moderate = 24h) en rendant
// le backend source de vérité. Voir docs/AUDIT_REPORT_CORRECTIONS.md.
//
// Utilisation :
//   GET /functions/v1/cancellation-policy?bookingId=<uuid>
//   Authorization: Bearer <user JWT>
//
// Retour :
//   {
//     policy: "moderate" | "strict",
//     hoursThreshold: 24,
//     aboveRefundFraction: 1.0,
//     belowRefundFraction: 0.5,
//     currentHoursUntil: 36.5,
//     projectedFraction: 1.0,
//     projectedRefundAmount: 50.00
//   }
//
// L'UI peut alors annoncer des phrases telles que
//   "À plus de 24h du RDV, remboursement complet (50$). Après, aucun
//    remboursement."
// en collant parfaitement à ce que cancel-booking appliquera réellement.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

// Même source que cancel-booking — à dupliquer prudemment ou à extraire
// dans _shared/ lors du prochain refactor. Pour cette livraison, on garde
// proche (moins de couplage implicite).
const POLICY = {
  moderate: {
    hoursThreshold: 24,
    aboveRefundFraction: 1.0,
    belowRefundFraction: 0.5,
  },
  strict: {
    hoursThreshold: 0,
    aboveRefundFraction: 0.0,
    belowRefundFraction: 0.0,
  },
} as const;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "GET") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }
    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const url = new URL(req.url);
    const bookingId = url.searchParams.get("bookingId") ?? "";
    if (!isValidUuid(bookingId)) {
      return jsonResponse(
        { error: "bookingId_invalid" },
        400,
        undefined,
        req,
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: booking, error } = await supabase
      .from("bookings")
      .select(
        "id, client_id, pro_id, deposit_amount, time_slots(date, start_time), services(cancellation_policy)",
      )
      .eq("id", bookingId)
      .maybeSingle();

    if (error || !booking) {
      return jsonResponse({ error: "booking_not_found" }, 404, undefined, req);
    }

    if (booking.client_id !== user.id && booking.pro_id !== user.id) {
      return jsonResponse({ error: "forbidden" }, 403, undefined, req);
    }

    const rawPolicy =
      (booking.services as Record<string, unknown> | null)
        ?.cancellation_policy as string ?? "moderate";
    const policy =
      (rawPolicy === "strict" ? "strict" : "moderate") as keyof typeof POLICY;
    const params = POLICY[policy];

    const slot = booking.time_slots as { date?: string; start_time?: string } | null;
    let currentHoursUntil: number | null = null;
    let projectedFraction = params.belowRefundFraction;
    let projectedRefundAmount = 0;

    if (slot?.date && slot?.start_time) {
      const slotDate = new Date(`${slot.date}T${slot.start_time}`);
      const ms = slotDate.getTime() - Date.now();
      if (Number.isFinite(ms)) {
        currentHoursUntil = ms / (1000 * 60 * 60);
        projectedFraction = currentHoursUntil > params.hoursThreshold
          ? params.aboveRefundFraction
          : params.belowRefundFraction;
        projectedRefundAmount =
          Math.round(
            (booking.deposit_amount ?? 0) * projectedFraction * 100,
          ) / 100;
      }
    }

    return jsonResponse(
      {
        policy,
        hoursThreshold: params.hoursThreshold,
        aboveRefundFraction: params.aboveRefundFraction,
        belowRefundFraction: params.belowRefundFraction,
        currentHoursUntil,
        projectedFraction,
        projectedRefundAmount,
      },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("cancellation-policy error", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
