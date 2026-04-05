import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  jsonResponse,
  sanitizeText,
  securityHeadersFor,
} from "../_shared/security.ts";

/** UID Cloudflare Stream (hex 32). */
const CLOUDFLARE_STREAM_UID = /^[a-f0-9]{32}$/i;

const ALLOWED_CATEGORIES = [
  "coiffure",
  "beaute",
  "fitness",
  "photo",
  "musique",
  "cuisine",
  "massage",
  "tatouage",
  "maquillage",
  "mode",
  "danse",
  "art",
  "coaching",
  "autre_service",
];

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: securityHeadersFor(req) });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.trim()) {
      return jsonResponse({ error: "Not authenticated" }, 401, undefined, req);
    }
    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!token) {
      return jsonResponse({ error: "Not authenticated" }, 401, undefined, req);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnon = Deno.env.get("SUPABASE_ANON_KEY")!;

    const supabaseAdmin = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const supabaseForJwt = createClient(supabaseUrl, supabaseAnon);
    const {
      data: { user },
      error: jwtError,
    } = await supabaseForJwt.auth.getUser(token);
    if (jwtError || !user) {
      console.error(
        "[moderate-video] auth.getUser failed",
        jwtError?.message ?? "no user",
        jwtError?.status,
      );
      return jsonResponse({ error: "Not authenticated" }, 401, undefined, req);
    }

    // Verify pro status
    const { data: profile } = await supabaseAdmin
      .from("profiles_pro")
      .select("id, stripe_onboarded, is_top_pro")
      .eq("id", user.id)
      .single();

    if (!profile) {
      return jsonResponse({ error: "Pro profile not found" }, 401, undefined, req);
    }

    // La publication vidéo ne bloque pas sur Stripe : les paiements passent par Connect ailleurs.
    // `stripe_onboarded` peut être renvoyé au client pour afficher un rappel discret si besoin.
    const stripeOnboarded = profile.stripe_onboarded === true;

    const body = await req.json();
    const title = sanitizeText(String(body.title ?? ""));
    const description = sanitizeText(String(body.description ?? ""));
    const category = String(body.category ?? "");
    const duration = body.duration as number | undefined;
    const cloudflare_id = String(body.cloudflare_id ?? "").trim();
    const thumbnail_url = String(body.thumbnail_url ?? "");
    const hashtags = Array.isArray(body.hashtags) ? body.hashtags : [];

    if (!cloudflare_id || !CLOUDFLARE_STREAM_UID.test(cloudflare_id)) {
      return jsonResponse(
        { error: "cloudflare_id invalide (UID Stream attendu)", field: "cloudflare_id" },
        400,
        undefined,
        req,
      );
    }

    // Validate fields
    if (!title || title.length < 5 || title.length > 80) {
      return jsonResponse(
        { error: "Title is required (5-80 characters)", field: "title" },
        400,
        undefined,
        req,
      );
    }

    if (!description || description.length < 20) {
      return jsonResponse(
        { error: "Description is required (minimum 20 characters)", field: "description" },
        400,
        undefined,
        req,
      );
    }

    if (!category || !ALLOWED_CATEGORIES.includes(category)) {
      return jsonResponse(
        {
          error: `Category must be one of: ${ALLOWED_CATEGORIES.join(", ")}`,
          field: "category",
        },
        400,
        undefined,
        req,
      );
    }

    if (duration && duration > 60) {
      return jsonResponse(
        { error: "Video must be 60 seconds or less", field: "duration" },
        400,
        undefined,
        req,
      );
    }

    const customerCode = Deno.env.get("CLOUDFLARE_CUSTOMER_CODE")?.trim() ?? "";
    const resolvedThumbnail = customerCode
      ? `https://customer-${customerCode}.cloudflarestream.com/${cloudflare_id}/thumbnails/thumbnail.jpg`
      : thumbnail_url;

    const durationSeconds =
      typeof duration === "number" && Number.isFinite(duration)
        ? Math.min(60, Math.max(0, Math.round(duration)))
        : undefined;

    const UUID_RE =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    const rawServiceId =
      typeof body.service_id === "string" ? body.service_id : undefined;
    let serviceId: string | null = null;
    if (rawServiceId && typeof rawServiceId === "string") {
      const sid = rawServiceId.trim();
      if (sid && UUID_RE.test(sid)) {
        const { data: svc, error: svcErr } = await supabaseAdmin
          .from("services")
          .select("id")
          .eq("id", sid)
          .eq("pro_id", user.id)
          .maybeSingle();
        if (svcErr) {
          return jsonResponse(
            { error: "Could not validate service", field: "service_id" },
            400,
            undefined,
            req,
          );
        }
        if (svc?.id) serviceId = sid;
        else {
          return jsonResponse(
            { error: "Service not found or not yours", field: "service_id" },
            400,
            undefined,
            req,
          );
        }
      } else if (sid) {
        return jsonResponse(
          { error: "Invalid service_id", field: "service_id" },
          400,
          undefined,
          req,
        );
      }
    }

    const { data: video, error: insertError } = await supabaseAdmin
      .from("videos")
      .insert({
        pro_id: user.id,
        cloudflare_id,
        thumbnail_url: resolvedThumbnail || null,
        title,
        description,
        category,
        hashtags: hashtags || [],
        status: "approved",
        visibility: "public",
        upload_status: "ready",
        duration_seconds: durationSeconds ?? null,
        ...(serviceId ? { service_id: serviceId } : {}),
      })
      .select("id, status, visibility")
      .single();

    if (insertError) {
      return jsonResponse({ error: insertError.message }, 500, undefined, req);
    }

    return jsonResponse(
      {
        videoId: video.id,
        status: video.status,
        visibility: video.visibility,
        stripeOnboarded,
        nextStep:
          "Video published immediately — visible in feed",
      },
      200,
      undefined,
      req,
    );
  } catch (error) {
    return jsonResponse({ error: (error as Error).message }, 500, undefined, req);
  }
});
