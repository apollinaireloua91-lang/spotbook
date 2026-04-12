import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  checkRateLimit,
  getClientIp,
  isValidEmail,
  jsonResponse,
  securityHeaders,
} from "../_shared/security.ts";

const VALID_TYPES = ["login", "signup", "otp", "payment", "upload", "booking"];

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
  }

  try {
    const body = await req.json();
    // Accept both naming conventions: type/email OR scope/identifier
    const type = body.type ?? body.scope;
    const email = body.email ?? body.identifier;
    const { cardFingerprint } = body;

    if (!type || !VALID_TYPES.includes(type)) {
      return jsonResponse(
        { error: `type must be one of ${VALID_TYPES.join("|")}` },
        400
      );
    }

    let key = "";
    if (type === "login" || type === "signup") {
      key = getClientIp(req);
    } else if (type === "otp") {
      if (!email || !isValidEmail(String(email))) {
        return jsonResponse({ error: "email format is invalid" }, 400);
      }
      key = String(email).toLowerCase();
    } else {
      if (!cardFingerprint || String(cardFingerprint).length < 4) {
        return jsonResponse(
          { error: "cardFingerprint is required for payment" },
          400
        );
      }
      key = String(cardFingerprint);
    }

    const result = await checkRateLimit({
      scope: type as "login" | "signup" | "otp" | "payment" | "upload" | "booking",
      key,
    });

    if (!result.allowed) {
      return jsonResponse(
        {
          error: `Trop de tentatives. Réessaie dans ${result.retryInMinutes} minutes.`,
          message: `Trop de tentatives. Réessaie dans ${result.retryInMinutes} minutes.`,
        },
        429
      );
    }

    return jsonResponse({
      success: true,
      remaining: result.remaining,
    });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : String(error ?? "unknown_error");
    console.error("[rate-limiter]", message, error);
    return jsonResponse({ error: message }, 400);
  }
});
