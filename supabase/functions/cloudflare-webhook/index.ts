import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { jsonResponse, securityHeadersFor } from "../_shared/security.ts";

/**
 * Cloudflare Stream Webhook handler.
 *
 * Cloudflare sends a POST when a video finishes encoding (`ready`) or fails (`error`).
 * We update the video row in Supabase and notify the Pro.
 *
 * Configure in Cloudflare Dashboard:
 *   Stream → Notifications → Webhooks
 *   URL: https://<project>.supabase.co/functions/v1/cloudflare-webhook
 *   Events: stream.ready, stream.error
 *   Secret: store as CLOUDFLARE_WEBHOOK_SECRET in Edge Function env
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: securityHeadersFor(req) });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405, undefined, req);
  }

  try {
    // ── Verify webhook signature ──
    // Cloudflare sends a signing secret in the webhook-secret header.
    const webhookSecret = Deno.env.get("CLOUDFLARE_WEBHOOK_SECRET")?.trim();
    if (webhookSecret) {
      const receivedSecret = req.headers.get("webhook-secret")?.trim();
      if (receivedSecret !== webhookSecret) {
        console.error("[cloudflare-webhook] Invalid webhook secret");
        return jsonResponse({ error: "Forbidden" }, 403, undefined, req);
      }
    }

    const body = await req.json();

    // Cloudflare webhook payload:
    // For stream.ready: { uid, readyToStream, status: { state: "ready" }, duration, thumbnail, ... }
    // For stream.error: { uid, status: { state: "error", errorReasonCode, errorReasonText }, ... }
    const uid = body.uid as string | undefined;
    const status = body.status as
      | { state: string; errorReasonCode?: string; errorReasonText?: string }
      | undefined;

    if (!uid) {
      return jsonResponse(
        { error: "Missing uid in webhook payload" },
        400,
        undefined,
        req
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const state = status?.state ?? (body.readyToStream ? "ready" : "unknown");

    if (state === "ready") {
      // ── Video ready — update status ──
      const durationSeconds =
        typeof body.duration === "number" && Number.isFinite(body.duration)
          ? Math.round(body.duration)
          : undefined;

      // Build playback URLs from Cloudflare response
      const customerCode =
        Deno.env.get("CLOUDFLARE_CUSTOMER_CODE")?.trim() ?? "";
      const playbackHls = body.playback?.hls
        ?? (customerCode
          ? `https://customer-${customerCode}.cloudflarestream.com/${uid}/manifest/video.m3u8`
          : undefined);
      const thumbnailUrl = body.thumbnail
        ?? (customerCode
          ? `https://customer-${customerCode}.cloudflarestream.com/${uid}/thumbnails/thumbnail.jpg`
          : undefined);

      const updatePayload: Record<string, unknown> = {
        upload_status: "ready",
        status: "approved",
        visibility: "public",
      };
      if (durationSeconds !== undefined) {
        updatePayload.duration_seconds = durationSeconds;
      }
      if (playbackHls) {
        updatePayload.cloudflare_playback_url = playbackHls;
        updatePayload.stream_url = playbackHls;
      }
      if (thumbnailUrl) {
        updatePayload.cloudflare_thumbnail_url = thumbnailUrl;
        updatePayload.thumbnail_url = thumbnailUrl;
      }

      const { error: updateError } = await supabase
        .from("videos")
        .update(updatePayload)
        .eq("cloudflare_id", uid);

      if (updateError) {
        console.error(
          "[cloudflare-webhook] update failed for ready state",
          updateError.message
        );
        return jsonResponse(
          { error: updateError.message },
          500,
          undefined,
          req
        );
      }

      // ── Notify the Pro ──
      const { data: video } = await supabase
        .from("videos")
        .select("pro_id, title")
        .eq("cloudflare_id", uid)
        .maybeSingle();

      if (video?.pro_id) {
        await supabase.from("notifications").insert({
          user_id: video.pro_id,
          type: "video_ready",
          title: "Vidéo publiée !",
          body: `Votre vidéo "${video.title ?? ""}" est maintenant en ligne.`,
          data: { video_uid: uid },
        });
      }

      console.log(`[cloudflare-webhook] Video ${uid} → ready & approved`);
    } else if (state === "error") {
      // ── Video encoding failed ──
      const errorReason =
        status?.errorReasonText ?? status?.errorReasonCode ?? "unknown";

      const { error: updateError } = await supabase
        .from("videos")
        .update({ upload_status: "error", status: "rejected" })
        .eq("cloudflare_id", uid);

      if (updateError) {
        console.error(
          "[cloudflare-webhook] update failed for error state",
          updateError.message
        );
      }

      // Notify the Pro of the failure
      const { data: video } = await supabase
        .from("videos")
        .select("pro_id, title")
        .eq("cloudflare_id", uid)
        .maybeSingle();

      if (video?.pro_id) {
        await supabase.from("notifications").insert({
          user_id: video.pro_id,
          type: "video_error",
          title: "Erreur de traitement",
          body: `Votre vidéo "${video.title ?? ""}" n'a pas pu être traitée. Veuillez réessayer.`,
          data: { video_uid: uid, error: errorReason },
        });
      }

      console.error(
        `[cloudflare-webhook] Video ${uid} → error: ${errorReason}`
      );
    } else {
      console.log(
        `[cloudflare-webhook] Ignored event for ${uid}, state: ${state}`
      );
    }

    return jsonResponse({ ok: true }, 200, undefined, req);
  } catch (error) {
    console.error("[cloudflare-webhook] Unhandled error", error);
    return jsonResponse(
      { error: (error as Error).message },
      500,
      undefined,
      req
    );
  }
});
