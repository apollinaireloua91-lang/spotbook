import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import { jsonResponse, securityHeadersFor } from "../_shared/security.ts";

/**
 * stripe-connect-dashboard
 *
 * Returns a Stripe Login Link (Express Dashboard URL) for an already-onboarded pro,
 * OR an AccountLink (onboarding URL) if onboarding is incomplete.
 * Also returns the current onboarding status.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: securityHeadersFor(req) });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    console.log("[dashboard] authHeader present:", !!authHeader, authHeader?.substring(0, 20));
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized", reason: "no_auth_header" }, 401, undefined, req);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

    if (!supabaseUrl || !serviceRoleKey || !stripeSecret) {
      console.error("[dashboard] missing env:", { supabaseUrl: !!supabaseUrl, serviceRoleKey: !!serviceRoleKey, stripeSecret: !!stripeSecret });
      return jsonResponse({ error: "server_misconfiguration" }, 500, undefined, req);
    }

    // Authenticate user
    const authClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: authData, error: authError } = await authClient.auth.getUser();
    console.log("[dashboard] getUser result:", { userId: authData?.user?.id, error: authError?.message });
    if (authError || !authData?.user) {
      return jsonResponse({ error: "unauthorized", reason: "getUser_failed", detail: authError?.message }, 401, undefined, req);
    }
    const user = authData.user;

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Fetch pro profile
    const { data: profile, error: profileErr } = await supabase
      .from("profiles_pro")
      .select("stripe_account_id, stripe_onboarded")
      .eq("id", user.id)
      .single();

    if (profileErr || !profile) {
      return jsonResponse({ error: "pro_profile_not_found" }, 404, undefined, req);
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
    const account = await stripe.accounts.retrieve(profile.stripe_account_id);
    const detailsSubmitted = account.details_submitted === true;
    const chargesEnabled = account.charges_enabled === true;
    const payoutsEnabled = account.payouts_enabled === true;
    const fullyOnboarded = detailsSubmitted && chargesEnabled && payoutsEnabled;

    // Update DB status
    if (profile.stripe_onboarded !== fullyOnboarded) {
      await supabase
        .from("profiles_pro")
        .update({ stripe_onboarded: fullyOnboarded })
        .eq("id", user.id);
    }

    let url: string;

    if (fullyOnboarded) {
      // Fully onboarded → generate Login Link (Express Dashboard)
      const loginLink = await stripe.accounts.createLoginLink(
        profile.stripe_account_id,
      );
      url = loginLink.url;
    } else {
      // Not fully onboarded → generate AccountLink to complete onboarding
      const webBase =
        Deno.env.get("SPOTBOOK_WEB_BASE_URL")?.replace(/\/$/, "") ||
        "https://getspotbook.app";

      const accountLink = await stripe.accountLinks.create({
        account: profile.stripe_account_id,
        refresh_url: `${webBase}/pro/stripe-connect?refresh=true`,
        return_url: `${webBase}/pro/stripe-connect?success=true`,
        type: "account_onboarding",
      });
      url = accountLink.url;
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
    console.error("stripe-connect-dashboard error:", error);
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: message }, 500, undefined, req);
  }
});
