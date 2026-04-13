import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  jsonResponse,
  sanitizeText,
  securityHeaders,
} from "../_shared/security.ts";

const corsHeaders = securityHeaders;

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'unauthorized' }, 401);
    }
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );
    const { code } = await req.json();
    if (!code || String(code).trim().length < 4) {
      return jsonResponse({ error: 'code OAuth invalide' }, 400);
    }

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return jsonResponse({ error: 'unauthorized' }, 401);

    // Mocking the OAuth flow: graph.facebook.com -> token -> graph.instagram.com/me -> followers
    // In a real app, we would exchange the code for an access token, then fetch user data.
    const mockFollowers = Math.floor(Math.random() * 50000) + 10000;
    const mockHandle = sanitizeText('insta_pro_' + Math.floor(Math.random() * 1000));
    const token = `mock_token_${crypto.randomUUID()}`;
    const nonce = Array.from(crypto.getRandomValues(new Uint8Array(24)))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
    const keyHex = Deno.env.get("SOCIAL_TOKEN_KEY_HEX") ?? "";
    if (!keyHex || keyHex.length !== 64) {
      return jsonResponse({ error: "SOCIAL_TOKEN_KEY_HEX invalide" }, 500);
    }

    // Use service_role client for encryption RPC — never send key via anon client
    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: encryptedToken, error: encErr } = await serviceClient.rpc(
      "encrypt_social_token",
      {
        p_token: token,
        p_nonce_hex: nonce,
        p_key_hex: keyHex,
      }
    );
    if (encErr || !encryptedToken) {
      return jsonResponse({ error: "Erreur chiffrement token" }, 500);
    }

    await serviceClient.from('social_connections').upsert({
      pro_id: user.id,
      platform: 'instagram',
      handle: mockHandle,
      followers_count: mockFollowers,
      access_token: encryptedToken,
      refresh_token: null,
      token_nonce: nonce,
      updated_at: new Date().toISOString(),
    });

    return jsonResponse({ success: true, followers: mockFollowers, handle: mockHandle });
  } catch (error) {
    console.error("link-instagram error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
