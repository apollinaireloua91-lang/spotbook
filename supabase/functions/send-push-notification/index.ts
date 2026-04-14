import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { encode as base64url } from "https://deno.land/std@0.168.0/encoding/base64url.ts";
import {
  isValidUuid,
  jsonResponse,
  sanitizeText,
  securityHeadersFor,
  timingSafeEqual,
} from "../_shared/security.ts";

interface PushPayload {
  userId: string;
  title: string;
  body: string;
  type: string;
  data?: Record<string, string>;
  /** Obligatoire pour les appels clients (ex. notif « nouvel abonné »). */
  actorId?: string;
}

// ─── FCM v1 OAuth2 ────────────────────────────────────────────────

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

/** Import a PEM-encoded RSA private key for signing JWTs. */
async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

/** Build and sign a Google OAuth2 JWT assertion for FCM. */
async function createSignedJwt(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const enc = new TextEncoder();
  const headerB64 = base64url(enc.encode(JSON.stringify(header)));
  const payloadB64 = base64url(enc.encode(JSON.stringify(payload)));
  const unsigned = `${headerB64}.${payloadB64}`;

  const key = await importPrivateKey(sa.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    enc.encode(unsigned),
  );

  return `${unsigned}.${base64url(new Uint8Array(signature))}`;
}

/** Exchange a signed JWT for a short-lived Google OAuth2 access token. */
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const jwt = await createSignedJwt(sa);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Google OAuth token exchange failed: ${res.status} ${text}`);
  }
  const { access_token } = await res.json();
  return access_token as string;
}

/** Préférences table `notification_preferences` (colonnes legacy + *_enabled). */
function notificationTypeEnabled(
  prefs: Record<string, unknown> | null,
  type: string,
): boolean {
  if (!prefs) return true;
  const explicit = prefs[`${type}_enabled`];
  if (explicit === false) return false;
  if (explicit === true) return true;
  if (type === "message" && prefs.messages === false) return false;
  if ((type === "booking" || type === "ticket") && prefs.bookings === false) {
    return false;
  }
  if (type === "ticket" && prefs.promotions === false) return false;
  return true;
}

function isServiceRoleRequest(req: Request): boolean {
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const auth = req.headers.get("Authorization") ?? "";
  return Boolean(serviceKey && timingSafeEqual(auth, `Bearer ${serviceKey}`));
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const payload = (await req.json()) as PushPayload;
    const { userId, title, body, type, data } = payload;

    if (!userId || !isValidUuid(String(userId))) {
      return jsonResponse({ error: "userId must be a valid UUID" }, 400, undefined, req);
    }
    if (!title || !body || !type) {
      return jsonResponse({ error: "title, body, type required" }, 400, undefined, req);
    }

    if (!isServiceRoleRequest(req)) {
      const authHeader = req.headers.get("Authorization");
      if (!authHeader) {
        return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
      }
      const authClient = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_ANON_KEY") ?? "",
        { global: { headers: { Authorization: authHeader } } },
      );
      const {
        data: { user },
      } = await authClient.auth.getUser();
      if (!user) {
        return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
      }

      if (type !== "social") {
        return jsonResponse({ error: "forbidden" }, 403, undefined, req);
      }
      const actorId = payload.actorId;
      if (!actorId || !isValidUuid(String(actorId)) || actorId !== user.id) {
        return jsonResponse({ error: "forbidden" }, 403, undefined, req);
      }
      if (data?.kind !== "new_follower") {
        return jsonResponse({ error: "forbidden" }, 403, undefined, req);
      }

      const { data: follow } = await supabase
        .from("follows")
        .select("follower_id")
        .eq("follower_id", actorId)
        .eq("following_id", userId)
        .maybeSingle();

      if (!follow) {
        return jsonResponse({ error: "forbidden" }, 403, undefined, req);
      }
    }

    const { data: prefs } = await supabase
      .from("notification_preferences")
      .select("*")
      .eq("user_id", userId)
      .single();

    if (!notificationTypeEnabled(prefs as Record<string, unknown> | null, type)) {
      return jsonResponse(
        {
          success: true,
          push_sent: false,
          reason: "disabled_by_user",
        },
        200,
        undefined,
        req,
      );
    }

    const { data: user } = await supabase
      .from("users")
      .select("fcm_token")
      .eq("id", userId)
      .single();

    let pushSent = false;

    if (user?.fcm_token) {
      const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "";
      if (!saJson) {
        console.error("FIREBASE_SERVICE_ACCOUNT secret is not set");
      } else {
        try {
          const sa: ServiceAccount = JSON.parse(saJson);
          const accessToken = await getAccessToken(sa);
          const fcmUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

          const message = {
            message: {
              token: user.fcm_token,
              notification: { title, body },
              data: {
                type,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                ...(data ?? {}),
              },
              android: {
                priority: "high" as const,
                notification: { channel_id: "spotbook_notifications" },
              },
              apns: {
                payload: { aps: { sound: "default", badge: 1 } },
              },
            },
          };

          const fcmRes = await fetch(fcmUrl, {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(message),
          });

          if (!fcmRes.ok) {
            const errBody = await fcmRes.text();
            console.error(`FCM v1 error ${fcmRes.status}: ${errBody}`);
          }
          pushSent = fcmRes.ok;
        } catch (fcmErr) {
          console.error("FCM send failed:", fcmErr);
          pushSent = false;
        }
      }
    }

    await supabase.from("notifications").insert({
      user_id: userId,
      title: sanitizeText(title),
      body: sanitizeText(body),
      type,
      data: data ?? {},
      is_read: false,
      push_sent: pushSent,
    });

    return jsonResponse({ success: true, push_sent: pushSent }, 200, undefined, req);
  } catch (error) {
    console.error("send-push-notification error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
