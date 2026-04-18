import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  jsonResponse,
  sanitizeText,
  securityHeadersFor,
} from "../_shared/security.ts";

// ─────────────────────────────────────────────────────────────────────
// geocode-city — resolve (city, country) → {latitude, longitude}.
// Caches results in public.cities_cache so Google Geocoding is hit at
// most once per unique (city, country) pair across all clients.
// Auth: any authenticated Spotbook user. Used by the client search map
// to place Pros who don't have exact coordinates.
// ─────────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    // ── 1. Authenticate caller ──
    const supabaseAuth = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization") ?? "" },
        },
      },
    );
    const {
      data: { user },
    } = await supabaseAuth.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    // ── 2. Parse & sanitize input ──
    const body = await req.json().catch(() => ({}));
    const city = sanitizeText(String(body?.city ?? "")).slice(0, 120).trim();
    const country =
      sanitizeText(String(body?.country ?? "")).slice(0, 80).trim();
    if (city.length < 2) {
      return jsonResponse({ error: "city_too_short" }, 400, undefined, req);
    }

    const key = `${city.toLowerCase()}|${country.toLowerCase()}`;

    // ── 3. Service client for cache R/W ──
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // ── 4. Cache hit? ──
    const { data: cached, error: cacheErr } = await serviceClient
      .from("cities_cache")
      .select("latitude, longitude")
      .eq("key", key)
      .maybeSingle();
    if (cacheErr) {
      console.error("cities_cache read error:", cacheErr);
    }
    if (cached) {
      return jsonResponse(
        {
          latitude: cached.latitude,
          longitude: cached.longitude,
          cached: true,
        },
        200,
        undefined,
        req,
      );
    }

    // ── 5. Cache miss → Google Geocoding ──
    const apiKey =
      Deno.env.get("GOOGLE_GEOCODING_KEY") ??
      Deno.env.get("GOOGLE_PLACES_KEY") ??
      "";
    if (!apiKey) {
      return jsonResponse(
        { error: "geocoding_not_configured" },
        500,
        undefined,
        req,
      );
    }

    const query = country ? `${city}, ${country}` : city;
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${
      encodeURIComponent(query)
    }&key=${apiKey}`;

    const resp = await fetch(url);
    if (!resp.ok) {
      return jsonResponse(
        { error: `geocoding_http_${resp.status}` },
        502,
        undefined,
        req,
      );
    }

    const data = await resp.json();
    const status = data?.status as string | undefined;
    if (status !== "OK") {
      return jsonResponse(
        { error: `geocoding_status_${status ?? "unknown"}` },
        status === "ZERO_RESULTS" ? 404 : 502,
        undefined,
        req,
      );
    }

    const loc = data?.results?.[0]?.geometry?.location as
      | { lat?: number; lng?: number }
      | undefined;
    const lat = typeof loc?.lat === "number" ? loc.lat : null;
    const lng = typeof loc?.lng === "number" ? loc.lng : null;
    if (lat === null || lng === null) {
      return jsonResponse(
        { error: "invalid_geocoding_response" },
        502,
        undefined,
        req,
      );
    }

    // ── 6. Persist to cache (best-effort, non-blocking on failure) ──
    const { error: insertErr } = await serviceClient
      .from("cities_cache")
      .insert({
        key,
        city,
        country: country || null,
        latitude: lat,
        longitude: lng,
      });
    if (insertErr) {
      // Duplicate key race is fine — another concurrent caller beat us to it.
      if (!String(insertErr.message).includes("duplicate")) {
        console.error("cities_cache insert error:", insertErr);
      }
    }

    return jsonResponse(
      { latitude: lat, longitude: lng, cached: false },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("geocode-city error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
