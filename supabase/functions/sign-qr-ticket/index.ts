import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { encode as hexEncode } from "https://deno.land/std@0.168.0/encoding/hex.ts";
import {
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";
import { generateQrPng } from "../_shared/qr_png.ts";

async function assertCanSignTicket(
  req: Request,
  ticketOwnerUserId: string,
): Promise<Response | null> {
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const auth = req.headers.get("Authorization") ?? "";
  if (serviceKey && auth === `Bearer ${serviceKey}`) {
    return null;
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: auth } } },
  );
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
  }
  if (user.id !== ticketOwnerUserId) {
    return jsonResponse({ error: "forbidden" }, 403, undefined, req);
  }
  return null;
}

async function hmacSha256(data: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(data)
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
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { ticketId } = await req.json();
    if (!ticketId || !isValidUuid(String(ticketId))) {
      return jsonResponse(
        { error: "ticketId doit être un UUID valide" },
        400,
        undefined,
        req,
      );
    }

    const { data: ticket, error: tErr } = await supabase
      .from("tickets")
      .select("id, event_id, user_id, purchased_at")
      .eq("id", ticketId)
      .single();

    if (tErr || !ticket) {
      return jsonResponse({ error: "ticket_not_found" }, 404, undefined, req);
    }

    const denied = await assertCanSignTicket(req, ticket.user_id as string);
    if (denied) return denied;

    const data = `${ticket.id}|${ticket.event_id}|${ticket.user_id}|${ticket.purchased_at}`;
    const secret = Deno.env.get("QR_SIGNING_SECRET") ?? "";
    if (!secret || secret.length < 16) {
      console.error("QR_SIGNING_SECRET manquant ou trop court (min 16 caractères)");
      return jsonResponse({ error: "server_misconfigured" }, 500, undefined, req);
    }
    const qrHash = await hmacSha256(data, secret);

    await supabase
      .from("tickets")
      .update({ qr_hash: qrHash, status: "valid" })
      .eq("id", ticketId);
    await supabase.rpc("log_audit_action", {
      p_user_id: ticket.user_id,
      p_action: "ticket_purchased",
      p_resource_type: "ticket",
      p_resource_id: ticket.id,
      p_metadata: { event_id: ticket.event_id },
    });

    // ── Generate QR PNG and upload to Storage ──────────────────────
    let qrCodeUrl: string | undefined;
    try {
      const qrData = `${ticketId}|${qrHash}`;
      const pngBytes = generateQrPng(qrData, 8, 2);

      // Ensure bucket exists (idempotent — error ignored if already created)
      await supabase.storage.createBucket("ticket-qr-codes", { public: true });

      const filePath = `${ticketId}.png`;
      const { error: uploadErr } = await supabase.storage
        .from("ticket-qr-codes")
        .upload(filePath, pngBytes, {
          contentType: "image/png",
          upsert: true,
        });

      if (uploadErr) {
        console.error("QR PNG upload failed:", uploadErr.message);
      } else {
        const { data: urlData } = supabase.storage
          .from("ticket-qr-codes")
          .getPublicUrl(filePath);
        qrCodeUrl = urlData?.publicUrl;
      }
    } catch (qrErr) {
      // QR image generation is non-blocking — ticket is still valid without it
      console.error("QR PNG generation failed:", qrErr);
    }

    return jsonResponse(
      { success: true, ticketId, qrCodeUrl },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("sign-qr-ticket error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
