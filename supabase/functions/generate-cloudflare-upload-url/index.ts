import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  assertVideoMime,
  checkRateLimit,
  getClientIp,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

/** Durée max alignée avec le picker Flutter (120 s = 2 min). */
const MAX_DURATION_SECONDS = 120;
/** Taille max fichier (bytes) — marge sous la limite Stream habituelle. */
const MAX_FILE_BYTES = 500 * 1024 * 1024;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: securityHeadersFor(req) });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405, undefined, req);
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

    // Server-side options: no session persistence (no localStorage in Deno)
    const serverOpts = {
      auth: { autoRefreshToken: false, persistSession: false },
    };

    const supabaseForJwt = createClient(supabaseUrl, supabaseAnon, serverOpts);
    const {
      data: { user },
      error: jwtError,
    } = await supabaseForJwt.auth.getUser(token);

    if (jwtError || !user) {
      console.error(
        "[generate-cloudflare-upload-url] auth.getUser failed",
        jwtError?.message ?? "no user",
        jwtError?.status,
      );
      return jsonResponse({ error: "Not authenticated" }, 401, undefined, req);
    }

    // Use service role key for server-side checks — bypasses RLS.
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, serverOpts);

    // Primary check: profiles_pro existence
    const { data: profile, error: profileErr } = await supabaseAdmin
      .from("profiles_pro")
      .select("id")
      .eq("id", user.id)
      .maybeSingle();

    if (profileErr || !profile) {
      console.error(
        "[generate-cloudflare-upload-url] profiles_pro check failed",
        JSON.stringify({
          userId: user.id,
          profileErr: profileErr?.message ?? profileErr,
          profileData: profile,
          serviceRoleKeySet: !!serviceRoleKey,
          serviceRoleKeyLength: serviceRoleKey?.length ?? 0,
        }),
      );

      // Fallback: check users.role directly
      const { data: userRow, error: userErr } = await supabaseAdmin
        .from("users")
        .select("role")
        .eq("id", user.id)
        .maybeSingle();

      console.error(
        "[generate-cloudflare-upload-url] fallback users.role check",
        JSON.stringify({
          userId: user.id,
          userRole: userRow?.role,
          userErr: userErr?.message ?? userErr,
        }),
      );

      if (userErr || userRow?.role !== "pro") {
        return jsonResponse(
          { error: "Only provider accounts can request upload URLs" },
          403,
          undefined,
          req,
        );
      }
    }

    let body: Record<string, unknown> = {};
    const raw = await req.text();
    if (raw.trim()) {
      try {
        body = JSON.parse(raw) as Record<string, unknown>;
      } catch {
        return jsonResponse({ error: "Invalid JSON body" }, 400, undefined, req);
      }
    }

    const mimeType = String(body.mimeType ?? "").trim();
    if (mimeType && !assertVideoMime(mimeType)) {
      return jsonResponse(
        {
          error: "Unsupported video type",
          field: "mimeType",
          allowed: "video/mp4, video/quicktime, video/x-m4v, …",
        },
        400,
        undefined,
        req,
      );
    }

    const fileSizeBytes = body.fileSizeBytes;
    if (fileSizeBytes != null) {
      const n = Number(fileSizeBytes);
      if (!Number.isFinite(n) || n < 1 || n > MAX_FILE_BYTES) {
        return jsonResponse(
          {
            error: "Invalid or excessive file size",
            field: "fileSizeBytes",
            maxBytes: MAX_FILE_BYTES,
          },
          400,
          undefined,
          req,
        );
      }
    }

    const ip = getClientIp(req);
    const rateKey = `${user.id}:${ip}`;
    const rl = await checkRateLimit({ scope: "upload", key: rateKey });
    if (!rl.allowed) {
      return jsonResponse(
        {
          error: "Too many upload requests",
          retryInMinutes: rl.retryInMinutes,
        },
        429,
        undefined,
        req,
      );
    }

    const cloudflareToken =
      Deno.env.get("CLOUDFLARE_STREAM_API_TOKEN") ??
      Deno.env.get("CLOUDFLARE_API_TOKEN");
    const cloudflareAccountId = Deno.env.get("CLOUDFLARE_ACCOUNT_ID");

    if (!cloudflareToken || !cloudflareAccountId) {
      return jsonResponse({ error: "Cloudflare secrets missing" }, 500, undefined, req);
    }

    const response = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${cloudflareAccountId}/stream/direct_upload`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${cloudflareToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          maxDurationSeconds: MAX_DURATION_SECONDS,
          requireSignedURLs: false,
          meta: {
            uploaded_by: user.id,
            source: "spotbook",
            moderation: "none",
          },
        }),
      },
    );

    const data = await response.json();

    if (!response.ok) {
      return jsonResponse(
        { error: "Cloudflare upload URL generation failed", details: data },
        500,
        undefined,
        req,
      );
    }

    const bodyCf = data as { success?: boolean; result?: Record<string, unknown> };
    if (bodyCf.success === false) {
      return jsonResponse(
        { error: "Cloudflare upload URL generation failed", details: data },
        500,
        undefined,
        req,
      );
    }

    const result = bodyCf.result;
    const meta =
      result && typeof result === "object"
        ? {
          uid: result.uid,
          expiresAt: result.expiresAt ?? result.expires,
          maxDurationSeconds: MAX_DURATION_SECONDS,
        }
        : {};

    return jsonResponse(
      { ...data, spotbook: meta },
      200,
      undefined,
      req,
    );
  } catch (error) {
    console.error("generate-cloudflare-upload-url error:", error);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
