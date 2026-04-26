import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  isValidEmail,
  jsonResponse,
  sanitizeText,
  securityHeadersFor,
} from "../_shared/security.ts";
import { sendResendEmail } from "../_shared/send_resend_email.ts";

// ─────────────────────────────────────────────────────────────────────
// accept-soumission — Client accepts a Pro's quote.
// Auth: anonymous (share_token is the bearer credential).
// Flow: validate token → check status is sent/viewed → flip to 'accepted'
//       → notify Pro by email (template `soumission-accepte-pro`).
//
// Why share_token instead of JWT:
//   The catering quote flow targets BOTH registered clients and prospects
//   who only got the email link. Forcing JWT would break the prospect path
//   that's the whole point of the soumission feature. The token has 128
//   bits of entropy (16 random bytes hex from gen_random_bytes) and the
//   `soumissions_share_token_select` RLS policy already trusts it for
//   reads; we extend that trust to the accept transition here.
// ─────────────────────────────────────────────────────────────────────

const APP_URL = "https://getspotbook.app";

function fmtMoney(cents: number): string {
  const val = (cents / 100).toFixed(2).replace(".", ",");
  return `${val} $`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    const body = await req.json().catch(() => ({}));
    const shareToken = String(body?.shareToken ?? "").trim();
    if (!shareToken || shareToken.length < 16) {
      return jsonResponse({ error: "share_token_required" }, 400, undefined, req);
    }

    const service = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // ── 1. Load soumission by share_token ──
    const { data: soum, error: fetchErr } = await service
      .from("soumissions")
      .select(
        "id, pro_id, title, client_name, client_email, total_cents, valid_until, status",
      )
      .eq("share_token", shareToken)
      .maybeSingle();

    if (fetchErr || !soum) {
      return jsonResponse({ error: "soumission_not_found" }, 404, undefined, req);
    }

    // ── 2. Validate state transition ──
    // Idempotent: if already accepted, return success without re-sending email.
    if (soum.status === "accepted") {
      return jsonResponse(
        { success: true, status: "accepted", already: true },
        200,
        undefined,
        req,
      );
    }
    if (soum.status !== "sent" && soum.status !== "viewed") {
      return jsonResponse(
        { error: "invalid_status", current: soum.status },
        409,
        undefined,
        req,
      );
    }

    // ── 3. Check expiry ──
    if (soum.valid_until) {
      const validUntilDate = new Date(soum.valid_until as string);
      if (validUntilDate.getTime() < Date.now()) {
        return jsonResponse({ error: "soumission_expired" }, 410, undefined, req);
      }
    }

    // ── 4. Flip status to 'accepted' ──
    const { error: updErr } = await service
      .from("soumissions")
      .update({ status: "accepted" })
      .eq("id", soum.id);

    if (updErr) {
      console.error("[accept-soumission] status update error:", updErr);
      return jsonResponse({ error: "update_failed" }, 500, undefined, req);
    }

    // ── 5. Fetch Pro email + name to notify ──
    const { data: proUser } = await service
      .from("users")
      .select("email, full_name, display_name")
      .eq("id", soum.pro_id)
      .maybeSingle();

    const proEmail = proUser?.email as string | undefined;

    if (proEmail && isValidEmail(proEmail)) {
      const proName = proUser?.display_name ||
        proUser?.full_name ||
        "Pro Spotbook";
      const totalCents = (soum.total_cents as number) ?? 0;
      const dashboardUrl = `${APP_URL}/pro/soumissions/${soum.id}`;

      const result = await sendResendEmail({
        event: "soumission_accepte_pro",
        to: proEmail,
        variables: {
          pro_name: proName,
          client_name: sanitizeText(String(soum.client_name ?? "Le client")),
          title: soum.title,
          total_cents: totalCents,
          total_formatted: fmtMoney(totalCents),
          dashboard_url: dashboardUrl,
        },
      });

      if (!result.ok) {
        // Email failure is non-fatal — status is already updated.
        // Pro can still see the acceptance in their dashboard.
        console.warn(
          `[accept-soumission] email dispatch failed soumission=${soum.id} mode=${result.mode} error=${result.error ?? "?"}`,
        );
      }
    } else {
      console.warn(
        `[accept-soumission] pro email missing for soumission=${soum.id} pro=${soum.pro_id}`,
      );
    }

    return jsonResponse(
      { success: true, status: "accepted" },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("[accept-soumission] error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
