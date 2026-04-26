import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// stripe-connect-reminder — Cron-only Edge Function (verify_jwt=false on gateway).
// Authenticates via Vault-stored shared secret (cron ↔ function pact).
//
// Cadence rules:
//   • Pro account >= 7 days old, has stripe_account_id, NOT stripe_onboarded
//   • First reminder when stripe_connect_reminder_sent_at IS NULL
//   • Re-pings every 7 days, capped at MAX_REMINDERS=4 total

const APP_URL = "https://getspotbook.app";
const REMINDER_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;
const MAX_REMINDERS = 4;
const BATCH_SIZE = 50;
const RESEND_TEMPLATE_ID = "53874409-39e8-4bb2-98ac-93ec34a93fea"; // rappel-stripe-connect
const RESEND_FROM = "Spotbook <noreply@getspotbook.app>";

// ── Helpers (inlined from _shared/) ──

function securityHeadersFor(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "https://getspotbook.app",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
  };
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...securityHeadersFor(), "Content-Type": "application/json" },
  });
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}

function isValidEmail(v: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

let _cachedCronSecret: string | null = null;
async function assertCronAuth(req: Request): Promise<Response | null> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!_cachedCronSecret) {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!url || !key) return jsonResponse({ error: "server_misconfigured" }, 500);
    const c = createClient(url, key);
    const { data, error } = await c.rpc("get_cron_shared_secret");
    if (error || typeof data !== "string" || !data.length) {
      console.error("[stripe-connect-reminder] vault read failed:", error);
      return jsonResponse({ error: "server_misconfigured" }, 500);
    }
    _cachedCronSecret = data;
  }
  if (!timingSafeEqual(auth, `Bearer ${_cachedCronSecret}`)) {
    return jsonResponse({ error: "forbidden" }, 403);
  }
  return null;
}

async function sendResendTemplate(
  to: string,
  variables: Record<string, unknown>,
): Promise<{ ok: boolean; error?: string }> {
  const apiKey = Deno.env.get("RESEND_API_KEY");
  if (!apiKey) return { ok: false, error: "resend_api_key_missing" };
  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: RESEND_FROM,
        to: [to],
        template: { id: RESEND_TEMPLATE_ID, variables },
      }),
    });
    if (!res.ok) {
      const detail = await res.text().catch(() => "");
      return { ok: false, error: `resend_${res.status}_${detail.slice(0, 80)}` };
    }
    return { ok: true };
  } catch (e) {
    return { ok: false, error: String(e) };
  }
}

interface ProRow {
  id: string;
  business_name: string | null;
  stripe_account_id: string;
  stripe_onboarded: boolean;
  stripe_connect_reminder_sent_at: string | null;
  stripe_connect_reminder_count: number;
  users: {
    email: string | null;
    full_name: string | null;
    display_name: string | null;
    created_at: string;
    role: string;
  } | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: securityHeadersFor() });
  if (req.method !== "POST") return jsonResponse({ error: "method_not_allowed" }, 405);

  const forbidden = await assertCronAuth(req);
  if (forbidden) return forbidden;

  try {
    const service = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const sevenDaysAgoIso = new Date(Date.now() - REMINDER_WINDOW_MS).toISOString();

    const { data: rows, error: fetchErr } = await service
      .from("profiles_pro")
      .select(
        `id, business_name, stripe_account_id, stripe_onboarded,
         stripe_connect_reminder_sent_at, stripe_connect_reminder_count,
         users:users!inner(email, full_name, display_name, created_at, role)`,
      )
      .eq("stripe_onboarded", false)
      .not("stripe_account_id", "is", null)
      .lt("stripe_connect_reminder_count", MAX_REMINDERS)
      .or(
        `stripe_connect_reminder_sent_at.is.null,stripe_connect_reminder_sent_at.lt.${sevenDaysAgoIso}`,
      )
      .limit(BATCH_SIZE);

    if (fetchErr) {
      console.error("[stripe-connect-reminder] fetch error:", fetchErr);
      return jsonResponse({ error: "fetch_failed" }, 500);
    }

    const candidates = ((rows ?? []) as unknown as ProRow[]).filter((r) => {
      if (!r.users || r.users.role !== "pro") return false;
      const ageMs = Date.now() - new Date(r.users.created_at).getTime();
      return ageMs >= REMINDER_WINDOW_MS;
    });

    if (candidates.length === 0) return jsonResponse({ success: true, eligible: 0, emailed: 0 });

    let emailed = 0;
    const onboardingUrl = `${APP_URL}/pro/stripe-onboarding`;
    const nowIso = new Date().toISOString();

    for (const pro of candidates) {
      const email = pro.users!.email;
      if (!email || !isValidEmail(email)) {
        console.warn(`[stripe-connect-reminder] missing email pro=${pro.id}`);
        continue;
      }
      const proName = pro.users!.display_name ||
        pro.users!.full_name ||
        pro.business_name ||
        "Pro Spotbook";
      const reminderNumber = pro.stripe_connect_reminder_count + 1;

      const r = await sendResendTemplate(email, {
        pro_name: proName,
        business_name: pro.business_name ?? "",
        reminder_number: reminderNumber,
        max_reminders: MAX_REMINDERS,
        onboarding_url: onboardingUrl,
      });

      if (!r.ok) {
        console.warn(`[stripe-connect-reminder] email failed pro=${pro.id}: ${r.error}`);
        continue;
      }

      const { error: updErr } = await service
        .from("profiles_pro")
        .update({
          stripe_connect_reminder_sent_at: nowIso,
          stripe_connect_reminder_count: reminderNumber,
        })
        .eq("id", pro.id);

      if (updErr) {
        console.error(`[stripe-connect-reminder] tracking update failed pro=${pro.id}:`, updErr);
      }
      emailed++;
    }

    return jsonResponse({ success: true, eligible: candidates.length, emailed });
  } catch (e) {
    console.error("[stripe-connect-reminder] error:", e);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
