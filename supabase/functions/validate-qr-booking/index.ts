import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { encode as hexEncode } from "https://deno.land/std@0.168.0/encoding/hex.ts";
import {
  getQrSigningSecret,
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
  timingSafeEqual,
} from "../_shared/security.ts";

async function hmacSha256(data: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(data),
  );
  return new TextDecoder().decode(hexEncode(new Uint8Array(sig)));
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Authenticate the scanning pro
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    const {
      data: { user },
    } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const { bookingId, qrHash } = await req.json();
    if (
      !bookingId ||
      !isValidUuid(String(bookingId)) ||
      !qrHash ||
      String(qrHash).length < 20
    ) {
      return jsonResponse(
        { error: "bookingId UUID valide et qrHash requis" },
        400,
        undefined,
        req,
      );
    }

    const secret = getQrSigningSecret();
    if (!secret) {
      return jsonResponse({ error: "server_misconfigured" }, 500, undefined, req);
    }

    // Fetch booking with client info and service details.
    // `payment_mode` + `remaining_amount` sont stockés sur `bookings` depuis
    // la migration 20260401100000 — pas besoin de recalculer ici.
    const { data: booking, error: bErr } = await supabase
      .from("bookings")
      .select(
        "id, service_id, client_id, pro_id, created_at, scanned_at, status, " +
        "booking_code, deposit_amount, total_amount, remaining_amount, " +
        "payment_mode, currency, " +
        "services(name, duration_minutes), " +
        "time_slots(date, start_time, end_time), " +
        "client:users!client_id(full_name, avatar_url)"
      )
      .eq("id", bookingId)
      .single();

    if (bErr || !booking) {
      return jsonResponse(
        { valid: false, reason: "booking_not_found" },
        200,
        undefined,
        req,
      );
    }

    // Only the pro owning this booking can scan
    if (booking.pro_id !== user.id) {
      return jsonResponse({ error: "forbidden" }, 403, undefined, req);
    }

    // Only allow scanning confirmed bookings
    if (booking.status === "cancelled_full_refund" || booking.status === "cancelled_no_refund") {
      return jsonResponse(
        { valid: false, reason: "booking_cancelled" },
        200,
        undefined,
        req,
      );
    }

    // Verify HMAC
    const data = `${booking.id}|${booking.service_id}|${booking.client_id}|${booking.created_at}`;
    const expectedHash = await hmacSha256(data, secret);

    if (!timingSafeEqual(String(qrHash), expectedHash)) {
      return jsonResponse(
        { valid: false, reason: "invalid_hash" },
        200,
        undefined,
        req,
      );
    }

    // Atomic compare-and-swap : un seul scanneur peut gagner la course.
    // La clause `.is("scanned_at", null)` sérialise les UPDATE concurrents
    // au niveau du row-lock Postgres — le perdant reçoit 0 lignes.
    const scannedAt = new Date().toISOString();
    const { data: swapRows, error: swapErr } = await supabase
      .from("bookings")
      .update({ scanned_at: scannedAt })
      .eq("id", bookingId)
      .is("scanned_at", null)
      .select("id");

    if (swapErr) {
      console.error("validate-qr-booking scan swap failed:", swapErr.message);
      return jsonResponse({ error: "internal_error" }, 500, undefined, req);
    }

    // Helper : construit le bloc bookingDetails partagé entre les réponses
    // « déjà scanné » et « scan valide ». Centralise le calcul défensif du
    // solde restant et la normalisation des colonnes NULL.
    const buildBookingDetails = () => {
      const client = booking.client as Record<string, unknown> | null;
      const service = booking.services as Record<string, unknown> | null;
      const slot = booking.time_slots as Record<string, unknown> | null;

      // deposit_amount est NOT NULL DEFAULT 0 depuis 20260410000002, mais
      // on reste défensif au cas où un fallback ancien remonterait NULL.
      const depositAmount = Number(booking.deposit_amount ?? 0);
      const totalAmount = Number(booking.total_amount ?? 0);

      // remaining_amount est stocké sur la ligne, mais on clampe à 0 pour
      // éviter d'afficher un solde négatif si jamais un paiement sur place
      // a déjà été enregistré et que la colonne n'est pas à jour.
      const storedRemaining = Number(booking.remaining_amount ?? 0);
      const computedRemaining = Math.max(totalAmount - depositAmount, 0);
      const amountRemaining = Math.max(
        storedRemaining > 0 ? storedRemaining : computedRemaining,
        0,
      );

      return {
        clientName: client?.full_name ?? "Client",
        clientAvatar: client?.avatar_url ?? null,
        serviceName: service?.name ?? "Service",
        serviceDuration: service?.duration_minutes ?? 60,
        date: slot?.date ?? "",
        startTime: slot?.start_time ?? "",
        endTime: slot?.end_time ?? "",
        bookingCode: booking.booking_code,
        status: booking.status,
        // Montants — le scanner Pro a besoin des 3 pour afficher la
        // bannière « acompte / solde / total » en cas de paiement partiel.
        paymentMode: (booking.payment_mode as string) ?? "full",
        amountPaid: depositAmount,
        amountRemaining,
        totalAmount,
        currency: (booking.currency as string) ?? "CAD",
      };
    };

    // Perdant de la course OU déjà scanné avant cet appel
    if (!swapRows?.length) {
      return jsonResponse(
        {
          valid: false,
          reason: "already_scanned",
          scannedAt: booking.scanned_at ?? scannedAt,
          bookingDetails: buildBookingDetails(),
        },
        200,
        undefined,
        req,
      );
    }

    await supabase.rpc("log_audit_action", {
      p_user_id: user.id,
      p_action: "booking_scanned",
      p_resource_type: "booking",
      p_resource_id: booking.id,
      p_metadata: { scanned_at: scannedAt },
    });

    return jsonResponse(
      {
        valid: true,
        bookingId: booking.id,
        bookingDetails: buildBookingDetails(),
      },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("validate-qr-booking error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
