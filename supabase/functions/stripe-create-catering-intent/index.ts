import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import {
  getClientIp,
  isValidAmount,
  isValidUuid,
  jsonResponse,
  securityHeaders,
} from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
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

    const { submissionId } = await req.json();
    if (!submissionId || !isValidUuid(String(submissionId))) {
      return jsonResponse(
        { error: "submissionId must be a valid UUID" },
        400
      );
    }

    // Fetch submission with pro's Stripe account
    const { data: submission, error: sErr } = await supabase
      .from("catering_submissions")
      .select("*, profiles_pro(stripe_account_id, commission_rate)")
      .eq("id", submissionId)
      .single();

    if (sErr || !submission) {
      return jsonResponse({ error: "submission_not_found" }, 404);
    }

    // Verify client ownership
    if (submission.client_id !== user.id) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    // Only approved submissions can be paid
    if (submission.status !== "approved") {
      return jsonResponse({ error: "submission_not_approved" }, 400);
    }

    // Validate deposit amount
    const depositAmount = Number(submission.deposit_amount);
    if (!isValidAmount(depositAmount)) {
      return jsonResponse(
        { error: "deposit_amount must be > 0 and < 99999" },
        400
      );
    }

    // Rate limit
    const fingerprint = `${user.id}:${submission.id}:${getClientIp(req)}`;
    const rateLimitResp = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/rate-limiter`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          type: "payment",
          cardFingerprint: fingerprint,
        }),
      }
    );
    if (rateLimitResp.status === 429) {
      const data = await rateLimitResp.json();
      return jsonResponse({ error: data.error }, 429);
    }

    // Check for existing deposit record with a PaymentIntent
    const { data: existingDeposit } = await supabase
      .from("catering_deposits")
      .select("stripe_payment_id")
      .eq("submission_id", submissionId)
      .eq("status", "pending")
      .maybeSingle();

    if (existingDeposit?.stripe_payment_id) {
      const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
        apiVersion: "2023-10-16",
      });
      const existing = await stripe.paymentIntents.retrieve(
        existingDeposit.stripe_payment_id
      );
      return new Response(
        JSON.stringify({ clientSecret: existing.client_secret }),
        {
          headers: {
            ...securityHeaders,
            "Content-Type": "application/json",
          },
        }
      );
    }

    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    const depositCents = Math.round(depositAmount * 100);
    const pro = submission.profiles_pro;
    const commissionRate = pro?.commission_rate ?? 0.18;
    const applicationFee = Math.round(depositCents * commissionRate);

    const params: Record<string, unknown> = {
      amount: depositCents,
      currency: "cad",
      automatic_payment_methods: { enabled: true },
      metadata: {
        submissionId: submission.id,
        clientId: user.id,
        proId: submission.pro_id,
        type: "catering_deposit",
      },
    };

    if (pro?.stripe_account_id) {
      params.transfer_data = { destination: pro.stripe_account_id };
      params.application_fee_amount = applicationFee;
    }

    const paymentIntent = await stripe.paymentIntents.create(
      params as Stripe.PaymentIntentCreateParams,
      { idempotencyKey: `catering-${submissionId}-deposit-${user.id}` }
    );

    // Insert catering_deposits row
    await supabase.from("catering_deposits").insert({
      submission_id: submissionId,
      amount: depositAmount,
      stripe_payment_id: paymentIntent.id,
      status: "pending",
    });

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      {
        headers: {
          ...securityHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error) {
    console.error("stripe-create-catering-intent error:", error);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
