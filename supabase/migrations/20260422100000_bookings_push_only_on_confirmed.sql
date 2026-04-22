-- ─────────────────────────────────────────────────────────────────────────────
-- Migration : 2026-04-22
-- But : un Pro ne doit PAS recevoir de push FCM "Nouvelle réservation" au
--       moment de l'INSERT d'un booking (status `pending_payment`) — seulement
--       quand le paiement est effectivement confirmé.
--
-- Contexte : avant cette migration, le trigger `tr_bookings_push_after_insert`
-- se déclenchait sur INSERT, donc dès la création initiale du booking (toujours
-- `pending_payment` à ce moment). Résultat : le Pro recevait une notification
-- push pour un RDV qui pouvait n'être jamais confirmé (si le client abandonne
-- le paiement). Cf. docs/BOOKING_FLOW_REFONTE_PLAN.md §P2.
--
-- Fix : on remplace le trigger INSERT par un trigger AFTER UPDATE qui ne se
-- déclenche QUE lorsque le status passe à 'confirmed' (et n'y était pas avant).
-- La fonction elle-même est inchangée, on ne touche qu'au WHEN du trigger.
--
-- Rollback : recréer le trigger INSERT (DROP du UPDATE + CREATE INSERT).
-- ─────────────────────────────────────────────────────────────────────────────

BEGIN;

-- On retire l'ancien trigger INSERT.
DROP TRIGGER IF EXISTS "tr_bookings_push_after_insert" ON "public"."bookings";

-- On crée un nouveau trigger AFTER UPDATE qui se déclenche uniquement à la
-- transition vers 'confirmed'. Le WHEN filtre côté Postgres pour éviter
-- d'exécuter la fonction inutilement sur chaque UPDATE de booking.
CREATE TRIGGER "tr_bookings_push_on_confirmed"
  AFTER UPDATE OF "status" ON "public"."bookings"
  FOR EACH ROW
  WHEN (
    OLD."status" IS DISTINCT FROM NEW."status"
    AND NEW."status" = 'confirmed'
  )
  EXECUTE FUNCTION "public"."tr_notify_new_booking_push"();

COMMIT;
