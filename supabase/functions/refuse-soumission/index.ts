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
// refuse-soumission — Client declines a Pro's quote.
// Auth: anonymous via share_token (same rationale as accept-soumission).
// Flow: validate token → check status is sent/viewed → flip to 'refused'
//       → notify Pro by email (template `soumission-refuse-pro`).
//
// The optional `reason` field is forwarded to the Resend template as the
// `reason` variable — Apollinaire can choose to surface it in the email
// or ignore it via the dashboard. Sanitized (HTML stripped) to avoid
// reflected-content abuse via the Pro's mailbox.
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
    // Cap at 500 chars to avoid bloated payloads to Resend.
    const reasonRaw = String(body?.reason ?? "").trim().slice(0, 500);
    const reason = reasonRaw ? sanitizeText(reasonRaw) : "";

    const service = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // ── 1. Load soumission by share_token ──
    const { data: soum, error: fetchErr } = await service
      .from("soumissions")
      .select(
        "id, pro_id, title, client_name, total_cents, status",
      )
      .eq("share_token", shareToken)
      .maybeSingle();

    if (fetchErr || !soum) {
      return jsonResponse({ error: "soumission_not_found" }, 404, undefined, req);
    }

    // ── 2. Idempotent: already refused → return success ──
    if (soum.status === "refused") {
      return jsonResponse(
        { success: true, status: "refused", already: true },
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

    // ── 3. Flip status to 'refused' ──
    const { error: updErr } = await service
      .from("soumissions")
      .update({ status: "refused" })
      .eq("id", soum.id);

    if (updErr) {
      console.error("[refuse-soumission] status update error:", updErr);
      return jsonResponse({ error: "update_failed" }, 500, undefined, req);
    }

    // ── 4. Notify Pro ──
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
        event: "soumission_refuse_pro",
        to: proEmail,
        variables: {
          pro_name: proName,
          client_name: sanitizeText(String(soum.client_name ?? "Le client")),
          title: soum.title,
          total_cents: totalCents,
          total_formatted: fmtMoney(totalCents),
          reason,
          dashboard_url: dashboardUrl,
        },
      });

      if (!result.ok) {
        console.warn(
          `[refuse-soumission] email dispatch failed soumission=${soum.id} mode=${result.mode} error=${result.error ?? "?"}`,
        );
      }
    }

    return jsonResponse(
      { success: true, status: "refused" },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("[refuse-soumission] error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
