-- ═══════════════════════════════════════════════════════════════════════════════
-- get_cron_shared_secret() — Bridge between Vault and Edge Functions
-- ═══════════════════════════════════════════════════════════════════════════════
-- Context: Supabase has migrated this project away from legacy HS256 service_role
-- JWTs. The gateway now rejects them with `UNAUTHORIZED_LEGACY_JWT` even though
-- the env var SUPABASE_SERVICE_ROLE_KEY is still injected for backward
-- compatibility. This breaks every cron Edge Function that relied on
-- `assertServiceRoleOnly()` comparing the Authorization header to that env var.
--
-- Fix: replace the env-var-based shared secret with a Vault-based one.
--   - The cron sends `Authorization: Bearer <secret_from_vault>`
--   - The Edge Function reads the SAME secret from Vault via this RPC
--   - Both sides match → cron passes auth
--
-- Why SECURITY DEFINER + service_role ONLY:
--   The function bypasses RLS (vault.decrypted_secrets is admin-only by default)
--   but EXECUTE is restricted to service_role. Anyone calling the function
--   without service_role gets a permission_denied error from PostgREST.
--
-- Companion Vault entry: `cron_service_role_key` — must be created manually
-- via `vault.create_secret(...)` (not committed to git).

CREATE OR REPLACE FUNCTION public.get_cron_shared_secret()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, vault
AS $$
DECLARE
  secret_value TEXT;
BEGIN
  SELECT decrypted_secret INTO secret_value
  FROM vault.decrypted_secrets
  WHERE name = 'cron_service_role_key'
  LIMIT 1;

  IF secret_value IS NULL THEN
    RAISE EXCEPTION 'cron_service_role_key not found in Vault';
  END IF;

  RETURN secret_value;
END;
$$;

REVOKE ALL ON FUNCTION public.get_cron_shared_secret() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_cron_shared_secret() FROM anon;
REVOKE ALL ON FUNCTION public.get_cron_shared_secret() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.get_cron_shared_secret() TO service_role;

COMMENT ON FUNCTION public.get_cron_shared_secret() IS
  'Returns the shared secret used by cron jobs to authenticate with Edge Functions. service_role only.';
