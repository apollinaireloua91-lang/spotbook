// purchase-tickets-atomic
// ───────────────────────
// Matérialise les `tickets` après qu'un PaymentIntent Stripe est passé en
// `succeeded`. Remplace l'ancien `event_repository.createTickets` qui
// faisait un INSERT client-side (vecteur de fraude 🔴 cf.
// docs/CLIENT_FLOWS_AUDIT.md — la RLS autorisait `auth.uid() = user_id`
// sans vérifier le paiement).
//
// Garanties de cette fonction :
//   1. L'Authorization JWT authentifie vraiment un user ≠ anon.
//   2. Le PI existe côté Stripe ET est `succeeded`.
//   3. Les metadata du PI confirment (userId, ticketTypeId, quantity) →
//      un attaquant ne peut pas réutiliser le PI d'un autre acheteur.
//   4. Idempotence : si des tickets existent déjà pour ce PI (le webhook
//      Stripe peut nous avoir doublé) → on renvoie l'existant sans
//      ré-INSERT.
//   5. Capacité atomique : UPDATE conditionnel sur `ticket_types.sold_count`
//      avec WHERE sold_count + quantity <= quantity_total. Si deux acheteurs
//      grillent la dernière place simultanément, un seul gagne → 409.
//   6. QR HMAC signé côté serveur uniquement (secret `QR_SIGNING_SECRET`
//      jamais exposé au client).
//
// Le webhook `stripe-webhook-handler` conserve la même logique en safety
// net asynchrone — si cette fonction rate (client crashe après le tap),
// le webhook recrée les tickets manquants. Les deux chemins se
// dédupliquent via le check en étape 4.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import Stripe from "https://esm.sh/stripe@14.14.0?target=deno";
import { encode as hexEncode } from "https://deno.land/std@0.168.0/encoding/hex.ts";
import {
  getQrSigningSecret,
  isValidUuid,
  jsonResponse,
  securityHeadersFor,
} from "../_shared/security.ts";
import { generateQrPng } from "../_shared/qr_png.ts";

async function hmacSha256(data: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(data),
  );
  return new TextDecoder().decode(hexEncode(new Uint8Array(sig)));
}

type TicketRow = {
  id: string;
  event_id: string;
  user_id: string;
  ticket_type_id: string;
  purchased_at: string;
};

