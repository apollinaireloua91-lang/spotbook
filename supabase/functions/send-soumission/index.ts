import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  isValidEmail,
  jsonResponse,
  sanitizeText,
  securityHeadersFor,
} from "../_shared/security.ts";

// ─────────────────────────────────────────────────────────────────────
// send-soumission — Pro-initiated quote delivery.
// Auth: JWT of the Pro who owns the soumission.
// Flow: verify ownership → build HTML email → send via Resend →
//       update soumission.status (draft → sent). The client receives a
//       link to view the quote via its share_token.
// ─────────────────────────────────────────────────────────────────────

const FROM = "Spotbook <noreply@getspotbook.app>";
const APP_URL = "https://getspotbook.app";

function fmtMoney(cents: number): string {
  const val = (cents / 100).toFixed(2).replace(".", ",");
  return `${val} $`;
}

function buildSoumissionEmail(args: {
  clientName: string | null;
  proName: string;
  title: string;
  totalCents: number;
  validUntil: string | null;
  shareToken: string;
}): { subject: string; html: string } {
  const greeting = args.clientName
    ? `Bonjour ${sanitizeText(args.clientName)},`
    : "Bonjour,";
  const validity = args.validUntil
    ? `<p style="margin:12px 0 0;color:#9090AA;font-size:13px;">Valide jusqu'au ${
      sanitizeText(args.validUntil)
    }.</p>`
    : "";
  const link = `${APP_URL}/soumission/${args.shareToken}`;

  const html = `<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"/></head>
<body style="margin:0;padding:0;background:#0D0D14;font-family:-apple-system,'DM Sans',sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#0D0D14;">
    <tr><td align="center" style="padding:40px 16px;">
      <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#1E1E2E;border-radius:16px;overflow:hidden;">
        <tr><td style="padding:32px 40px 0;text-align:center;">
          <span style="font-size:20px;font-weight:700;color:#FFFFFF;">Spotbook</span>
        </td></tr>
        <tr><td style="padding:32px 40px 40px;">
          <h1 style="margin:0 0 16px;font-size:22px;color:#FFFFFF;font-weight:700;">Nouvelle soumission</h1>
          <p style="margin:0 0 16px;color:#E0E0F0;font-size:15px;line-height:22px;">${greeting}</p>
          <p style="margin:0 0 20px;color:#E0E0F0;font-size:15px;line-height:22px;">
            ${
    sanitizeText(args.proName)
  } vous a envoy&eacute; une soumission&nbsp;:
          </p>
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#2A2A3E;border-radius:12px;margin:8px 0 24px;">
            <tr><td style="padding:20px;">
              <p style="margin:0 0 8px;font-size:13px;color:#9090AA;text-transform:uppercase;letter-spacing:0.5px;">Objet</p>
              <p style="margin:0 0 16px;font-size:16px;color:#FFFFFF;font-weight:600;">${
    sanitizeText(args.title)
  }</p>
              <p style="margin:0 0 8px;font-size:13px;color:#9090AA;text-transform:uppercase;letter-spacing:0.5px;">Total TTC</p>
              <p style="margin:0;font-size:22px;color:#FFFFFF;font-weight:700;">${
    fmtMoney(args.totalCents)
  }</p>
              ${validity}
            </td></tr>
          </table>
          <table role="presentation" cellpadding="0" cellspacing="0" style="margin:8px auto 0;">
            <tr><td align="center" style="background:#6C3EF4;border-radius:12px;">
              <a href="${link}" style="display:inline-block;padding:14px 28px;color:#FFFFFF;font-weight:600;text-decoration:none;font-size:15px;">
                Voir la soumission
              </a>
            </td></tr>
          </table>
          <p style="margin:28px 0 0;color:#9090AA;font-size:12px;line-height:18px;text-align:center;">
            Ou copiez ce lien&nbsp;: <br/>
            <a href="${link}" style="color:#8B63FF;word-break:break-all;">${link}</a>
          </p>
        </td></tr>
      </table>
      <p style="margin:24px 0 0;color:#9090AA;font-size:12px;">&copy; 2026 Spotbook Inc.</p>
    </td></tr>
  </table>
</body></html>`;

  return {
    subject: `Soumission : ${sanitizeText(args.title)}`,
    html,
  };
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
      return jsonResponse({ error: "soumission_not_found" }, 404, undefined, req);
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

    // ── 5. Build + send email ──
    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (!resendKey) {
      console.error("RESEND_API_KEY not set");
      return jsonResponse(
        { error: "email_service_unavailable" },
        503,
        undefined,
        req,
      );
    }

    const validUntilStr = soum.valid_until
      ? new Date(soum.valid_until as string).toLocaleDateString("fr-CA")
      : null;

    const { subject, html } = buildSoumissionEmail({
      clientName: soum.client_name as string | null,
      proName: String(proName),
      title: soum.title as string,
      totalCents: (soum.total_cents as number) ?? 0,
      validUntil: validUntilStr,
      shareToken: soum.share_token as string,
    });

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM,
        to: [soum.client_email],
        subject,
        html,
      }),
    });

    if (!resendRes.ok) {
      const errBody = await resendRes.text();
      console.error("Resend error:", resendRes.status, errBody);
      return jsonResponse(
        { error: "email_send_failed", detail: resendRes.status },
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
      if (updErr) console.error("status update error:", updErr);
    }

    return jsonResponse({ success: true }, 200, undefined, req);
  } catch (error) {
    console.error("send-soumission error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
