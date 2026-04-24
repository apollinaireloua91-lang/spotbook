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
import { generateQrPng } from "../_shared/qr_png.ts";

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

    // Only service role or the booking owner can sign
    const { bookingId } = await req.json();
    if (!bookingId || !isValidUuid(String(bookingId))) {
      return jsonResponse(
        { error: "bookingId doit être un UUID valide" },
        400,
        undefined,
        req,
      );
    }

    const { data: booking, error: bErr } = await supabase
      .from("bookings")
      .select("id, service_id, client_id, created_at")
      .eq("id", bookingId)
      .single();

    if (bErr || !booking) {
      return jsonResponse({ error: "booking_not_found" }, 404, undefined, req);
    }

    // Auth check: service role or booking owner
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const auth = req.headers.get("Authorization") ?? "";
    if (!timingSafeEqual(auth, `Bearer ${serviceKey}`)) {
      const authClient = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_ANON_KEY") ?? "",
        { global: { headers: { Authorization: auth } } },
      );
      const {
        data: { user },
      } = await authClient.auth.getUser();
      if (!user || user.id !== booking.client_id) {
        return jsonResponse({ error: "forbidden" }, 403, undefined, req);
      }
    }

    const secret = getQrSigningSecret();
    if (!secret) {
      return jsonResponse({ error: "server_misconfigured" }, 500, undefined, req);
    }

    // Hash payload: bookingId|serviceId|clientId|createdAt
    const data = `${booking.id}|${booking.service_id}|${booking.client_id}|${booking.created_at}`;
    const qrHash = await hmacSha256(data, secret);

    // Update booking with hash
    await supabase
      .from("bookings")
      .update({ qr_hash: qrHash })
      .eq("id", bookingId);

    // Generate QR PNG — prefixed with "B:" to distinguish from ticket QR
    let qrCodeUrl: string | undefined;
    try {
      const qrData = `B:${bookingId}|${qrHash}`;
      const pngBytes = generateQrPng(qrData, 8, 2);

      // Bucket PRIVÉ : un QR de RDV donne accès au service, traité comme
      // bearer-token. On sert uniquement via signed URL courte durée.
      await supabase.storage.createBucket("booking-qr-codes", { public: false });

      const filePath = `${bookingId}.png`;
      const { error: uploadErr } = await supabase.storage
        .from("booking-qr-codes")
        .upload(filePath, pngBytes, {
          contentType: "image/png",
          upsert: true,
        });

      if (uploadErr) {
        console.error("QR PNG upload failed:", uploadErr.message);
      } else {
        const { data: signed, error: signErr } = await supabase.storage
          .from("booking-qr-codes")
          .createSignedUrl(filePath, 60 * 60);
        if (signErr) {
          console.error("QR signed URL failed:", signErr.message);
        } else {
          qrCodeUrl = signed?.signedUrl;
          // On ne persiste PAS l'URL signée (TTL 1h → périmée).
          // Le client appelle get-qr-url à chaque affichage.
        }
      }
    } catch (qrErr) {
      console.error("QR PNG generation failed:", qrErr);
    }

    await supabase.rpc("log_audit_action", {
      p_user_id: booking.client_id,
      p_action: "booking_qr_signed",
      p_resource_type: "booking",
      p_resource_id: booking.id,
      p_metadata: { service_id: booking.service_id },
    });

    return jsonResponse(
      { success: true, bookingId, qrCodeUrl },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("sign-qr-booking error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
