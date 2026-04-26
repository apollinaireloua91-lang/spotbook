import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  isValidEmail,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";
import { sendResendEmail } from "../_shared/send_resend_email.ts";

// ─────────────────────────────────────────────────────────────────────
// send-soumission — Pro-initiated quote delivery.
// Auth: JWT of the Pro who owns the soumission.
// Flow: verify ownership → dispatch via Resend template
//       (`soumission_reue`) → flip status draft → sent.
//
// Email content lives in the Resend dashboard (alias `soumission-reue`),
// so Apollinaire can iterate on copy without redeploying the Edge
// Function. The HTML fallback in `email_templates.ts` is the safety net
// if the template call fails.
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
    // ── 1. Authenticate Pro via JWT ──
    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization") ?? "" },
        },
      },
    );
    const { data: { user } } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    // ── 2. Parse input ──
    const body = await req.json().catch(() => ({}));
    const soumissionId = String(body?.soumissionId ?? "").trim();
    if (!soumissionId) {
      return jsonResponse(
        { error: "soumissionId required" },
        400,
        undefined,
        req,
      );
    }

    // ── 3. Load soumission + verify ownership (service role) ──
    const service = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: soum, error: fetchErr } = await service
      .from("soumissions")
      .select(
        "id, pro_id, title, client_name, client_email, total_cents, share_token, valid_until, status",
      )
      .eq("id", soumissionId)
      .maybeSingle();

    if (fetchErr || !soum) {
      return jsonResponse(
        { error: "soumission_not_found" },
        404,
        undefined,
        req,
      );
    }
    if (soum.pro_id !== user.id) {
      return jsonResponse({ error: "forbidden" }, 403, undefined, req);
    }
    if (!soum.client_email || !isValidEmail(String(soum.client_email))) {
      return jsonResponse(
        { error: "client_email_missing_or_invalid" },
        400,
        undefined,
        req,
      );
    }
    if (!soum.share_token) {
      return jsonResponse(
        { error: "share_token_missing" },
        500,
        undefined,
        req,
      );
    }

    // ── 4. Fetch Pro display name (falls back to business name) ──
    const { data: proUser } = await service
      .from("users")
      .select("full_name, display_name")
      .eq("id", user.id)
      .maybeSingle();
    const { data: proBiz } = await service
      .from("profiles_pro")
      .select("business_name")
      .eq("id", user.id)
      .maybeSingle();

    const proName = proUser?.display_name ||
      proUser?.full_name ||
      proBiz?.business_name ||
      "Votre prestataire";

    // ── 5. Dispatch via Resend template (with HTML fallback) ──
    const validUntilStr = soum.valid_until
      ? new Date(soum.valid_until as string).toLocaleDateString("fr-CA")
      : null;
    const totalCents = (soum.total_cents as number) ?? 0;
    const viewUrl = `${APP_URL}/soumission/${soum.share_token as string}`;

    const result = await sendResendEmail({
      event: "soumission_reue",
      to: String(soum.client_email),
      variables: {
        client_name: soum.client_name ?? "",
        pro_name: proName,
        title: soum.title,
        total_cents: totalCents,
        total_formatted: fmtMoney(totalCents),
        valid_until: validUntilStr ?? "",
        view_url: viewUrl,
        share_token: soum.share_token,
      },
    });

    if (!result.ok) {
      console.error(
        `[send-soumission] dispatch failed event=soumission_reue id=${soumissionId} mode=${result.mode} error=${result.error ?? "?"}`,
      );
      return jsonResponse(
        { error: "email_send_failed", detail: result.error ?? "unknown" },
        502,
        undefined,
        req,
      );
    }

    // ── 6. Flip status draft → sent (only if still draft) ──
    if (soum.status === "draft") {
      const { error: updErr } = await service
        .from("soumissions")
        .update({ status: "sent" })
        .eq("id", soumissionId);
      if (updErr) {
        console.error("[send-soumission] status update error:", updErr);
      }
    }

    return jsonResponse(
      { success: true, mode: result.mode, emailId: result.emailId },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("[send-soumission] error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
