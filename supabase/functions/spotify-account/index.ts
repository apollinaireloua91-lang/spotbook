import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { jsonResponse, securityHeaders } from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: securityHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Non authentifié" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
    } = await userClient.auth.getUser();
    if (!user) return jsonResponse({ error: "Non authentifié" }, 401);

    const service = createClient(supabaseUrl, serviceKey);
    const { data } = await service
      .from("pro_spotify_tokens")
      .select("expires_at, spotify_user_id")
      .eq("pro_id", user.id)
      .maybeSingle();

    return jsonResponse({
      linked: !!data,
      expiresAt: data?.expires_at ?? null,
      spotifyUserId: data?.spotify_user_id ?? null,
    });
  } catch (e) {
    return jsonResponse({ error: (e as Error).message }, 500);
  }
});
