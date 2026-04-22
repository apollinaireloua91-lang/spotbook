// =============================================================================
// Edge Function: delete-account
// =============================================================================
// Pipeline RGPD complet :
//   1. Vérif JWT utilisateur (identité confirmée par Supabase auth).
//   2. Appel RPC `public.delete_user_account(uid)` en context user pour purger
//      / anonymiser toutes les tables métier (messages, likes, bookings…).
//   3. Suppression de la ligne `auth.users` via admin API (service role).
//      Seule cette étape ne peut pas être faite en SQL — d'où l'Edge Function.
//
// Réponse : { ok: true, summary: { messages: 12, bookings: 3, ... } }
// =============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { jsonResponse, securityHeadersFor } from "../_shared/security.ts";
import { sendResendEmail } from "../_shared/send_resend_email.ts";

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

  // Client auth (propage le JWT au RPC pour que auth.uid() = user.id).
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

  // Étape 0 : email d'adieu AVANT le RPC.
  // Le RPC `delete_user_account` scramble l'email dans `public.users` (tombstone
  // RGPD) — si on envoie après, l'email de destination est perdu. On fetch + send
  // ici en best-effort. Si le fetch ou le send plante, on continue la suppression
  // (un email n'est pas suffisant pour bloquer un droit à l'oubli).
  try {
    const preDeleteClient = createClient(supabaseUrl, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: row } = await preDeleteClient
      .from("users")
      .select("email, full_name")
      .eq("id", user.id)
      .maybeSingle();
    const typedRow = row as
      | { email: string | null; full_name: string | null }
      | null;
    if (typedRow?.email) {
      await sendResendEmail({
        event: "account_deactivated",
        to: typedRow.email,
        variables: {
          fullName: typedRow.full_name ?? "",
          deletedAt: new Date().toISOString(),
        },
      });
    }
  } catch (mailErr) {
    console.warn(
      "delete-account: farewell email failed",
      (mailErr as Error).message,
    );
  }

  // Étape 1+2 : purge SQL via RPC (auth.uid() vérifié côté DB).
  const { data: summary, error: rpcErr } = await userClient.rpc(
    "delete_user_account",
    { p_user_id: user.id },
  );
  if (rpcErr) {
    console.error("delete_user_account RPC failed", {
      user_id: user.id,
      error: rpcErr.message,
    });
    return jsonResponse(
      { error: "delete_failed", detail: rpcErr.message },
      500,
      undefined,
      req,
    );
  }

  // Étape 3 : suppression auth.users via admin API. Obligatoire pour couper
  // toute session future et libérer l'email (même scramblé, l'auth conserve
  // la ligne tant qu'on ne la delete pas explicitement).
  const adminClient = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { error: authDeleteErr } = await adminClient.auth.admin.deleteUser(
    user.id,
  );
  if (authDeleteErr) {
    // Les données métier sont déjà anonymisées → on log mais on ne rollback
    // pas (partiel > rien). L'utilisateur est déconnecté à la prochaine action.
    console.error("auth.admin.deleteUser failed after data purge", {
      user_id: user.id,
      error: authDeleteErr.message,
    });
    return jsonResponse(
      {
        ok: true,
        summary,
        warning: "auth_user_deletion_failed",
        detail: authDeleteErr.message,
      },
      200,
      undefined,
      req,
    );
  }

  return jsonResponse({ ok: true, summary }, 200, undefined, req);
});
