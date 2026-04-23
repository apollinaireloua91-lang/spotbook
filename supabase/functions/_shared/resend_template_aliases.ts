// ════════════════════════════════════════════════════════════════════════════
// resend_template_aliases.ts — Single source of truth: Spotbook event → Resend
// ────────────────────────────────────────────────────────────────────────────
// The aliases below are the REAL published aliases in the Spotbook Resend
// dashboard as of 2026-04-22, fetched via `GET /templates`. Accented French
// aliases are kept verbatim (some are truncated because Resend strips diacritics
// when auto-generating aliases from template names — e.g. "Événement annulé"
// → "vnement-annul"). We do NOT rename them in the dashboard: stability of
// aliases matters more than prettiness since they are what call sites depend on.
//
// How the map is consumed:
//   - `sendResendEmail` reads `RESEND_TEMPLATES[event]` to get the template id.
//     Resend's /emails endpoint expects `template: { id, variables }`.
//   - The alias string is kept in the value for human readability (log output
//     includes it) and as a stable link back to the dashboard URL
//     https://resend.com/templates/<alias>.
//   - If Apollinaire recreates a template in the dashboard, only the `id`
//     changes — the alias stays. Update the `id` here and every call site
//     continues to work.
//
// Events absent from `RESEND_TEMPLATES` fall back to the HTML templates in
// `email_templates.ts` (dispatched via `buildEmail`). This is intentional for
// `pos_receipt` (too many dynamic variables for a simple Resend template).
//
// ⚠ DO NOT import this file from Flutter. Deno-only (Edge Functions).
// ════════════════════════════════════════════════════════════════════════════

/**
 * Every distinct email event Spotbook can emit. Keys are `snake_case` and
 * stable — they're referenced from edge functions and the unified dispatcher.
 *
 * NB: Some events split on a business dimension (e.g. `payment_receipt_full`
 * vs `payment_receipt_deposit`) because Apollinaire has two templates in the
 * dashboard — one per payment mode.
 */
export type EmailEventKey =
  // ─── Client — currently ACTIVE in code ───
  | "booking_confirmed" // legacy — gardé pour compat tests ; remplacé par les 2 keys ci-dessous
  | "booking_accepted_by_pro" // update-booking-status : Pro accepte, paiement PAS encore capturé
  | "booking_paid_and_confirmed" // stripe-webhook PI succeeded : paiement capturé + RDV confirmé
  | "booking_cancelled"
  | "refund_completed"
  | "payment_receipt_full"
  | "payment_receipt_deposit"
  | "ticket_purchased"
  | "booking_reminder_j1"
  | "review_request"
  | "pos_receipt" // HTML-only — intentionally absent from RESEND_TEMPLATES
  | "payment_failed"
  | "appointment_cancelled_by_pro"
  | "remaining_payment_reminder"
  | "event_cancelled"
  | "event_reminder"
  | "reminder_1h_before"
  // ─── Pro ───
  | "pro_new_booking"
  | "pro_payment_received"
  | "pro_cancellation_by_client"
  | "pro_payout_sent"
  | "pro_transfer_reversed" // refund > 48h : Stripe reverse le transfer déjà envoyé
  | "pro_new_review"
  // ─── Auth / onboarding — to wire in Commit 4 ───
  | "welcome"
  | "account_deactivated"
  | "pro_stripe_connect_activated";

/**
 * A single Resend template entry. `id` is the canonical key used by the
 * /emails endpoint; `alias` is human-friendly for logs + documentation.
 */
export interface ResendTemplate {
  /** Dashboard alias (stable across recreations). */
  readonly alias: string;
  /** Resend template UUID (what the API actually consumes). */
  readonly id: string;
}

/**
 * Spotbook event → Resend template. Absent keys → HTML fallback.
 * IDs fetched from `GET /templates` on 2026-04-22.
 */