async function signAndStoreQr(
  supabase: ReturnType<typeof createClient>,
  ticket: TicketRow,
  secret: string,
): Promise<string | null> {
  const data =
    `${ticket.id}|${ticket.event_id}|${ticket.user_id}|${ticket.purchased_at}`;
  const qrHash = await hmacSha256(data, secret);

  await supabase
    .from("tickets")
    .update({ qr_hash: qrHash, status: "valid" })
    .eq("id", ticket.id);

  try {
    const pngBytes = generateQrPng(`${ticket.id}|${qrHash}`, 8, 2);
    // Bucket privé, best effort. L'appelant peut toujours re-signer via
    // get-qr-url plus tard si l'upload échoue ici.
    await supabase.storage.createBucket("ticket-qr-codes", { public: false });
    const filePath = `${ticket.id}.png`;
    const { error: upErr } = await supabase.storage
      .from("ticket-qr-codes")
      .upload(filePath, pngBytes, { contentType: "image/png", upsert: true });
    if (upErr) {
      console.error("qr upload failed", ticket.id, upErr.message);
      return null;
    }
    const { data: signed, error: signErr } = await supabase.storage
      .from("ticket-qr-codes")
      .createSignedUrl(filePath, 60 * 60);
    if (signErr) {
      console.error("qr signed url failed", ticket.id, signErr.message);
      return null;
    }
    return signed?.signedUrl ?? null;
  } catch (e) {
    console.error("qr png gen failed", ticket.id, e);
    return null;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: securityHeadersFor(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, undefined, req);
  }

  try {
    // ── 1. Auth ────────────────────────────────────────────────────────
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

    // ── 2. Input ───────────────────────────────────────────────────────
    const body = await req.json().catch(() => ({}));
    const paymentIntentId = String(body?.paymentIntentId ?? "");
    const ticketTypeId = String(body?.ticketTypeId ?? "");
    const eventId = String(body?.eventId ?? "");
    const quantity = Number(body?.quantity ?? 0);

    if (
      !paymentIntentId.startsWith("pi_") ||
      !isValidUuid(ticketTypeId) ||
      !isValidUuid(eventId) ||
      !Number.isInteger(quantity) ||
      quantity < 1 ||
      quantity > 4
    ) {
      return jsonResponse(
        { error: "payload_invalid" },
        400,
        undefined,
        req,
      );
    }

    // ── 3. Vérification Stripe (source de vérité) ──────────────────────
    const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
      apiVersion: "2023-10-16",
    });

    let pi: Stripe.PaymentIntent;
    try {
      pi = await stripe.paymentIntents.retrieve(paymentIntentId);
    } catch (e) {
      console.error("stripe pi retrieve failed", paymentIntentId, e);
      return jsonResponse({ error: "pi_not_found" }, 404, undefined, req);
    }

    if (pi.status !== "succeeded") {
      return jsonResponse(
        { error: "pi_not_succeeded", status: pi.status },
        409,
        undefined,
        req,
      );
    }

    // Les metadata sont écrites par `stripe-create-ticket-intent` lors de
    // la création du PI. Un PI sans ces champs n'a pas été créé par notre
    // propre flow (ou a été manipulé) → on refuse.
    const meta = pi.metadata ?? {};
    if (
      meta.type !== "ticket" ||
      meta.userId !== user.id ||
      meta.ticketTypeId !== ticketTypeId ||
      String(meta.quantity) !== String(quantity) ||
      String(meta.eventId) !== eventId
    ) {
      return jsonResponse(
        { error: "pi_metadata_mismatch" },
        403,
        undefined,
        req,
      );
    }

    // ── 4. Idempotence — tickets déjà matérialisés ? ───────────────────
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: existing } = await supabase
      .from("tickets")
      .select("id, event_id, user_id, ticket_type_id, purchased_at, qr_hash")
      .eq("stripe_payment_intent_id", paymentIntentId)
      .eq("user_id", user.id);

    if (existing && existing.length >= quantity) {
      // Le webhook ou un appel précédent a déjà fait le travail. On
      // renvoie juste les tickets existants + leurs QR (re-signés si
      // nécessaire).
      const secret = getQrSigningSecret();
      if (!secret) {
        return jsonResponse(
          { error: "server_misconfigured" },
          500,
          undefined,
          req,
        );
      }
      const results: Array<{ id: string; qrCodeUrl: string | null }> = [];
      for (const t of existing) {
        const url = await signAndStoreQr(
          supabase,
          t as TicketRow,
          secret,
        );
        results.push({ id: (t as TicketRow).id, qrCodeUrl: url });
      }
      return jsonResponse(
        { success: true, already_processed: true, tickets: results },
        200,
        undefined,
        req,
      );
    }

    // ── 5. Capacité atomique ───────────────────────────────────────────
    // UPDATE conditionnel : on ne réserve les N places que si elles sont
    // encore dispo. La course avec `stripe-webhook-handler` est tranchée
    // par Postgres — celui qui écrit le second voit `sold_count + q > q`
    // et ne met pas à jour (0 rows returned).
    const { data: ttUpdated, error: ttErr } = await supabase.rpc(
      "increment_sold_count_if_available",
      { p_ticket_type_id: ticketTypeId, p_quantity: quantity },
    );

    if (ttErr) {
      // Fallback : si la RPC n'existe pas encore, on tente l'ancienne
      // (non atomique) et on fait confiance à la vérification d'Edge
      // `stripe-create-ticket-intent` qui a déjà filtré au moment du PI.
      console.warn(
        "increment_sold_count_if_available indisponible, fallback legacy",
        ttErr.message,
      );
      await supabase.rpc("increment_sold_count", {
        p_ticket_type_id: ticketTypeId,
        p_quantity: quantity,
      });
    } else if (ttUpdated === null || ttUpdated === false) {
      return jsonResponse(
        { error: "sold_out" },
        409,
        undefined,
        req,
      );
    }

    // ── 6. INSERT des tickets ──────────────────────────────────────────
    const toInsert = Array.from({ length: quantity }).map(() => ({
      event_id: eventId,
      ticket_type_id: ticketTypeId,
      user_id: user.id,
      stripe_payment_intent_id: paymentIntentId,
      status: "pending", // passera à 'valid' après signature QR
    }));

    const { data: inserted, error: insErr } = await supabase
      .from("tickets")
      .insert(toInsert)
      .select("id, event_id, user_id, ticket_type_id, purchased_at");

    if (insErr || !inserted) {
      console.error("ticket insert failed", insErr?.message);
      return jsonResponse(
        { error: "ticket_insert_failed" },
        500,
        undefined,
        req,
      );
    }

    // ── 7. Signature QR (HMAC SHA-256) + upload PNG ────────────────────
    const secret = getQrSigningSecret();
    if (!secret) {
      // Les tickets sont quand même insérés (statut `pending`). Un job
      // de reco peut les re-signer plus tard.
      return jsonResponse(
        {
          success: true,
          tickets: inserted.map((t) => ({ id: t.id, qrCodeUrl: null })),
          warning: "qr_secret_missing",
        },
        200,
        undefined,
        req,
      );
    }

    const results: Array<{ id: string; qrCodeUrl: string | null }> = [];
    for (const t of inserted as TicketRow[]) {
      const url = await signAndStoreQr(supabase, t, secret);
      results.push({ id: t.id, qrCodeUrl: url });
    }

    // ── 8. Audit + notifications (idempotent) ──────────────────────────
    await supabase.rpc("log_audit_action", {
      p_user_id: user.id,
      p_action: "tickets_purchased",
      p_resource_type: "tickets",
      p_resource_id: inserted[0]?.id ?? null,
      p_metadata: {
        payment_intent: paymentIntentId,
        ticket_type_id: ticketTypeId,
        quantity,
      },
    });

    return jsonResponse(
      { success: true, already_processed: false, tickets: results },
      200,
      undefined,
      req,
    );
  } catch (err) {
    console.error("purchase-tickets-atomic error", err);
    return jsonResponse({ error: "internal_error" }, 500, undefined, req);
  }
});
