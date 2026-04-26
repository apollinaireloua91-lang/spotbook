import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

/** Origine CORS principale (app web / deep-link callbacks). Surcharge via secret Edge `EDGE_CORS_ORIGIN`. */
function defaultCorsOrigin(): string {
  return Deno.env.get("EDGE_CORS_ORIGIN")?.trim() || "https://getspotbook.app";
}

/**
 * En-têtes CORS + durcissement HTTP. Pour une webapp multi-domaines, définir `EDGE_ALLOWED_ORIGINS`
 * (séparateur virgule) ; si la requête envoie `Origin` et qu’il est dans la liste, il est reflété.
 */
export function securityHeadersFor(req: Request | null): Record<string, string> {
  const allowListRaw =
    Deno.env.get("EDGE_ALLOWED_ORIGINS")?.trim() ||
    `https://getspotbook.app,https://www.getspotbook.app,https://spotbook.app`;
  const allowed = allowListRaw.split(",").map((s) => s.trim()).filter(Boolean);
  const origin = req?.headers.get("Origin");
  const acao =
    origin && allowed.includes(origin) ? origin : (allowed[0] ?? defaultCorsOrigin());

  return {
    "Access-Control-Allow-Origin": acao,
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type, stripe-signature",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Strict-Transport-Security": "max-age=31536000",
    "Content-Security-Policy": "default-src 'self'",
  };
}

/** @deprecated Préférer `securityHeadersFor(req)` pour OPTIONS / réponses liées à une requête. */
export const securityHeaders = securityHeadersFor(null);

export function jsonResponse(
  data: unknown,
  status = 200,
  extraHeaders?: Record<string, string>,
  req?: Request | null,
) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...securityHeadersFor(req ?? null),
      "Content-Type": "application/json",
      ...(extraHeaders ?? {}),
    },
  });
}

/**
 * Longueur minimale du secret HMAC pour signer/valider les QR.
 * 32 bytes = 256 bits d'entropie, conforme à la taille du digest SHA-256.
 * Un secret plus court dégrade la résistance aux attaques préimages.
 */
export const QR_SIGNING_SECRET_MIN_LENGTH = 32;

/**
 * Récupère le secret de signature QR, retourne null si absent ou trop court.
 * Centralisé pour éviter des seuils incohérents entre signers et validators
 * (bug passé : signer acceptait 16 chars, validator exigeait 32 → hash
 * valides refusés comme "server_misconfigured").
 */
export function getQrSigningSecret(): string | null {
  const secret = Deno.env.get("QR_SIGNING_SECRET") ?? "";
  if (!secret || secret.length < QR_SIGNING_SECRET_MIN_LENGTH) {
    console.error(
      `QR_SIGNING_SECRET manquant ou trop court (min ${QR_SIGNING_SECRET_MIN_LENGTH} caractères)`,
    );
    return null;
  }
  return secret;
}

/** Timing-safe string comparison to prevent timing attacks on secret comparisons. */
export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  const encoder = new TextEncoder();
  const bufA = encoder.encode(a);
  const bufB = encoder.encode(b);
  if (bufA.byteLength !== bufB.byteLength) return false;
  // Use constant-time XOR comparison
  let result = 0;
  for (let i = 0; i < bufA.byteLength; i++) {
    result |= bufA[i] ^ bufB[i];
  }
  return result === 0;
}

/** Appels internes uniquement (Edge → Edge, pg_net, cron) : vérifie le JWT service_role Supabase. */
export function assertServiceRoleOnly(req: Request): Response | null {
  const expected = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const auth = req.headers.get("Authorization") ?? "";
  if (!expected || !timingSafeEqual(auth, `Bearer ${expected}`)) {
    return jsonResponse({ error: "forbidden" }, 403, undefined, req);
  }
  return null;
}

/**
 * Cron-style auth backed by a Vault-stored shared secret (cf. migration
 * 20260425100200_get_cron_shared_secret_rpc + Vault entry `cron_service_role_key`).
 *
 * Why we have this in addition to `assertServiceRoleOnly`:
 *   The hosted Supabase API gateway has been rolling out a JWT migration that
 *   rejects legacy HS256 service_role JWTs at the edge with
 *   `UNAUTHORIZED_LEGACY_JWT`. Functions deployed with `verify_jwt = false`
 *   can still receive any Authorization header — but `SUPABASE_SERVICE_ROLE_KEY`
 *   env var is now opaque (could be the new `sb_secret_…` format or a re-issued
 *   JWT) and pg_cron can't easily replicate it.
 *
 *   This helper uses a Vault-stored secret as the shared key between cron and
 *   Edge Function. The cron reads it with `decrypted_secret`; the function
 *   reads it via the `get_cron_shared_secret()` RPC. Both sides see the same
 *   value → the comparison passes regardless of what Supabase is doing with
 *   gateway-side keys.
 *
 * Use this for cron-only Edge Functions deployed with `verify_jwt = false`.
 * The function name is part of the contract — keep stable.
 */
