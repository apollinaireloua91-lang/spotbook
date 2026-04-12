import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  assertServiceRoleOnly,
  isValidEmail,
  jsonResponse,
  sanitizeText,
  securityHeadersFor,
} from "../_shared/security.ts";
import { buildEmail } from "../_shared/email_templates.ts";

const FROM = "Spotbook <noreply@getspotbook.app>";

const VALID_TYPES = [
  "booking_confirmed",
  "booking_cancelled",
  "payment_receipt",
  "ticket_purchased",
  "booking_reminder",
  "welcome",
  "review_request",
] as const;

type EmailType = (typeof VALID_TYPES)[number];

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }

  try {
    // Internal-only: service role required
    const forbidden = assertServiceRoleOnly(req);
    if (forbidden) return forbidden;

    const body = await req.json();
    const { type, to, userId, data } = body as {
      type: string;
      to?: string;
      userId?: string;
      data: Record<string, unknown>;
    };

    // Validate type
    if (!type || !(VALID_TYPES as readonly string[]).includes(type)) {
      return jsonResponse(
        { error: `type must be one of: ${VALID_TYPES.join(", ")}` },
        400,
        undefined,
        req,
      );
    }

    if (!data || typeof data !== "object") {
      return jsonResponse({ error: "data must be an object" }, 400, undefined, req);
    }

    // Resolve recipient email: accept `to` directly or look up via `userId`
    let recipientEmail = to;

    if (!recipientEmail && userId) {
      const supabase = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      );
      const { data: userData, error } = await supabase.auth.admin.getUserById(userId);
      if (error || !userData?.user?.email) {
        return jsonResponse({ error: "user_email_not_found" }, 404, undefined, req);
      }
      recipientEmail = userData.user.email;
    }

    if (!recipientEmail || !isValidEmail(String(recipientEmail))) {
      return jsonResponse(
        { error: "valid email required (to or userId)" },
        400,
        undefined,
        req,
      );
    }

    // Sanitize all string values in data
    const sanitizedData: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(data)) {
      sanitizedData[key] = typeof value === "string" ? sanitizeText(value) : value;
    }

    // Build email HTML from templates
    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (!resendKey) {
      console.error("RESEND_API_KEY is not set");
      return jsonResponse({ error: "email_service_unavailable" }, 503, undefined, req);
    }

    const { subject, html } = buildEmail(type, sanitizedData);

    // Send via Resend REST API
    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM,
        to: [recipientEmail],
        subject,
        html,
      }),
    });

    if (!resendRes.ok) {
      const errBody = await resendRes.text();
      console.error("Resend API error:", resendRes.status, errBody);
      return jsonResponse(
        { error: "email_send_failed", detail: resendRes.status },
        502,
        undefined,
        req,
      );
    }

    const resendData = await resendRes.json();

    return jsonResponse(
      { success: true, email_id: resendData.id, type },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("send-email error:", error);
    return jsonResponse({ error: (error as Error).message }, 500, undefined, req);
  }
});
