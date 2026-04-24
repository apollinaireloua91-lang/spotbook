import { serve } from "@std/http/server";
import { createClient } from "@supabase/supabase-js";
import Stripe from "stripe";
import { jsonResponse, securityHeadersFor } from "../_shared/security.ts";

const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY");
if (!stripeSecret) {
  throw new Error("Missing STRIPE_SECRET_KEY");
}

const stripe = new Stripe(stripeSecret, { apiVersion: "2023-10-16" });

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  let step = "init";
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized", reason: "no_auth_header" }, 401, undefined, req);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse({ error: "Server misconfiguration" }, 500, undefined, req);
    }

    // Authenticate user
    step = "auth";
    const token = authHeader.replace("Bearer ", "");
    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { data: authData, error: authError } = await adminClient.auth.getUser(token);
    if (authError || !authData?.user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }
    const user = authData.user;

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Parse request body for country selection (required on first-time onboarding).
    // Stripe Express country is immutable after account creation, so we capture it once here.
    step = "parse_body";
    const ALLOWED_COUNTRIES = ["CA", "FR", "US"] as const;
    type AllowedCountry = typeof ALLOWED_COUNTRIES[number];
    let requestedCountry: AllowedCountry | null = null;
    try {
      const bodyText = await req.text();
      if (bodyText) {
        const body = JSON.parse(bodyText) as { country?: unknown };
        if (typeof body.country === "string") {
          const upper = body.country.toUpperCase();
          if ((ALLOWED_COUNTRIES as readonly string[]).includes(upper)) {
            requestedCountry = upper as AllowedCountry;
          }
        }
      }
    } catch (_) {
      // Invalid JSON is fine — country is optional for re-onboarding existing accounts.
    }

    // Fetch profile
    step = "fetch_profile";
    const { data: profile, error: profileError } = await supabase
      .from("profiles_pro")
      .select("stripe_account_id, stripe_onboarded, country")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      return jsonResponse({ error: "Pro profile not found", step }, 404, undefined, req);
    }

    let accountId = profile.stripe_account_id as string | null;

    // Create Stripe account if needed
    if (!accountId) {
      step = "create_account";
      // Country resolution: explicit body param > previously saved profiles_pro.country > env fallback.
      const existingCountry = (profile.country as string | null)?.toUpperCase() ?? null;
      const envFallback = Deno.env.get("STRIPE_DEFAULT_COUNTRY") || "CA";
      const country: string =
        requestedCountry ??
        (existingCountry && (ALLOWED_COUNTRIES as readonly string[]).includes(existingCountry)
          ? existingCountry
          : envFallback);

      if (!(ALLOWED_COUNTRIES as readonly string[]).includes(country)) {
        return jsonResponse(
          { error: "country_not_supported", step, country },
          400,
          undefined,
          req,
        );
      }

      try {
        // Idempotency : clé stable par user.id. Si la requête précédente
        // a créé le compte Stripe mais échoué à persister l'id en DB
        // (orphelin), la retry renvoie le MÊME compte au lieu d'en créer
        // un second. Stripe conserve la clé 24 h.
        const account = await stripe.accounts.create(
          {
            type: "express",
            country,
            ...(user.email ? { email: user.email } : {}),
            capabilities: {
              card_payments: { requested: true },
              transfers: { requested: true },
            },
            metadata: { spotbook_user_id: user.id },
          },
          { idempotencyKey: `connect-account-${user.id}` },
        );
        accountId = account.id;
      } catch (stripeErr: unknown) {
        const e = stripeErr as {
          type?: string;
          code?: string;
          message?: string;
          raw?: { type?: string; code?: string; message?: string; param?: string };
          statusCode?: number;
        };
        const stripeDetail = {
          step,
          stripe_type: e?.type || e?.raw?.type,
          stripe_code: e?.code || e?.raw?.code,
          stripe_param: e?.raw?.param,
          stripe_status: e?.statusCode,
          stripe_message: e?.message || e?.raw?.message || String(stripeErr),
        };
        console.error(`[onboarding] STRIPE_ERROR at step=${step}:`, JSON.stringify(stripeDetail));
        return jsonResponse(
          { error: "stripe_create_account_failed", ...stripeDetail },
          500,
          undefined,
          req,
        );
      }

      step = "save_account_id";
      const { error: updateErr } = await supabase
        .from("profiles_pro")
        .update({ stripe_account_id: accountId, country })
        .eq("id", user.id);

      if (updateErr) {
        // Compte Stripe déjà créé mais DB pas mise à jour → orphelin.
        // Le log STRUCTURÉ permet à ops de récupérer l'account id pour
        // réconciliation manuelle. Grâce à l'idempotency key ci-dessus,
        // une retry dans les 24 h renverra le MÊME accountId.
        console.error(
          `[onboarding] ORPHAN_ACCOUNT user=${user.id} stripe_account=${accountId} db_error=${updateErr.message}`,
        );
        return jsonResponse(
          {
            error: "db_update_failed",
            step,
            orphan_account: accountId,
            db_message: updateErr.message,
          },
          500,
          undefined,
          req,
        );
      }
    }

    // Retrieve account status
    step = "retrieve_account";
    const stripeAccount = await stripe.accounts.retrieve(accountId);
    const onboarded =
      stripeAccount.details_submitted === true &&
      stripeAccount.charges_enabled === true &&
      stripeAccount.payouts_enabled === true;

    step = "update_onboarded";
    const { error: onboardUpdateErr } = await supabase
      .from("profiles_pro")
      .update({ stripe_onboarded: onboarded })
      .eq("id", user.id);

    if (onboardUpdateErr) {
      return jsonResponse({ error: onboardUpdateErr.message, step }, 500, undefined, req);
    }

    // Create AccountLink for onboarding
    step = "create_account_link";
    // Stripe AccountLinks require HTTPS — custom schemes (app.spotbook://) are rejected.
    // We route through a public HTTPS edge function that then deep-links back to the app.
    const returnBase = `${supabaseUrl}/functions/v1/stripe-return`;

    try {
      const accountLink = await stripe.accountLinks.create({
        account: accountId,
        refresh_url: `${returnBase}?status=refresh`,
        return_url: `${returnBase}?status=success`,
        type: "account_onboarding",
      });
      return jsonResponse({ url: accountLink.url }, 200, undefined, req);
    } catch (stripeErr: unknown) {
      const e = stripeErr as {
        type?: string;
        code?: string;
        message?: string;
        raw?: { type?: string; code?: string; message?: string };
        statusCode?: number;
      };
      const stripeDetail = {
        step,
        stripe_type: e?.type || e?.raw?.type,
        stripe_code: e?.code || e?.raw?.code,
        stripe_status: e?.statusCode,
        stripe_message: e?.message || e?.raw?.message || String(stripeErr),
      };
      console.error(`[onboarding] STRIPE_ERROR at step=${step}:`, JSON.stringify(stripeDetail));
      return jsonResponse(
        { error: "stripe_account_link_failed", ...stripeDetail },
        500,
        undefined,
        req,
      );
    }
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    const stack = error instanceof Error ? error.stack : undefined;
    console.error(`[onboarding] FAIL at step=${step}:`, msg, stack);
    return jsonResponse({ error: msg, step }, 500, undefined, req);
  }
});
