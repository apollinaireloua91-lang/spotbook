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

    const { data: pro } = await service
      .from("profiles_pro")
      .select("id")
      .eq("id", user.id)
      .maybeSingle();
    if (!pro) {
      return jsonResponse({ error: "Compte pro requis" }, 403);
    }

    const body = await req.json().catch(() => ({}));
    const code = typeof body.code === "string" ? body.code.trim() : "";
    if (!code) {
      return jsonResponse({ error: "code manquant" }, 400);
    }

    const redirectUri = Deno.env.get("SPOTIFY_REDIRECT_URI") ?? "";
    const clientId = Deno.env.get("SPOTIFY_CLIENT_ID") ?? "";
    const clientSecret = Deno.env.get("SPOTIFY_CLIENT_SECRET") ?? "";
    if (!redirectUri || !clientId || !clientSecret) {
      return jsonResponse({ error: "Configuration Spotify incomplète" }, 500);
    }

    const tokenRes = await fetch("https://accounts.spotify.com/api/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: "Basic " + btoa(`${clientId}:${clientSecret}`),
      },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        code,
        redirect_uri: redirectUri,
      }),
    });

    if (!tokenRes.ok) {
      const detail = await tokenRes.text();
      return jsonResponse(
        { error: "Échange Spotify refusé", detail },
        400,
      );
    }

    const tok = await tokenRes.json() as {
      access_token: string;
      refresh_token: string;
      expires_in: number;
    };

    let spotifyUserId: string | null = null;
    try {
      const me = await fetch("https://api.spotify.com/v1/me", {
        headers: { Authorization: `Bearer ${tok.access_token}` },
      });
      if (me.ok) {
        const meJson = await me.json() as { id?: string };
        spotifyUserId = meJson.id ?? null;
      }
    } catch {
      // optionnel
    }

    const expiresAt = new Date(Date.now() + tok.expires_in * 1000).toISOString();
    const now = new Date().toISOString();

    // Encrypt tokens before storage (same pattern as link-instagram/tiktok/youtube)
    const keyHex = Deno.env.get("SOCIAL_TOKEN_KEY_HEX") ?? "";
    let encAccessToken = tok.access_token;
    let encRefreshToken = tok.refresh_token;
    let tokenNonce: string | null = null;

    if (keyHex && keyHex.length === 64) {
      const { data: encAccess } = await service.rpc("encrypt_social_token", {
        p_plaintext: tok.access_token,
        p_key_hex: keyHex,
      });
      const { data: encRefresh } = await service.rpc("encrypt_social_token", {
        p_plaintext: tok.refresh_token,
        p_key_hex: keyHex,
      });
      if (encAccess?.encrypted && encAccess?.nonce) {
        encAccessToken = encAccess.encrypted;
        tokenNonce = encAccess.nonce;
      }
      if (encRefresh?.encrypted) {
        encRefreshToken = encRefresh.encrypted;
      }
    }

    const patch = {
      access_token: encAccessToken,
      refresh_token: encRefreshToken,
      token_nonce: tokenNonce,
      expires_at: expiresAt,
      spotify_user_id: spotifyUserId,
      updated_at: now,
    };

    const { data: existing } = await service
      .from("pro_spotify_tokens")
      .select("pro_id")
      .eq("pro_id", user.id)
      .maybeSingle();

    const upRes = existing
      ? await service.from("pro_spotify_tokens").update(patch).eq("pro_id", user.id)
      : await service.from("pro_spotify_tokens").insert({
        pro_id: user.id,
        ...patch,
        created_at: now,
      });

    if (upRes.error) {
      return jsonResponse({ error: upRes.error.message }, 500);
    }

    return jsonResponse({ ok: true, spotifyUserId });
  } catch (e) {
    return jsonResponse({ error: (e as Error).message }, 500);
  }
});
