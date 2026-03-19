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

    const { ticketId } = await req.json();
    if (!ticketId) {
      return new Response(
        JSON.stringify({ error: "ticketId required" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

    const { data: ticket, error: tErr } = await supabase
      .from("tickets")
      .select("id, event_id, user_id, purchased_at")
      .eq("id", ticketId)
      .single();

    if (tErr || !ticket) {
      return new Response(
        JSON.stringify({ error: "ticket_not_found" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 404,
        }
      );
    }

    const data = `${ticket.id}|${ticket.event_id}|${ticket.user_id}|${ticket.purchased_at}`;
    const secret = Deno.env.get("QR_SIGNING_SECRET") ?? "spotbook-qr-secret";
    const qrHash = await hmacSha256(data, secret);

    await supabase
      .from("tickets")
      .update({ qr_hash: qrHash, status: "valid" })
      .eq("id", ticketId);

    return new Response(
      JSON.stringify({ success: true, qr_hash: qrHash }),
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