let _cachedCronSecret: string | null = null;

export async function assertCronAuthFromVault(
  req: Request,
): Promise<Response | null> {
  const auth = req.headers.get("Authorization") ?? "";

  if (!_cachedCronSecret) {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!url || !serviceKey) {
      console.error(
        "[assertCronAuthFromVault] missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars",
      );
      return jsonResponse(
        { error: "server_misconfigured" },
        500,
        undefined,
        req,
      );
    }

    // Lazy import — the supabase-js client is heavy; only paid when first cron hits.
    const { createClient } = await import(
      "https://esm.sh/@supabase/supabase-js@2.39.3"
    );
    const client = createClient(url, serviceKey);
    const { data, error } = await client.rpc("get_cron_shared_secret");
    if (error || typeof data !== "string" || data.length === 0) {
      console.error(
        "[assertCronAuthFromVault] failed to read shared secret from Vault:",
        error,
      );
      return jsonResponse(
        { error: "server_misconfigured" },
        500,
        undefined,
        req,
      );
    }
    _cachedCronSecret = data;
  }

  if (!timingSafeEqual(auth, `Bearer ${_cachedCronSecret}`)) {
    return jsonResponse({ error: "forbidden" }, 403, undefined, req);
  }
  return null;
}

export const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function isValidUuid(value: string) {
  return uuidRegex.test(value);
}

export function isValidEmail(value: string) {
  return emailRegex.test(value);
}

export function sanitizeText(value: string) {
  return value
    .replace(/<script[\s\S]*?>[\s\S]*?<\/script>/gi, "")
    .replace(/<\/?[^>]+(>|$)/g, "")
    .trim();
}

export function isValidAmount(amount: number) {
  return Number.isFinite(amount) && amount > 0 && amount < 99999;
}

export function assertImageMime(mimeType: string) {
  return /^image\/(png|jpe?g|webp|gif)$/i.test(mimeType);
}

/** Types vidéo acceptés pour l’URL d’upload Stream (aligné client : mp4 / mov / m4v). */
export function assertVideoMime(mimeType: string) {
  return /^video\/(mp4|quicktime|x-m4v|3gpp|x-msvideo)$/i.test(mimeType);
}

export function getClientIp(req: Request) {
  const forwarded = req.headers.get("x-forwarded-for");
  if (forwarded) return forwarded.split(",")[0].trim();
  return req.headers.get("cf-connecting-ip") ?? "unknown";
}

type RateLimitInput = {
  scope: "login" | "signup" | "otp" | "payment" | "upload" | "booking";
  key: string;
};

const LIMITS: Record<RateLimitInput["scope"], { max: number; windowMs: number }> =
  {
    login: { max: 5, windowMs: 15 * 60 * 1000 },
    signup: { max: 10, windowMs: 30 * 60 * 1000 },
    otp: { max: 3, windowMs: 10 * 60 * 1000 },
    payment: { max: 3, windowMs: 60 * 60 * 1000 },
    upload: { max: 20, windowMs: 60 * 60 * 1000 },
    booking: { max: 5, windowMs: 60 * 1000 },
  };

export async function checkRateLimit(input: RateLimitInput) {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !serviceKey) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  }

  const now = Date.now();
  const cfg = LIMITS[input.scope];
  const bucket = Math.floor(now / cfg.windowMs);

  const supabase = createClient(url, serviceKey);
  const { data, error } = await supabase.rpc("rate_limit_consume", {
    p_scope: input.scope,
    p_rate_key: input.key,
    p_bucket: bucket,
    p_max: cfg.max,
    p_window_ms: cfg.windowMs,
  });

  if (error) {
    throw new Error(error.message);
  }

  const row = Array.isArray(data) ? data[0] : data;
  if (!row || typeof row !== "object") {
    throw new Error("rate_limit_consume returned no row");
  }

  const r = row as Record<string, unknown>;
  return {
    allowed: Boolean(r.allowed),
    retryInMinutes: Number(r.retry_in_minutes ?? 0),
    remaining: Number(r.remaining ?? 0),
  };
}
