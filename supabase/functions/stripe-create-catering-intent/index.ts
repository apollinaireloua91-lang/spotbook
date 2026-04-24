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
import { currencyForCountry } from "../_shared/currency.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
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

    // Fetch submission with pro's Stripe account + country (devise)
    const { data: submission, error: sErr } = await supabase
      .from("catering_submissions")
      .select("*, profiles_pro(stripe_account_id, commission_rate, country)")
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

    const totalPriceCents = Math.round((submission.total_amount ?? 0) * 100);
    const depositCents = Math.round(depositAmount * 100);
    const serviceFeeCents = Math.round((submission.service_fee ?? 2.50) * 100);
    const chargeAmount = depositCents + serviceFeeCents;
    const pro = submission.profiles_pro;
    const commissionRate = pro?.commission_rate ?? 0.18;
    // Commission on FULL price + service fee — ALL goes to Spotbook
    const fullCommission = Math.round(totalPriceCents * commissionRate);
    const applicationFee = fullCommission + serviceFeeCents;

    // Devise basée sur le pays du pro — pas de fallback "cad" en dur
    const cateringCurrency = currencyForCountry(
      pro?.country as string | null | undefined,
    );
    const params: Record<string, unknown> = {
      amount: chargeAmount,
      currency: cateringCurrency,
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

    // Insert catering_deposits row. Si l'INSERT échoue, on cancel le PI
    // pour éviter un charge orphelin côté Stripe.
    const { error: insertErr } = await supabase
      .from("catering_deposits")
      .insert({
        submission_id: submissionId,
        amount: depositAmount,
        stripe_payment_id: paymentIntent.id,
        status: "pending",
      });

    if (insertErr) {
      console.error(
        JSON.stringify({
          level: "error",
          code: "ORPHAN_CATERING_DEPOSIT",
          message:
            "Stripe PI created but catering_deposits insert failed",
          submissionId,
          paymentIntentId: paymentIntent.id,
          dbError: insertErr.message,
        }),
      );
      try {
        await stripe.paymentIntents.cancel(paymentIntent.id, {
          cancellation_reason: "abandoned",
        });
      } catch (cancelErr) {
        console.error(
          JSON.stringify({
            level: "error",
            code: "ORPHAN_CATERING_CANCEL_FAILED",
            paymentIntentId: paymentIntent.id,
            error: (cancelErr as Error).message,
          }),
        );
      }
      return jsonResponse({ error: "internal_error" }, 500);
    }

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
