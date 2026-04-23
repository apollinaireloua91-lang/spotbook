// Edge Function: stripe-terminal-connection-token
//
// Mints a short-lived Stripe Terminal connection token for the authenticated
// Pro. The Stripe Terminal SDK (mek_stripe_terminal Flutter plugin → iOS
// StripeTerminal 4.x) calls this endpoint at startup and whenever the
// previous token expires.
//
// Connection tokens are scoped to the platform (= our Stripe secret key),
// NOT to the connected account. Stripe Terminal then routes the actual
// PaymentIntent to the Pro's connected account through the
// `transfer_data.destination` we set in `create-pos-payment-intent`.
//
// Reference:
//   https://stripe.com/docs/terminal/payments/setup-integration?reader=tap-to-pay#connection-token
//
// Request body (JSON, all fields optional):
//   {
//     location_id?: string  // Stripe Terminal location ID (optional —
//                            // useful once the Pro has registered a
//                            // `terminal.location` for receipts / reporting)
//   }
//
// Response 200:
//   { secret: string }
//
// Errors:
//   401 unauthorized                  — no JWT or invalid JWT
//   403 not_a_pro                     — auth.uid() not present in profiles_pro
//   409 stripe_connect_not_onboarded  — Pro has no stripe_account_id
//   429 rate_limited                  — too many token requests
//   500 internal_error                — Stripe call failed or other internal issue

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  checkRateLimit,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

interface RequestPayload {
  location_id?: string | null;
}

function parsePayload(raw: unknown): { ok: true; value: RequestPayload } | { ok: false; error: string } {
  // Empty body is allowed — `location_id` is optional.
  if (raw === null || raw === undefined) {
    return { ok: true, value: {} };
  }
  if (typeof raw !== "object") {
    return { ok: false, error: "invalid_body" };
  }
  const b = raw as Record<string, unknown>;

  let locationId: string | null = null;
  if (typeof b.location_id === "string" && b.location_id.trim().length > 0) {
    const v = b.location_id.trim();
    // Stripe Terminal location IDs are short (`tml_...`) — guard against
    // pathological inputs that would just balloon the Stripe call.
    if (!/^tml_[A-Za-z0-9]+$/.test(v) || v.length > 64) {
      return { ok: false, error: "invalid_location_id" };
    }
    locationId = v;
  }

  return { ok: true, value: { location_id: locationId } };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    // Body parsing — body may be empty, that's fine.
    let raw: unknown = null;
    const contentLength = req.headers.get("content-length");
    if (contentLength && contentLength !== "0") {
      try {
        raw = await req.json();
      } catch {
        return jsonResponse({ error: "invalid_json" }, 400, undefined, req);
      }
    }
    const parsed = parsePayload(raw);
    if (!parsed.ok) {
      return jsonResponse({ error: parsed.error }, 400, undefined, req);
    }

    // Rate-limit per Pro on the `payment` bucket — Tap-to-Pay token requests
    // are normally a handful per hour at most (initial connect + occasional
    // refresh). Stripe's tokens are valid ~1h server-side; the SDK shouldn't
    // be re-asking constantly. A burst means a buggy retry loop or abuse.
    try {
      const rl = await checkRateLimit({ scope: "payment", key: `terminal-token:${user.id}` });
      if (!rl.allowed) {
        return jsonResponse(
          { error: "rate_limited", retry_in_minutes: rl.retryInMinutes },
          429,
          undefined,
          req,
        );
      }
    } catch (rlErr) {
      // Rate-limit infra failure must not block legitimate Pros — log and
      // continue. (Stripe itself enforces a hard ceiling anyway.)
      console.error(
        JSON.stringify({
          level: "warn",
          code: "TERMINAL_TOKEN_RATELIMIT_INFRA_FAILED",
          userId: user.id,
          error: (rlErr as Error).message,
        }),
      );
    }

    // Service-role client for privileged read of `profiles_pro`.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: pro, error: proErr } = await supabase
      .from("profiles_pro")
      .select("id, stripe_account_id")
      .eq("id", user.id)
      .maybeSingle();

    if (proErr) {
      console.error(
        JSON.stringify({
          level: "error",
          code: "TERMINAL_TOKEN_PROFILE_LOOKUP_FAILED",
          userId: user.id,
          dbError: proErr.message,
        }),
      );
      return jsonResponse({ error: "internal_error" }, 500, undefined, req);
    }
    if (!pro) {
      return jsonResponse({ error: "not_a_pro" }, 403, undefined, req);
    }
    if (!pro.stripe_account_id) {
      return jsonResponse(
        { error: "stripe_connect_not_onboarded" },
        409,
        undefined,
        req,
      );
    }

    const stripeKey = Deno.env.get("STRIPE_SECRET_KEY") ?? "";
    if (!stripeKey) {
      console.error(
        JSON.stringify({
          level: "error",
          code: "TERMINAL_TOKEN_MISSING_STRIPE_KEY",
        }),
      );
      return jsonResponse({ error: "internal_error" }, 500, undefined, req);
    }

    const stripe = new Stripe(stripeKey, { apiVersion: "2023-10-16" });

    // Mint the connection token. The token is platform-scoped; the actual
    // PaymentIntent (created in `create-pos-payment-intent`) carries
    // `transfer_data.destination = pro.stripe_account_id` so the funds still
    // land on the correct connected account.
    //
    // `location` is optional; pass it only if the caller provided one (Pro
    // has registered a `terminal.location` for receipts / fleet management).
    const tokenParams: Stripe.Terminal.ConnectionTokenCreateParams = {};
    if (parsed.value.location_id) {
      tokenParams.location = parsed.value.location_id;
    }

    const token = await stripe.terminal.connectionTokens.create(tokenParams);

    console.log(
      JSON.stringify({
        level: "info",
        code: "TERMINAL_TOKEN_ISSUED",
        proId: user.id,
        stripeAccountId: pro.stripe_account_id,
        hasLocation: Boolean(parsed.value.location_id),
      }),
    );

    return jsonResponse({ secret: token.secret }, 200, undefined, req);
  } catch (error) {
    const err = error as Error & { type?: string; code?: string };
    console.error(
      JSON.stringify({
        level: "error",
        code: "TERMINAL_TOKEN_UNEXPECTED",
        message: err.message,
        stripeType: err.type,
        stripeCode: err.code,
      }),
    );
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
