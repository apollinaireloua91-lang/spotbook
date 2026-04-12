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
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );
    const { code } = await req.json();
    if (!code || String(code).trim().length < 4) {
      return jsonResponse({ error: 'code OAuth invalide' }, 400);
    }
    
    // Mocking the OAuth flow: oauth2.googleapis.com/token -> youtube/v3/channels -> subscriberCount
    const mockFollowers = Math.floor(Math.random() * 500000) + 50000;
    const mockHandle = sanitizeText('yt_pro_' + Math.floor(Math.random() * 1000));
    const token = `mock_token_${crypto.randomUUID()}`;
    const nonce = Array.from(crypto.getRandomValues(new Uint8Array(24)))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
    const keyHex = Deno.env.get("SOCIAL_TOKEN_KEY_HEX") ?? "";
    if (!keyHex || keyHex.length !== 64) {
      return jsonResponse({ error: "SOCIAL_TOKEN_KEY_HEX invalide" }, 500);
    }
    
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: encryptedToken, error: encErr } = await supabase.rpc(
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

    await supabase.from('social_connections').upsert({
      pro_id: user.id,
      platform: 'youtube',
      handle: mockHandle,
      followers_count: mockFollowers,
      access_token: encryptedToken,
      refresh_token: null,
      token_nonce: nonce,
      updated_at: new Date().toISOString(),
    });

    return jsonResponse({ success: true, followers: mockFollowers, handle: mockHandle });
  } catch (error) {
    console.error("link-youtube error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
