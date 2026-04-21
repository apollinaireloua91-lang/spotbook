// join-waitlist-atomic
// ────────────────────
// Edge Function fine qui :
//   1. Authentifie le user via son JWT.
//   2. Délègue le travail à la RPC `join_waitlist_atomic` (voir migration
//      20260421140000) qui sérialise les insertions via advisory lock.
//   3. Retourne la position attribuée.
//
// On sépare l'auth de la logique parce que la RPC doit être `SECURITY
// DEFINER` pour pouvoir prendre le verrou — mais on ne veut pas accorder
// l'exécution à anon, seulement aux users authentifiés passant par le
// JWT. L'Edge Function est le point de contrôle.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    // ── Auth ──
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }
    const authClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await authClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "unauthorized" }, 401, undefined, req);
    }

    // ── Input ──
    const body = await req.json().catch(() => ({}));
    const ticketTypeId = String(body?.ticketTypeId ?? "");
    if (!isValidUuid(ticketTypeId)) {
      return jsonResponse(
        { error: "ticketTypeId_invalid" },
        400,
        undefined,
        req,
      );
    }

    // ── Vérification que le ticket_type existe et que l'event n'est pas
    // déjà passé — évite d'empiler des positions sur des events morts.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );
    const { data: tt, error: ttErr } = await supabase
      .from("ticket_types")
      .select("id, event_id, events(event_date)")
      .eq("id", ticketTypeId)
      .maybeSingle();

    if (ttErr || !tt) {
      return jsonResponse({ error: "ticket_type_not_found" }, 404, undefined, req);
    }

    const eventDateRaw = (tt.events as { event_date?: string } | null)
      ?.event_date;
    if (eventDateRaw) {
      const eventTs = new Date(eventDateRaw).getTime();
      if (!Number.isNaN(eventTs) && eventTs < Date.now()) {
        return jsonResponse({ error: "event_past" }, 409, undefined, req);
      }
    }

    // ── RPC atomique ──
    const { data, error } = await supabase.rpc("join_waitlist_atomic", {
      p_ticket_type_id: ticketTypeId,
      p_user_id: user.id,
    });

    if (error) {
      console.error("join_waitlist_atomic rpc failed", error.message);
      return jsonResponse(
        { error: "waitlist_join_failed" },
        500,
        undefined,
        req,
      );
    }

    const row = Array.isArray(data) ? data[0] : data;
    if (!row) {
      return jsonResponse(
        { error: "waitlist_empty_response" },
        500,
        undefined,
        req,
      );
    }

    return jsonResponse(
      {
        success: true,
        position: row.position,
        alreadyIn: row.already_in,
      },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("join-waitlist-atomic error", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
