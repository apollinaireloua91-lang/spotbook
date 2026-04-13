import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
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
      const projectId = Deno.env.get("FCM_PROJECT_ID") ?? "";
      const serverKey = Deno.env.get("FCM_SERVER_KEY") ?? "";

      const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

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
            notification: { channel_id: "spotbook_default" },
          },
          apns: {
            payload: { aps: { sound: "default", badge: 1 } },
          },
        },
      };

      try {
        const fcmRes = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${serverKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(message),
        });

        pushSent = fcmRes.ok;
      } catch {
        pushSent = false;
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
