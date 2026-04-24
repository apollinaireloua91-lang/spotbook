// ════════════════════════════════════════════════════════════════════════════
// get-qr-url
// ────────────────────────────────────────────────────────────────────────────
// Retourne une signed URL (TTL 1h) vers l'image QR d'un booking ou d'un
// ticket. Vérifie que l'utilisateur appelant est :
//   – le propriétaire (client_id / user_id de la ressource)
//   – OU le pro associé (pro_id du booking / event)
// Sinon 403. Les buckets `booking-qr-codes` et `ticket-qr-codes` sont privés.
// ════════════════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

const SIGNED_URL_TTL_SECONDS = 60 * 60;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
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
    const {
      data: { user },
    } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const { type, id } = await req.json();
    if (
      (type !== "booking" && type !== "ticket") ||
      !id ||
      !isValidUuid(String(id))
    ) {
      return jsonResponse(
        { error: "type doit être booking|ticket et id un UUID" },
        400,
        undefined,
        req,
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // ── Vérification propriétaire ────────────────────────────────────────
    let bucket: string;
    if (type === "booking") {
      const { data: booking, error } = await supabase
        .from("bookings")
        .select("client_id, pro_id")
        .eq("id", id)
        .single();
      if (error || !booking) {
        return jsonResponse({ error: "not_found" }, 404, undefined, req);
      }
      if (booking.client_id !== user.id && booking.pro_id !== user.id) {
        return jsonResponse({ error: "forbidden" }, 403, undefined, req);
      }
      bucket = "booking-qr-codes";
    } else {
      const { data: ticket, error } = await supabase
        .from("tickets")
        .select("user_id, event_id, events(pro_id)")
        .eq("id", id)
        .single();
      if (error || !ticket) {
        return jsonResponse({ error: "not_found" }, 404, undefined, req);
      }
      const eventProId =
        (ticket.events as { pro_id?: string } | null)?.pro_id;
      if (ticket.user_id !== user.id && eventProId !== user.id) {
        return jsonResponse({ error: "forbidden" }, 403, undefined, req);
      }
      bucket = "ticket-qr-codes";
    }

    const { data: signed, error: signErr } = await supabase.storage
      .from(bucket)
      .createSignedUrl(`${id}.png`, SIGNED_URL_TTL_SECONDS);

    if (signErr || !signed?.signedUrl) {
      console.error("get-qr-url sign failed:", signErr?.message);
      return jsonResponse({ error: "sign_failed" }, 500, undefined, req);
    }

    return jsonResponse(
      { qrCodeUrl: signed.signedUrl, expiresIn: SIGNED_URL_TTL_SECONDS },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("get-qr-url error:", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
