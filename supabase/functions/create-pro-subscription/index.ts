import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import { jsonResponse, securityHeaders } from "../_shared/security.ts";

const corsHeaders = securityHeaders;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    );
    const {
      data: { user },
    } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    // Verify pro role
    const { data: profile } = await supabase
      .from("users")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profile?.role !== "pro") {
      return jsonResponse({ error: "pro_only" }, 403);
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const priceId = Deno.env.get("STRIPE_PRO_PREMIUM_PRICE_ID");
    if (!priceId) {
      return jsonResponse({ error: "price_not_configured" }, 500);
    }

    // Create Stripe Checkout session for subscription (29 CAD/month)
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${Deno.env.get("APP_URL") ?? "spotbook://"}subscription-success`,
      cancel_url: `${Deno.env.get("APP_URL") ?? "spotbook://"}subscription-cancel`,
      subscription_data: {
        metadata: { proId: user.id },
      },
      metadata: { proId: user.id },
    });

    return new Response(
      JSON.stringify({ url: session.url, sessionId: session.id }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("create-pro-subscription error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
