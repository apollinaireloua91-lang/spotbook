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

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized", reason: "no_auth_header" }, 401, undefined, req);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
      console.error("[onboarding] missing env:", { supabaseUrl: !!supabaseUrl, supabaseAnonKey: !!supabaseAnonKey, serviceRoleKey: !!serviceRoleKey });
      return jsonResponse(
        { error: "Server misconfiguration" },
        500,
        undefined,
        req,
      );
    }

    const supabaseAuth = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: authData, error: authError } = await supabaseAuth.auth.getUser();
    if (authError || !authData?.user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }
    const user = authData.user;

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data: profile, error: profileError } = await supabase
      .from("profiles_pro")
      .select("stripe_account_id, stripe_onboarded")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      return jsonResponse({ error: "Pro profile not found" }, 404, undefined, req);
    }

    let accountId = profile.stripe_account_id as string | null;

    if (!accountId) {
      const account = await stripe.accounts.create({
        type: "express",
        ...(user.email ? { email: user.email } : {}),
        metadata: { spotbook_user_id: user.id },
      });
      accountId = account.id;

      const { error: updateErr } = await supabase
        .from("profiles_pro")
        .update({ stripe_account_id: accountId })
        .eq("id", user.id);

      if (updateErr) {
        return jsonResponse(
          { error: updateErr.message },
          500,
          undefined,
          req,
        );
      }
    }

    const stripeAccount = await stripe.accounts.retrieve(accountId);
    const onboarded =
      stripeAccount.details_submitted === true &&
      stripeAccount.charges_enabled === true &&
      stripeAccount.payouts_enabled === true;

    const { error: onboardUpdateErr } = await supabase
      .from("profiles_pro")
      .update({ stripe_onboarded: onboarded })
      .eq("id", user.id);

    if (onboardUpdateErr) {
      return jsonResponse(
        { error: onboardUpdateErr.message },
        500,
        undefined,
        req,
      );
    }

    const deepLink = "app.spotbook://stripe-connect-callback";

    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: `${deepLink}?refresh=true`,
      return_url: `${deepLink}?success=true`,
      type: "account_onboarding",
    });

    return jsonResponse({ url: accountLink.url }, 200, undefined, req);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: message }, 500, undefined, req);
  }
});
