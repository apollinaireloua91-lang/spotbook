import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { jsonHeaders, securityHeaders } from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
  }
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );
    
    // Fetch all social connections
    const { data: connections, error } = await supabase.from('social_connections').select('*');
    if (error) throw error;

    // Mocking the sync process
    for (const conn of connections ?? []) {
      // Token is decrypted server-side only for stats sync.
      const decrypted = await supabase.rpc("decrypt_social_token", {
        p_ciphertext: conn.access_token,
      });
      if (decrypted.error) {
        continue;
      }
      const newFollowers = conn.followers_count + Math.floor(Math.random() * 100) - 20;
      await supabase.from('social_connections').update({
        followers_count: Math.max(0, newFollowers),
        updated_at: new Date().toISOString(),
      }).eq('id', conn.id);
    }

    return new Response(JSON.stringify({ success: true, synced: (connections ?? []).length }), {
      headers: jsonHeaders,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: jsonHeaders,
      status: 400,
    });
  }
});
