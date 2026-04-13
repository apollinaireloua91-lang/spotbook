import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { assertServiceRoleOnly, jsonResponse, securityHeaders } from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const forbidden = assertServiceRoleOnly(req);
  if (forbidden) return forbidden;

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );
    const keyHex = Deno.env.get("SOCIAL_TOKEN_KEY_HEX") ?? "";
    if (!keyHex || keyHex.length !== 64) {
      return jsonResponse({ error: "SOCIAL_TOKEN_KEY_HEX invalide" }, 500);
    }
    
    // Fetch all social connections
    const { data: connections, error } = await supabase
      .from('social_connections')
      .select('id, followers_count, access_token, token_nonce');
    if (error) throw error;

    // Mocking the sync process (token decrypted only server-side)
    for (const conn of connections) {
      if (conn.access_token && conn.token_nonce) {
        const { error: decErr } = await supabase.rpc("decrypt_social_token", {
          p_encrypted_base64: conn.access_token,
          p_nonce_hex: conn.token_nonce,
          p_key_hex: keyHex,
        });
        if (decErr) {
          continue;
        }
      }
      const newFollowers = conn.followers_count + Math.floor(Math.random() * 100) - 20;
      await supabase.from('social_connections').update({
        followers_count: Math.max(0, newFollowers),
        updated_at: new Date().toISOString(),
      }).eq('id', conn.id);
    }

    return jsonResponse({ success: true, synced: connections.length });
  } catch (error) {
    console.error("sync-social-stats error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
