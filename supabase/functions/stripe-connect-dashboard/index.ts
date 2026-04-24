import { serve } from "@std/http/server";
import { createClient } from "@supabase/supabase-js";
import Stripe from "stripe";
import { jsonResponse, securityHeadersFor } from "../_shared/security.ts";

/**
 * stripe-connect-dashboard
 *
 * Returns a Stripe Login Link (Express Dashboard URL) for an already-onboarded pro,
 * OR an AccountLink (onboarding URL) if onboarding is incomplete.
 * Also returns the current onboarding status.
 *
 * v22 — Self-healing: if the stored stripe_account_id is dead (resource_missing,
 * account_invalid, 404), we null it out in the DB and return `status: not_connected`
 * so the UI can show "Connect your bank" again.
 */

type StripeErrLike = {
  type?: string;
  code?: string;
  message?: string;
  raw?: { type?: string; code?: string; message?: string; param?: string };
  statusCode?: number;
};

function stripeDetail(err: unknown, step: string) {
  const e = err as StripeErrLike;
  return {
    step,
    stripe_type: e?.type || e?.raw?.type,
    stripe_code: e?.code || e?.raw?.code,
    stripe_param: e?.raw?.param,
    stripe_status: e?.statusCode,
    stripe_message: e?.message || e?.raw?.message || String(err),
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  let step = "init";
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

    if (!supabaseUrl || !serviceRoleKey || !stripeSecret) {
      console.error("[dashboard] missing env:", {
        supabaseUrl: !!supabaseUrl,
        serviceRoleKey: !!serviceRoleKey,
        stripeSecret: !!stripeSecret,
      });
      return jsonResponse({ error: "server_misconfiguration" }, 500, undefined, req);
    }

    // Authenticate user — use service role + token for reliable ES256 JWT verification
    step = "auth";
    const token = authHeader.replace("Bearer ", "");
    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { data: authData, error: authError } = await adminClient.auth.getUser(token);
    if (authError || !authData?.user) {
      console.error("[dashboard] getUser failed:", authError?.message);
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }
    const user = authData.user;

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Fetch pro profile
    step = "fetch_profile";
    const { data: profile, error: profileErr } = await supabase
      .from("profiles_pro")
      .select("stripe_account_id, stripe_onboarded")
      .eq("id", user.id)
      .single();

    if (profileErr || !profile) {
      return jsonResponse({ error: "pro_profile_not_found", step }, 404, undefined, req);
    }

    const stripe = new Stripe(stripeSecret, { apiVersion: "2023-10-16" });

    // No Stripe account yet → return status only
    if (!profile.stripe_account_id) {
      return jsonResponse(
        {
          status: "not_connected",
          detailsSubmitted: false,
          chargesEnabled: false,
          payoutsEnabled: false,
          url: null,
        },
        200,
        undefined,
        req,
      );
    }

    // Retrieve Stripe account to check current status
    step = "retrieve_account";
    let account;
    try {
      account = await stripe.accounts.retrieve(profile.stripe_account_id);
    } catch (stripeErr: unknown) {
      const detail = stripeDetail(stripeErr, step);
      console.error(
        `[dashboard] STRIPE_ERROR at step=${step}:`,
        JSON.stringify(detail),
      );

      // Self-healing: if the account ID is dead, null it out so the user can reconnect.
      const isRecoverable =
        detail.stripe_code === "resource_missing" ||
        detail.stripe_code === "account_invalid" ||
        detail.stripe_status === 404 ||
        /no such account|account.*not.*exist/i.test(detail.stripe_message ?? "");

      if (isRecoverable) {
        await supabase
          .from("profiles_pro")
          .update({ stripe_account_id: null, stripe_onboarded: false })
          .eq("id", user.id);

        return jsonResponse(
          {
            status: "not_connected",
            detailsSubmitted: false,
            chargesEnabled: false,
            payoutsEnabled: false,
            url: null,
            reset: true,
            reason: detail.stripe_code ?? "retrieve_failed",
          },
          200,
          undefined,
          req,
        );
      }

      return jsonResponse(
        { error: "stripe_retrieve_failed", ...detail },
        500,
        undefined,
        req,
      );
    }

    const detailsSubmitted = account.details_submitted === true;
    const chargesEnabled = account.charges_enabled === true;
    const payoutsEnabled = account.payouts_enabled === true;
    const fullyOnboarded = detailsSubmitted && chargesEnabled && payoutsEnabled;

    // Update DB status
    step = "update_onboarded";
    if (profile.stripe_onboarded !== fullyOnboarded) {
      await supabase
        .from("profiles_pro")
        .update({ stripe_onboarded: fullyOnboarded })
        .eq("id", user.id);
    }

    let url: string;

    if (fullyOnboarded) {
      // Fully onboarded → generate Login Link (Express Dashboard)
      step = "create_login_link";
      try {
        const loginLink = await stripe.accounts.createLoginLink(
          profile.stripe_account_id,
        );
        url = loginLink.url;
      } catch (stripeErr: unknown) {
        const detail = stripeDetail(stripeErr, step);
        console.error(
          `[dashboard] STRIPE_ERROR at step=${step}:`,
          JSON.stringify(detail),
        );
        return jsonResponse(
          { error: "stripe_login_link_failed", ...detail },
          500,
          undefined,
          req,
        );
      }
    } else {
      // Not fully onboarded → generate AccountLink to complete onboarding
      step = "create_account_link";
      // Stripe AccountLinks require HTTPS — custom schemes are rejected.
      const returnBase = `${supabaseUrl}/functions/v1/stripe-return`;

      try {
        const accountLink = await stripe.accountLinks.create({
          account: profile.stripe_account_id,
          refresh_url: `${returnBase}?status=refresh`,
          return_url: `${returnBase}?status=success`,
          type: "account_onboarding",
        });
        url = accountLink.url;
      } catch (stripeErr: unknown) {
        const detail = stripeDetail(stripeErr, step);
        console.error(
          `[dashboard] STRIPE_ERROR at step=${step}:`,
          JSON.stringify(detail),
        );
        return jsonResponse(
          { error: "stripe_account_link_failed", ...detail },
          500,
          undefined,
          req,
        );
      }
    }

    return jsonResponse(
      {
        status: fullyOnboarded ? "active" : "pending",
        detailsSubmitted,
        chargesEnabled,
        payoutsEnabled,
        url,
      },
      200,
      undefined,
      req,
    );
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    const stack = error instanceof Error ? error.stack : undefined;
    console.error(`[dashboard] FAIL at step=${step}:`, msg, stack);
    return jsonResponse({ error: msg, step }, 500, undefined, req);
  }
});
