import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { encode as hexEncode } from "https://deno.land/std@0.168.0/encoding/hex.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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
    return new Response("ok", { headers: corsHeaders });
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
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    const { ticketId, qrHash } = await req.json();
    if (!ticketId || !qrHash) {
      return new Response(
        JSON.stringify({ error: "ticketId and qrHash required" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

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
          headers: { ...corsHeaders, "Content-Type": "application/json" },
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
          headers: { ...corsHeaders, "Content-Type": "application/json" },
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
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Mark as used
    await supabase
      .from("tickets")
      .update({ scanned_at: new Date().toISOString(), status: "used" })
      .eq("id", ticketId);

    return new Response(
      JSON.stringify({ valid: true, ticketId: ticket.id }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
