// =============================================================================
// Edge Function: send-welcome-email
// =============================================================================
// Fire-and-forget welcome email, invoked by Flutter immediately after a
// successful signup (email/password). Deliberately NOT wired to a DB trigger:
//   - Triggers would fire on backfills, admin inserts, data migrations —
//     every one of those paths would spam random users.
//   - Flutter-initiated invoke guarantees we only send on a real human signup
//     flow and lets us include display-time data (resolved `full_name`,
//     preferred language) that the auth trigger doesn't have access to.
//
// Auth model : propagates the user's JWT to resolve identity. The caller must
// already have a session (the invoke happens right after `auth.signUp`
// succeeded with a session, or right after an OAuth first-login callback).
//
// Response : `{ ok: true }` on success, `{ ok: false, reason }` otherwise.
// Callers fire-and-forget — no UX blocking on email delivery.
// =============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { jsonResponse, securityHeadersFor } from "../_shared/security.ts";
import { sendResendEmail } from "../_shared/send_resend_email.ts";

interface WelcomeUserRow {
  email: string | null;
  full_name: string | null;
  role: string | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return jsonResponse({ error: "server_misconfigured" }, 500, undefined, req);
  }

  // Auth client with caller JWT — gives us `auth.uid()` binding via Supabase's
  // token introspection. Used only to resolve the caller's identity.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userErr,
  } = await userClient.auth.getUser();
  if (userErr || !user) {
    return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
  }

  // Service-role lookup on the public.users row: the caller can't read their
  // own `role` cleanly via RLS (depends on schema policies) and we need it to
  // branch the email copy. Email is taken from here rather than auth.users to
  // match what the rest of the stack uses (the two are kept in sync by the
  // signup trigger).
  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: rowRaw, error: rowErr } = await admin
    .from("users")
    .select("email, full_name, role")
    .eq("id", user.id)
    .maybeSingle();

  // Cast explicite : Supabase SDK ne résout pas les FK embeds typés (bug connu
  // v2.x) — même sans embed, on reste cohérent avec le pattern projet.
  const row = rowRaw as unknown as WelcomeUserRow | null;

  if (rowErr) {
    console.error("send-welcome-email: users lookup failed", rowErr.message);
    return jsonResponse({ ok: false, reason: "lookup_failed" }, 500, undefined, req);
  }

  const recipient = row?.email ?? user.email ?? null;
  if (!recipient) {
    return jsonResponse({ ok: false, reason: "no_email" }, 400, undefined, req);
  }

  // Best-effort send. `sendResendEmail` never throws — returns a structured
  // result. We swallow everything downstream of auth/recipient validation so
  // the caller can always `.invoke()` without a try/catch.
  const result = await sendResendEmail({
    event: "welcome",
    to: recipient,
    variables: {
      fullName: row?.full_name ?? "",
      role: row?.role ?? "client",
      email: recipient,
    },
  });

  return jsonResponse({ ok: result.ok, mode: result.mode }, 200, undefined, req);
});
