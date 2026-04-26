import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// expire-soumissions — Cron-only Edge Function (verify_jwt=false on the gateway).
// Authenticates via a Vault-stored shared secret (read by both pg_cron caller
// and this function via the public.get_cron_shared_secret() RPC).
//
// Flow per run:
//   1. assertCronAuth() — compare Authorization to Vault secret
//   2. SELECT soumissions WHERE status IN ('sent','viewed') AND valid_until < now()
//   3. UPDATE those rows to status='expired'
//   4. For each row, send the Resend template `soumission-expire` to the Pro

const APP_URL = "https://getspotbook.app";
const BATCH_SIZE = 100;
const RESEND_TEMPLATE_ID = "8aa3115f-b7a2-4119-8b59-14676941f6e1"; // soumission-expire
const RESEND_FROM = "Spotbook <noreply@getspotbook.app>";

// ── Inlined helpers (extracted from _shared/) ──

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
  let result = 0;
  for (let i = 0; i < a.length; i++) result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return result === 0;
}

function isValidEmail(v: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

function sanitizeText(v: string): string {
  return v.replace(/<\/?[^>]+(>|$)/g, "").trim();
}

function fmtMoney(cents: number): string {
  return `${(cents / 100).toFixed(2).replace(".", ",")} $`;
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
      console.error("[expire-soumissions] vault read failed:", error);
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

interface ExpiredSoumission {
  id: string;
  pro_id: string;
  title: string;
  client_name: string | null;
  total_cents: number;
  valid_until: string;
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

    const nowIso = new Date().toISOString();
    const { data: candidates, error: fetchErr } = await service
      .from("soumissions")
      .select("id, pro_id, title, client_name, total_cents, valid_until")
      .in("status", ["sent", "viewed"])
      .not("valid_until", "is", null)
      .lt("valid_until", nowIso)
      .limit(BATCH_SIZE);

    if (fetchErr) {
      console.error("[expire-soumissions] fetch error:", fetchErr);
      return jsonResponse({ error: "fetch_failed" }, 500);
    }

    const list = (candidates ?? []) as ExpiredSoumission[];
    if (list.length === 0) return jsonResponse({ success: true, expired: 0, emailed: 0 });

    const ids = list.map((s) => s.id);
    const { error: updErr } = await service
      .from("soumissions")
      .update({ status: "expired" })
      .in("id", ids);

    if (updErr) {
      console.error("[expire-soumissions] update error:", updErr);
      return jsonResponse({ error: "update_failed" }, 500);
    }

    let emailed = 0;
    for (const soum of list) {
      const { data: proUser } = await service
        .from("users")
        .select("email, full_name, display_name")
        .eq("id", soum.pro_id)
        .maybeSingle();

      const proEmail = proUser?.email as string | undefined;
      if (!proEmail || !isValidEmail(proEmail)) {
        console.warn(`[expire-soumissions] missing email soumission=${soum.id}`);
        continue;
      }

      const proName = proUser?.display_name || proUser?.full_name || "Pro Spotbook";
      const totalCents = soum.total_cents ?? 0;

      const r = await sendResendTemplate(proEmail, {
        pro_name: proName,
        client_name: sanitizeText(soum.client_name ?? "Le client"),
        title: soum.title,
        total_cents: totalCents,
        total_formatted: fmtMoney(totalCents),
        expired_at: new Date(soum.valid_until).toLocaleDateString("fr-CA"),
        dashboard_url: `${APP_URL}/pro/soumissions/${soum.id}`,
      });

      if (r.ok) emailed++;
      else console.warn(`[expire-soumissions] email failed soumission=${soum.id}: ${r.error}`);
    }

    return jsonResponse({ success: true, expired: list.length, emailed });
  } catch (e) {
    console.error("[expire-soumissions] error:", e);
    return jsonResponse({ error: "internal_error" }, 500);
  }
});
