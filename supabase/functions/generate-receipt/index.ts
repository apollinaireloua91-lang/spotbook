// ════════════════════════════════════════════════════════════════════════════
// generate-receipt — Priority #12
// ────────────────────────────────────────────────────────────────────────────
// Creates a digital receipt for a completed booking.
// Called post-payment by the stripe-webhook-handler.
//
// Idempotent — uses UNIQUE constraint on bookings.id.
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

    // Idempotency
    const { data: existingReceipt } = await admin
      .from("receipts")
      .select("id, receipt_number")
      .eq("booking_id", bookingId)
      .maybeSingle();
    if (existingReceipt) {
      return jsonResponse(
        { ok: true, receiptId: existingReceipt.id, alreadyExists: true },
        200,
        undefined,
        req,
      );
    }

    // Pull booking + services + addons + tips for full breakdown
    const { data: booking } = await admin
      .from("bookings")
      .select(
        `id, client_id, pro_id, total_price, currency, stripe_payment_intent_id,
         booking_services(id, price, duration_minutes, services(name, title)),
         booking_addons(name_snapshot, price),
         tips(amount_cents, status)`,
      )
      .eq("id", bookingId)
      .single();

    if (!booking) {
      return jsonResponse({ error: "booking_not_found" }, 404, undefined, req);
    }

    const subtotal = Math.round((booking.total_price as number) * 100);
    const addons = (booking.booking_addons ?? []) as Array<
      { price: number }
    >;
    const addonsCents = addons.reduce(
      (sum, a) => sum + Math.round((a.price as number) * 100),
      0,
    );
    const tips = ((booking.tips ?? []) as Array<
      { amount_cents: number; status: string }
    >).filter((t) => t.status === "succeeded");
    const tipCents = tips.reduce((sum, t) => sum + t.amount_cents, 0);
    const totalCents = subtotal + tipCents;

    // Generate receipt number via the DB function
    const { data: numRes } = await admin.rpc("generate_receipt_number");
    const receiptNumber = numRes as string;

    const lineItems = [
      ...((booking.booking_services ?? []) as Array<{
        price: number;
        duration_minutes: number;
        services?: { name?: string; title?: string };
      }>).map((bs) => ({
        type: "service",
        name: bs.services?.title ?? bs.services?.name ?? "Service",
        duration_minutes: bs.duration_minutes,
        amount_cents: Math.round(bs.price * 100),
      })),
      ...addons.map((a) => ({
        type: "addon",
        name: (a as unknown as { name_snapshot?: string }).name_snapshot,
        amount_cents: Math.round(a.price * 100),
      })),
      ...(tipCents > 0
        ? [{ type: "tip", name: "Pourboire", amount_cents: tipCents }]
        : []),
    ];

    const { data: newReceipt, error: insertErr } = await admin
      .from("receipts")
      .insert({
        booking_id: bookingId,
        client_id: booking.client_id,
        pro_id: booking.pro_id,
        receipt_number: receiptNumber,
        subtotal_cents: subtotal,
        addons_cents: addonsCents,
        tip_cents: tipCents,
        total_cents: totalCents,
        currency: booking.currency ?? "CAD",
        line_items: lineItems,
      })
      .select("id, receipt_number")
      .single();

    if (insertErr) {
      console.error("receipt insert failed", insertErr);
      return jsonResponse({ error: "insert_failed" }, 500, undefined, req);
    }

    return jsonResponse(
      {
        ok: true,
        receiptId: newReceipt!.id,
        receiptNumber: newReceipt!.receipt_number,
      },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("generate-receipt error", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
