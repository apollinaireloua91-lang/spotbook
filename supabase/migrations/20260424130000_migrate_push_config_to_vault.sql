-- Migration: migrate_push_config_to_vault
--
-- Contexte
-- ────────
-- Sur Supabase Cloud, `ALTER DATABASE postgres SET app.settings.X = ...`
-- échoue avec `permission denied (42501)` — seul le superuser peut écrire
-- des GUC personnalisées au niveau database/role, et Supabase Cloud ne
-- l'expose pas. Conséquence : la helper `fire_send_push_notification`
-- (cf. migration 20260326121446_remote_schema.sql L312-354) ne peut pas
-- récupérer son URL ni son service_role_key via `current_setting(...)` →
-- elle exit silencieusement et AUCUN push (booking, message, follow,
-- review, ticket, booking_reported) n'est jamais envoyé.
--
-- Cf. docs/PRO_NOTIFICATIONS_AUDIT.md §3 bug #1 (mise à jour 2026-04-24).
--
-- Fix
-- ───
-- Bascule la lecture des deux paramètres sur Supabase Vault (extension
-- `supabase_vault`), qui expose une vue `vault.decrypted_secrets` (RLS
-- restreint à `postgres` + `service_role`).
--
-- Pourquoi modifier la HELPER plutôt que `tr_notify_new_message_push` ?
-- ───────────────────────────────────────────────────────────────────
-- `fire_send_push_notification` est appelée par 6 triggers/fonctions
-- (messages, bookings, follows, reviews, tickets, booking_reported).
-- Modifier la helper bénéficie à TOUS d'un seul coup, sans risquer de
-- divergence entre triggers. La forme du payload HTTP (qui matche le
-- contrat de l'EF `send-push-notification` : `{userId, title, body,
-- type, data}`) reste centralisée ici.
--
-- Setup manuel requis
-- ───────────────────
-- Cette migration NE CRÉE PAS les secrets dans Vault. Apollinaire doit
-- les créer manuellement via Supabase Dashboard → SQL Editor avec :
--
--   SELECT vault.create_secret(
--     '<service_role_key>',
--     'service_role_key',
--     'Service role key used by fire_send_push_notification helper'
--   );
--   SELECT vault.create_secret(
--     'https://<project-ref>.supabase.co/functions/v1/send-push-notification',
--     'push_function_url',
--     'URL of the send-push-notification Edge Function'
--   );
--
-- Vérifier ensuite :
--   SELECT name FROM vault.secrets
--   WHERE name IN ('push_function_url', 'service_role_key');

-- L'extension est généralement déjà activée sur Supabase Cloud. CREATE
-- IF NOT EXISTS est idempotent et no-op si déjà présente.
CREATE EXTENSION IF NOT EXISTS supabase_vault;

CREATE OR REPLACE FUNCTION public.fire_send_push_notification(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_type text,
  p_data jsonb DEFAULT '{}'::jsonb
) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    -- vault dans le search_path pour que `vault.decrypted_secrets` soit
    -- résolu sans qualification dans les fallback futurs. La qualification
    -- explicite (`vault.decrypted_secrets`) ci-dessous reste défensive.
    SET search_path TO 'public', 'vault'
AS $$
DECLARE
  v_url text;
  v_key text;
  v_body jsonb;
BEGIN
  -- Lookup Vault (remplace current_setting('app.settings.X')).
  -- vault.decrypted_secrets est une vue : SELECT direct, RLS-protégé,
  -- accessible aux fonctions SECURITY DEFINER ownées par postgres.
  SELECT decrypted_secret INTO v_url
  FROM vault.decrypted_secrets
  WHERE name = 'push_function_url'
  LIMIT 1;

  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  IF v_url IS NULL OR v_url = '' OR v_key IS NULL OR v_key = '' THEN
    RAISE LOG 'fire_send_push_notification: skip (vault secrets push_function_url and/or service_role_key missing)';
    RETURN;
  END IF;

  -- Payload identique au contrat de l'EF send-push-notification :
  --   { userId, title, body, type, data }
  v_body := jsonb_build_object(
    'userId', p_user_id::text,
    'title', p_title,
    'body', p_body,
    'type', p_type,
    'data', COALESCE(p_data, '{}'::jsonb)
  );

  PERFORM net.http_post(
    url := v_url,
    body := v_body,
    params := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    timeout_milliseconds := 8000
  );
END;
$$;

-- Owner et grants inchangés (CREATE OR REPLACE préserve les permissions
-- existantes), mais on les ré-affirme pour traçabilité.
ALTER FUNCTION public.fire_send_push_notification(uuid, text, text, text, jsonb)
  OWNER TO postgres;

REVOKE ALL ON FUNCTION public.fire_send_push_notification(uuid, text, text, text, jsonb)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fire_send_push_notification(uuid, text, text, text, jsonb)
  TO anon, authenticated, service_role;
