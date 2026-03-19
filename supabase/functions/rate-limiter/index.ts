import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { Redis } from "https://esm.sh/@upstash/redis@1.31.6";

import { getClientIp, jsonHeaders, securityHeaders } from "../_shared/security.ts";

type Scope = "login" | "otp" | "payment";

const scopeConfig: Record<Scope, { limit: number; windowSec: number }> = {
  login: { limit: 5, windowSec: 15 * 60 },
  otp: { limit: 3, windowSec: 10 * 60 },
  payment: { limit: 3, windowSec: 60 * 60 },
};

const redis = new Redis({
  url: Deno.env.get("SUPABASE_KV_REST_URL") ?? "",
  token: Deno.env.get("SUPABASE_KV_REST_TOKEN") ?? "",
});

function toKey(scope: Scope, identifier: string): string {
  return `rate:${scope}:${identifier}`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
  }

  try {
    const body = await req.json();
    const scope = body.scope as Scope;
    const rawIdentifier = (body.identifier as string | undefined)?.trim();
    const ip = getClientIp(req);

    if (!scope || !scopeConfig[scope]) {
      return new Response(
        JSON.stringify({ error: "scope invalide (login|otp|payment)" }),
        { headers: jsonHeaders, status: 400 },
      );
    }

    const identifier = rawIdentifier && rawIdentifier.length > 0
      ? rawIdentifier
      : ip;
    const { limit, windowSec } = scopeConfig[scope];
    const key = toKey(scope, identifier);

    const count = await redis.incr(key);
    if (count === 1) {
      await redis.expire(key, windowSec);
    }

    if (count > limit) {
      const ttl = await redis.ttl(key);
      const retryInMinutes = Math.max(1, Math.ceil((ttl ?? windowSec) / 60));
      return new Response(
        JSON.stringify({
          allowed: false,
          message: `Trop de tentatives. Réessaie dans ${retryInMinutes} minutes.`,
          retryAfterSeconds: ttl ?? windowSec,
        }),
        { headers: jsonHeaders, status: 429 },
      );
    }

    return new Response(
      JSON.stringify({
        allowed: true,
        remaining: Math.max(0, limit - count),
      }),
      { headers: jsonHeaders, status: 200 },
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: jsonHeaders,
      status: 400,
    });
  }
});
