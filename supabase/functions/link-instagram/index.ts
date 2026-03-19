import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { jsonHeaders, sanitizeText, securityHeaders } from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: securityHeaders });
  }
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );
    const { code } = await req.json();
    const oauthCode = sanitizeText(String(code ?? ""));
    if (!oauthCode) {
      return new Response(JSON.stringify({ error: "code requis" }), {
        headers: jsonHeaders,
        status: 400,
      });
    }
    
    // Mocking the OAuth flow: graph.facebook.com -> token -> graph.instagram.com/me -> followers
    // In a real app, we would exchange the code for an access token, then fetch user data.
    const mockFollowers = Math.floor(Math.random() * 50000) + 10000;
    const mockHandle = 'insta_pro_' + Math.floor(Math.random() * 1000);
    
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const encrypted = await supabase.rpc("encrypt_social_token", {
      p_token: "mock_token",
    });
    if (encrypted.error) throw encrypted.error;

    await supabase.from('social_connections').upsert({
      pro_id: user.id,
      platform: 'instagram',
      handle: mockHandle,
      followers_count: mockFollowers,
      access_token: encrypted.data,
      refresh_token: 'mock_refresh',
      updated_at: new Date().toISOString(),
    });

    return new Response(JSON.stringify({ success: true, followers: mockFollowers, handle: mockHandle }), {
      headers: jsonHeaders,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: jsonHeaders,
      status: 400,
    });
  }
});
