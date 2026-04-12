import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export type SpotifyTokenRow = {
  access_token: string;
  refresh_token: string;
  expires_at: string;
};

/**
 * Retourne un access_token valide pour le pro, en rafraîchissant via refresh_token si besoin.
 */
export async function getValidProAccessToken(
  service: SupabaseClient,
  proId: string,
): Promise<string | null> {
  const { data: row, error } = await service
    .from("pro_spotify_tokens")
    .select("access_token, refresh_token, expires_at")
    .eq("pro_id", proId)
    .maybeSingle();

  if (error || !row) return null;

  const r = row as SpotifyTokenRow;
  const expMs = new Date(r.expires_at).getTime();
  if (Date.now() < expMs - 60_000) {
    return r.access_token;
  }

  const refreshed = await refreshAccessToken(r.refresh_token);
  if (!refreshed) return null;

  const newExpires = new Date(
    Date.now() + refreshed.expires_in * 1000,
  ).toISOString();
  const patch: Record<string, string> = {
    access_token: refreshed.access_token,
    expires_at: newExpires,
    updated_at: new Date().toISOString(),
  };
  if (refreshed.refresh_token) {
    patch.refresh_token = refreshed.refresh_token;
  }

  await service
    .from("pro_spotify_tokens")
    .update(patch)
    .eq("pro_id", proId);

  return refreshed.access_token;
}

async function refreshAccessToken(refreshToken: string): Promise<{
  access_token: string;
  refresh_token?: string;
  expires_in: number;
} | null> {
  const clientId = Deno.env.get("SPOTIFY_CLIENT_ID") ?? "";
  const clientSecret = Deno.env.get("SPOTIFY_CLIENT_SECRET") ?? "";
  if (!clientId || !clientSecret) return null;

  const res = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization: "Basic " + btoa(`${clientId}:${clientSecret}`),
    },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: refreshToken,
    }),
  });

  if (!res.ok) return null;
  return await res.json();
}

/** Mappe un item track Spotify API → payload client (aligné spotify-search). */
export function mapSpotifyTrackItem(t: Record<string, unknown>): {
  id: string;
  name: string;
  artist: string;
  albumArt: string | null;
  previewUrl: string | null;
  durationMs: number;
  spotifyUri: string;
} {
  const artists = (t.artists as Record<string, unknown>[]) ?? [];
  const album = (t.album as Record<string, unknown>) ?? {};
  const images = (album.images as Record<string, unknown>[]) ?? [];
  return {
    id: t.id as string,
    name: t.name as string,
    artist: artists.map((a) => a.name as string).join(", "),
    albumArt: images.length > 0 ? (images[0].url as string) : null,
    previewUrl: (t.preview_url as string) ?? null,
    durationMs: t.duration_ms as number,
    spotifyUri: t.uri as string,
  };
}
