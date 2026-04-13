import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  getValidProAccessToken,
  mapSpotifyTrackItem,
} from "../_shared/spotify_pro_tokens.ts";
import {
  jsonResponse,
  sanitizeText,
  securityHeaders,
} from "../_shared/security.ts";

const corsHeaders = securityHeaders;

// Spotify Client Credentials token (cached in-memory, refreshed on expiry)
let cachedToken: string | null = null;
let tokenExpiry = 0;

async function getSpotifyToken(): Promise<string> {
  if (cachedToken && Date.now() < tokenExpiry) return cachedToken;

  const clientId = Deno.env.get("SPOTIFY_CLIENT_ID") ?? "";
  const clientSecret = Deno.env.get("SPOTIFY_CLIENT_SECRET") ?? "";
  if (!clientId || !clientSecret) {
    throw new Error("SPOTIFY_CLIENT_ID or SPOTIFY_CLIENT_SECRET not set");
  }

  const res = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization:
        "Basic " + btoa(`${clientId}:${clientSecret}`),
    },
    body: "grant_type=client_credentials",
  });

  if (!res.ok) {
    throw new Error(`Spotify token error: ${res.status}`);
  }

  const data = await res.json();
  cachedToken = data.access_token as string;
  // Refresh 60s before expiry
  tokenExpiry = Date.now() + (data.expires_in - 60) * 1000;
  return cachedToken!;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  try {
    // Verify the caller is authenticated
    const supabase = createClient(
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
    } = await supabase.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "Non authentifié" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const serviceClient = createClient(supabaseUrl, serviceKey);

    const { query, type } = await req.json();
    const q = sanitizeText(String(query ?? "")).slice(0, 100);
    if (q.length < 2) {
      return jsonResponse({ error: "Requête trop courte" }, 400);
    }

    const searchType = type === "artist" ? "artist" : "track";

    const userAccess = await getValidProAccessToken(serviceClient, user.id);
    let bearer = userAccess;
    if (!bearer) {
      bearer = await getSpotifyToken();
    }

    const url = `https://api.spotify.com/v1/search?q=${encodeURIComponent(q)}&type=${searchType}&limit=10&market=FR`;
    const spotifyRes = await fetch(url, {
      headers: { Authorization: `Bearer ${bearer}` },
    });

    if (!spotifyRes.ok) {
      cachedToken = null;
      const retryUser = await getValidProAccessToken(serviceClient, user.id);
      const retryBearer = retryUser ?? await getSpotifyToken();
      const retryRes = await fetch(url, {
        headers: { Authorization: `Bearer ${retryBearer}` },
      });
      if (!retryRes.ok) {
        return jsonResponse(
          { error: `Spotify API error: ${retryRes.status}` },
          502
        );
      }
      const retryData = await retryRes.json();
      return jsonResponse(mapResults(retryData, searchType));
    }

    const data = await spotifyRes.json();
    return jsonResponse(mapResults(data, searchType));
  } catch (error) {
    console.error("spotify-search error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});

function mapResults(
  data: Record<string, unknown>,
  type: string
): { tracks: ReturnType<typeof mapSpotifyTrackItem>[] } {
  if (type === "track") {
    const items = ((data as Record<string, unknown>).tracks as Record<string, unknown>)?.items as unknown[];
    return {
      tracks: (items ?? []).map((item: unknown) =>
        mapSpotifyTrackItem(item as Record<string, unknown>)
      ),
    };
  }
  return { tracks: [] };
}
