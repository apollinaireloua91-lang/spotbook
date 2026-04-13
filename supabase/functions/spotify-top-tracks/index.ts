import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  getValidProAccessToken,
  mapSpotifyTrackItem,
} from "../_shared/spotify_pro_tokens.ts";
import { jsonResponse, securityHeaders } from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: securityHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
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
    const access = await getValidProAccessToken(service, user.id);
    if (!access) {
      return jsonResponse({ linked: false, tracks: [] });
    }

    const body = await req.json().catch(() => ({}));
    const timeRange = body.time_range === "long_term"
      ? "long_term"
      : body.time_range === "medium_term"
      ? "medium_term"
      : "short_term";

    const url =
      `https://api.spotify.com/v1/me/top/tracks?limit=20&time_range=${timeRange}`;
    const tr = await fetch(url, {
      headers: { Authorization: `Bearer ${access}` },
    });

    if (!tr.ok) {
      const t = await tr.text();
      return jsonResponse(
        { error: "Spotify top tracks failed", detail: t, linked: true, tracks: [] },
        502,
      );
    }

    const data = await tr.json() as { items?: Record<string, unknown>[] };
    const items = data.items ?? [];
    const tracks = items.map((item) => mapSpotifyTrackItem(item));

    return jsonResponse({ linked: true, tracks });
  } catch (e) {
    console.error("spotify-top-tracks error:", e);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