export const RESEND_TEMPLATES: Partial<Record<EmailEventKey, ResendTemplate>> =
  {
    // Client — existing, published
    booking_confirmed: {
      alias: "rservation-confirme",
      id: "b49bd62b-35f7-4694-87c7-489167f8a377",
    },
    // ⚠ Aliases ci-dessous ont été générés automatiquement par Resend (les
    //   diacritiques ont été strippés). On les garde tels quels — la stabilité
    //   des aliases prime sur l'esthétique. Cf. en-tête du fichier.
    booking_accepted_by_pro: {
      alias: "rservation-accepte-par-le-pro",
      id: "a01f7c58-5549-4a83-9159-b2bc5d52d25c",
    },
    booking_paid_and_confirmed: {
      alias: "paiement-confirm-rdv-rserv",
      id: "d4c6c70e-f06a-427c-8488-5032cbe129ce",
    },
    booking_cancelled: {
      alias: "rservation-annule",
      id: "550764b8-12a8-4f0c-9202-af7274128db8",
    },
    refund_completed: {
      alias: "remboursement-effectu",
      id: "59f85f27-a35c-4b95-80eb-5e4947231dc1",
    },
    payment_receipt_full: {
      alias: "reu-de-paiement",
      id: "0ae33cee-2832-43d7-b044-ad7dca6b6d7e",
    },
    payment_receipt_deposit: {
      alias: "acompte-reu",
      id: "d1f0bb61-038f-4733-9786-6b24c684a7cd",
    },
    ticket_purchased: {
      alias: "votre-billet",
      id: "89027df2-241c-4251-a211-bd8766f2b8e2",
    },
    booking_reminder_j1: {
      alias: "rappel-de-rendez-vous",
      id: "55e1702c-10b5-478a-9b15-53a7476d5d79",
    },
    review_request: {
      alias: "donnez-votre-avis",
      id: "d8532fa1-b174-47d3-bd4c-0201b152057b",
    },
    // pos_receipt: intentionally absent — HTML-only (too many dynamic fields).

    // Client — new
    payment_failed: {
      alias: "paiement-chou",
      id: "cb167b78-4cc5-46c6-9bb6-58f3f1a9e352",
    },
    appointment_cancelled_by_pro: {
      alias: "annulation-par-le-professionnel",
      id: "4f39b54e-af3c-4ed2-9f24-08428ed34bb9",
    },
    remaining_payment_reminder: {
      alias: "solde-restant-payer",
      id: "b3dbae47-3622-40fb-9aad-4c1e7fd7a280",
    },
    event_cancelled: {
      alias: "vnement-annul",
      id: "4776e58e-763b-4993-8734-fe10ed4e5e9a",
    },
    event_reminder: {
      alias: "rappel-vnement",
      id: "e2cba0a1-ad14-450e-b607-0e4b5295f42a",
    },
    reminder_1h_before: {
      alias: "rappel-1h-avant",
      id: "b1b54ab3-759a-4da9-8577-623bebe2edb1",
    },

    // Pro — new
    pro_new_booking: {
      alias: "nouvelle-rservation-pro",
      id: "783397f6-c995-46b9-bb19-aca0da34e58d",
    },
    pro_payment_received: {
      alias: "paiement-reu-pro",
      id: "540a9bd6-6342-4985-a7b1-fd78aabe92d7",
    },
    pro_cancellation_by_client: {
      alias: "annulation-client-pro",
      id: "d1301036-5fcf-4b1a-8085-8d3e39b27e82",
    },
    pro_payout_sent: {
      alias: "virement-envoy",
      id: "09e067f5-d062-49bc-b69b-82bff38702e4",
    },
    pro_transfer_reversed: {
      alias: "virement-annul-suite-remboursement",
      id: "16f31ce1-52a5-4ca8-ac32-701de6c8f006",
    },
    pro_new_review: {
      alias: "nouvel-avis-reu-pro",
      id: "d83e2185-d536-4354-941f-d091aa0bedc1",
    },

    // Auth / onboarding
    welcome: {
      alias: "bienvenue-sur-spotbook",
      id: "d9c9bd24-3868-42b1-ba0f-4298753c7932",
    },
    account_deactivated: {
      alias: "compte-dsactiv",
      id: "0ee5e562-cc52-4d20-a2c8-d2719b7850db",
    },
    pro_stripe_connect_activated: {
      alias: "stripe-connect-activ",
      id: "d55b142d-102c-4b48-a79d-65e0809fef8c",
    },
  };

/**
 * Aliases that EXIST in the Resend dashboard but are intentionally NOT wired
 * into an edge function yet. Kept here so a future dev doesn't think these
 * templates are orphaned. Cross-reference `docs/APOLLINAIRE_TODO.md` for
 * context on each one.
 */
export const KNOWN_UNWIRED_ALIASES = [
  // Supabase Auth Email Hook migration — planned post-launch
  "rinitialisation-mot-de-passe",
  "vrification-email",
  // Heuristic suspicious-login detection — not implemented
  "connexion-suspecte",
  // Reschedule feature — backend flow doesn't exist yet
  "rendez-vous-reprogramm",
  // Stripe Connect incomplete-onboarding cron — post-Commit 4
  "rappel-stripe-connect",
  // Catering / quote feature — not in backend scope yet
  "soumission-reue",
  "soumission-accepte-pro",
  "soumission-refuse-pro",
  "soumission-expire",
] as const;

/** Resend drafts to ignore (never used for sending). */
export const RESEND_DRAFT_ALIASES = [
  "untitled-template",
  "untitled-template-1",
] as const;
