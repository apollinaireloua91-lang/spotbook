import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Not authenticated" }), {
        status: 401,
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Not authenticated" }), {
        status: 401,
      });
    }

    // Verify pro status
    const { data: profile } = await supabaseAdmin
      .from("profiles_pro")
      .select("id, stripe_onboarded, is_top_pro")
      .eq("id", user.id)
      .single();

    if (!profile) {
      return new Response(
        JSON.stringify({ error: "Pro profile not found" }),
        { status: 401 }
      );
    }

    if (!profile.stripe_onboarded) {
      return new Response(
        JSON.stringify({
          error: "Stripe Connect must be configured before uploading",
        }),
        { status: 403 }
      );
    }

    const body = await req.json();
    const { title, description, category, duration, cloudflare_id, stream_url, thumbnail_url, hashtags } = body;

    // Validate fields
    if (!title || title.length < 5 || title.length > 80) {
      return new Response(
        JSON.stringify({
          error: "Title is required (5-80 characters)",
          field: "title",
        }),
        { status: 400 }
      );
    }

    if (!description || description.length < 20) {
      return new Response(
        JSON.stringify({
          error: "Description is required (minimum 20 characters)",
          field: "description",
        }),
        { status: 400 }
      );
    }

    if (!category || !ALLOWED_CATEGORIES.includes(category)) {
      return new Response(
        JSON.stringify({
          error: `Category must be one of: ${ALLOWED_CATEGORIES.join(", ")}`,
          field: "category",
        }),
        { status: 400 }
      );
    }

    if (duration && duration > 60) {
      return new Response(
        JSON.stringify({
          error: "Video must be 60 seconds or less",
          field: "duration",
        }),
        { status: 400 }
      );
    }

    const status = profile.is_top_pro ? "approved" : "pending_review";

    const { data: video, error: insertError } = await supabaseAdmin
      .from("videos")
      .insert({
        pro_id: user.id,
        cloudflare_id,
        stream_url,
        thumbnail_url,
        title,
        description,
        category,
        hashtags: hashtags || [],
        status,
      })
      .select("id, status")
      .single();

    if (insertError) {
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 500,
      });
    }

    return new Response(
      JSON.stringify({ videoId: video.id, status: video.status }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
    });
  }
});
