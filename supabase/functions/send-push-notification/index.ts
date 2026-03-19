import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  assertUuid,
  jsonHeaders,
  sanitizeText,
  securityHeaders,
} from "../_shared/security.ts";

interface PushPayload {
  userId: string;
  title: string;
  body: string;
  type: string;
  data?: Record<string, string>;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { userId, title, body, type, data } =
      (await req.json()) as PushPayload;

    if (!userId || !title || !body || !type) {
      return new Response(
        JSON.stringify({ error: "userId, title, body, type required" }),
        {
          headers: jsonHeaders,
          status: 400,
        }
      );
    }
    assertUuid(userId, "userId");
    const safeTitle = sanitizeText(title);
    const safeBody = sanitizeText(body);

    // Check notification preferences
    const { data: prefs } = await supabase
      .from("notification_preferences")
      .select("*")
      .eq("user_id", userId)
      .single();

    if (prefs) {
      const prefKey = `${type}_enabled` as string;
      if (prefs[prefKey] === false) {
        // User disabled this notification type
        // Still insert in history but don't send push
        await supabase.from("notifications").insert({
          user_id: userId,
          title: safeTitle,
          body: safeBody,
          type,
          data: data ?? {},
          is_read: false,
          push_sent: false,
        });

        return new Response(
          JSON.stringify({
            success: true,
            push_sent: false,
            reason: "disabled_by_user",
          }),
          {
            headers: jsonHeaders,
          }
        );
      }
    }

    // Get FCM token
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
          notification: { title: safeTitle, body: safeBody },
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
        // FCM delivery failed — still save notification in history
        pushSent = false;
      }
    }

    // Insert notification in history
    await supabase.from("notifications").insert({
      user_id: userId,
      title: safeTitle,
      body: safeBody,
      type,
      data: data ?? {},
      is_read: false,
      push_sent: pushSent,
    });

    return new Response(
      JSON.stringify({ success: true, push_sent: pushSent }),
      {
        headers: jsonHeaders,
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: jsonHeaders,
      status: 400,
    });
  }
});
