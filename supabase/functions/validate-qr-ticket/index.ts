import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { encode as hexEncode } from "https://deno.land/std@0.168.0/encoding/hex.ts";
import { assertUuid, jsonHeaders, securityHeaders } from "../_shared/security.ts";

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
    return new Response("ok", { headers: securityHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Auth check — only pros can scan
    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );
    const {
      data: { user },
    } = await authClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        headers: jsonHeaders,
        status: 401,
      });
    }

    const { ticketId, qrHash } = await req.json();
    if (!ticketId || !qrHash) {
      return new Response(
        JSON.stringify({ error: "ticketId and qrHash required" }),
        {
          headers: jsonHeaders,
          status: 400,
        }
      );
    }
    assertUuid(ticketId, "ticketId");

    const { data: ticket, error: tErr } = await supabase
      .from("tickets")
      .select("id, event_id, user_id, purchased_at, scanned_at, status")
      .eq("id", ticketId)
      .single();

    if (tErr || !ticket) {
      return new Response(
        JSON.stringify({
          valid: false,
          reason: "ticket_not_found",
        }),
        {
          headers: jsonHeaders,
        }
      );
    }

    // Recalculate HMAC
    const data = `${ticket.id}|${ticket.event_id}|${ticket.user_id}|${ticket.purchased_at}`;
    const secret = Deno.env.get("QR_SIGNING_SECRET") ?? "spotbook-qr-secret";
    const expectedHash = await hmacSha256(data, secret);

    if (qrHash !== expectedHash) {
      return new Response(
        JSON.stringify({ valid: false, reason: "invalid_hash" }),
        {
          headers: jsonHeaders,
        }
      );
    }

    // Already scanned
    if (ticket.scanned_at) {
      return new Response(
        JSON.stringify({
          valid: false,
          reason: "already_used",
          scannedAt: ticket.scanned_at,
        }),
        {
          headers: jsonHeaders,
        }
      );
    }

    // Mark as used
    await supabase
      .from("tickets")
      .update({ scanned_at: new Date().toISOString(), status: "used" })
      .eq("id", ticketId);
    await supabase.rpc("insert_audit_log", {
      p_user_id: ticket.user_id,
      p_action: "ticket_scanned",
      p_resource_type: "ticket",
      p_resource_id: ticket.id,
      p_metadata: { scanner_id: user.id, event_id: ticket.event_id },
      p_ip_address: "edge",
    });

    return new Response(
      JSON.stringify({ valid: true, ticketId: ticket.id }),
      {
        headers: jsonHeaders,
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: jsonHeaders,
      status: 400,
    });
  }
});
