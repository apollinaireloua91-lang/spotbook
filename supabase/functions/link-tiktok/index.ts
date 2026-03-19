import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

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
    
    // Mocking the OAuth flow: open.tiktokapis.com/v2/oauth/token/ -> follower_count
    const mockFollowers = Math.floor(Math.random() * 100000) + 20000;
    const mockHandle = 'tiktok_pro_' + Math.floor(Math.random() * 1000);
    
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    await supabase.from('social_connections').upsert({
      pro_id: user.id,
      platform: 'tiktok',
      handle: mockHandle,
      followers_count: mockFollowers,
      access_token: 'mock_token',
      refresh_token: 'mock_refresh',
      updated_at: new Date().toISOString(),
    });

    return new Response(JSON.stringify({ success: true, followers: mockFollowers, handle: mockHandle }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
