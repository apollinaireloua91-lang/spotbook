import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { encode as hexEncode } from "https://deno.land/std@0.168.0/encoding/hex.ts";
import {
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
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

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

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

    const { ticketId, qrHash } = await req.json();
    if (
      !ticketId ||
      !isValidUuid(String(ticketId)) ||
      !qrHash ||
      String(qrHash).length < 20
    ) {
      return jsonResponse(
        { error: "ticketId UUID valide et qrHash requis" },
        400,
        undefined,
        req,
      );
    }

    const secret = Deno.env.get("QR_SIGNING_SECRET") ?? "";
    if (!secret || secret.length < 32) {
      console.error("QR_SIGNING_SECRET manquant ou trop court");
      return jsonResponse({ error: "server_misconfigured" }, 500, undefined, req);
    }

    const { data: ticket, error: tErr } = await supabase
      .from("tickets")
      .select("id, event_id, user_id, purchased_at, scanned_at, status")
      .eq("id", ticketId)
      .single();

    if (tErr || !ticket) {
      return jsonResponse(
        { valid: false, reason: "ticket_not_found" },
        200,
        undefined,
        req,
      );
    }

    const { data: eventRow } = await supabase
      .from("events")
      .select("pro_id")
      .eq("id", ticket.event_id as string)
      .single();

    if (!eventRow || eventRow.pro_id !== user.id) {
      return jsonResponse({ error: "forbidden" }, 403, undefined, req);
    }

    const data = `${ticket.id}|${ticket.event_id}|${ticket.user_id}|${ticket.purchased_at}`;
    const expectedHash = await hmacSha256(data, secret);

    if (qrHash !== expectedHash) {
      return jsonResponse({ valid: false, reason: "invalid_hash" }, 200, undefined, req);
    }

    if (ticket.scanned_at) {
      return jsonResponse(
        {
          valid: false,
          reason: "already_used",
          scannedAt: ticket.scanned_at,
        },
        200,
        undefined,
        req,
      );
    }

    const scannedAt = new Date().toISOString();
    await supabase
      .from("tickets")
      .update({ scanned_at: scannedAt, status: "used" })
      .eq("id", ticketId);
    await supabase.rpc("log_audit_action", {
      p_user_id: user.id,
      p_action: "ticket_scanned",
      p_resource_type: "ticket",
      p_resource_id: ticket.id,
      p_metadata: { scanned_at: scannedAt },
    });

    return jsonResponse({ valid: true, ticketId: ticket.id }, 200, undefined, req);
  } catch (error) {
    console.error("validate-qr-ticket error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});




