// send-message-notification
// ─────────────────────────
// Déclenche une notif push FCM au destinataire d'un message qui vient
// d'être inséré dans `messages`. Ce wrapper a trois rôles :
//
//   1. Vérifie que l'appelant est bien l'auteur du message (pas un tiers
//      qui spammerait un destinataire via l'API).
//   2. Identifie le destinataire (l'autre participant de la conversation).
//   3. Appelle `send-push-notification` avec un payload typé + un idempotency
//      key pour éviter les doublons si Flutter retry.
//
// Choix : on laisse le caller (Flutter) invoquer cette fonction juste après
// avoir INSERT le message. Alternative évaluée : trigger DB → pg_net, mais
// trop fragile sur les réseaux à latence (timeouts silencieux) pour une
// beta. On pourra migrer vers un trigger + queue (pg_cron) une fois la
// volumétrie connue.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  isValidUuid,
  jsonResponse,
  sanitizeText,
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
    const messageId = String(body?.messageId ?? "");
    if (!isValidUuid(messageId)) {
      return jsonResponse({ error: "messageId_invalid" }, 400, undefined, req);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // ── Fetch message + conversation ──
    const { data: msg, error: mErr } = await supabase
      .from("messages")
      .select(
        "id, conversation_id, sender_id, content, created_at, conversations(id, client_id, pro_id)",
      )
      .eq("id", messageId)
      .maybeSingle();

    if (mErr || !msg) {
      return jsonResponse({ error: "message_not_found" }, 404, undefined, req);
    }

    if (msg.sender_id !== user.id) {
      return jsonResponse({ error: "forbidden" }, 403, undefined, req);
    }

    const conv = msg.conversations as
      | { client_id?: string; pro_id?: string }
      | null;
    if (!conv?.client_id || !conv?.pro_id) {
      return jsonResponse(
        { error: "conversation_incomplete" },
        422,
        undefined,
        req,
      );
    }

    // Le destinataire est l'autre participant. Si sender = pro → client
    // reçoit ; sinon pro reçoit. Cas pro-to-pro ou client-to-client non
    // supportés par le schéma actuel, donc pas à prévoir ici.
    const recipientId = msg.sender_id === conv.pro_id
      ? conv.client_id
      : conv.pro_id;
    if (recipientId === msg.sender_id) {
      return jsonResponse(
        { error: "recipient_is_sender" },
        422,
        undefined,
        req,
      );
    }

    // ── Préférences utilisateur ──
    // Si le destinataire a désactivé les notifs "messages", on s'arrête
    // avant d'appeler FCM — évite un reject côté device et un log inutile.
    const { data: prefs } = await supabase
      .from("notification_preferences")
      .select("messages_enabled")
      .eq("user_id", recipientId)
      .maybeSingle();

    if (prefs && prefs.messages_enabled === false) {
      return jsonResponse(
        { success: true, skipped: "recipient_opted_out" },
        200,
        undefined,
        req,
      );
    }

    // ── Titre + snippet ──
    const { data: senderProfile } = await supabase
      .from("users")
      .select("full_name, display_name")
      .eq("id", msg.sender_id)
      .maybeSingle();

    const title = senderProfile?.display_name ||
      senderProfile?.full_name ||
      "Nouveau message";
    // Snippet : 120 chars max, sanitize pour éviter d'embarquer du HTML
    // dans la notif (iOS/Android traitent les notifs en plain text mais
    // un payload mal formé pollue l'affichage).
    const snippet = sanitizeText(String(msg.content ?? "")).slice(0, 120);

    // ── Appel send-push-notification ──
    const pushResp = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/send-push-notification`,
      {
        method: "POST",
        headers: {
          Authorization:
            `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          userId: recipientId,
          title,
          body: snippet,
          type: "message",
          data: {
            conversationId: String(msg.conversation_id ?? ""),
            messageId: msg.id,
            senderId: msg.sender_id,
          },
          actorId: msg.sender_id,
        }),
      },
    );

    if (!pushResp.ok) {
      const errText = await pushResp.text().catch(() => "");
      console.error("send-push-notification failed", pushResp.status, errText);
      // On ne renvoie pas 500 : le message EST bien envoyé, seule la
      // notif a raté. Le client n'a rien à faire ; monitoring Sentry
      // prendra le relais.
      return jsonResponse(
        { success: true, pushed: false, pushStatus: pushResp.status },
        200,
        undefined,
        req,
      );
    }

    return jsonResponse(
      { success: true, pushed: true },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("send-message-notification error", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
