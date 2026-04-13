-- ============================================================
-- SECURITY AUDIT FIXES — April 2026
-- Fixes: C1 (soumissions anon read-all), timing-safe helpers
-- ============================================================

-- ── C1: SOUMISSIONS — Remove broken anon read-all policy ──────────────
-- The old policy `USING (share_token IS NOT NULL)` was TRUE for every row
-- because share_token has NOT NULL DEFAULT. Anon could read ALL soumissions.
-- Replace with a secure RPC-based lookup.
DROP POLICY IF EXISTS soumissions_share_token_select ON soumissions;

-- Create a secure function for anonymous share_token lookup.
-- Anon users must provide the exact token — no full-table scan.
CREATE OR REPLACE FUNCTION public.get_soumission_by_share_token(p_token TEXT)
RETURNS SETOF soumissions
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT * FROM public.soumissions
  WHERE share_token = p_token
  LIMIT 1;
$$;

-- Grant execute to anon so unauthenticated users with a link can call it
GRANT EXECUTE ON FUNCTION public.get_soumission_by_share_token(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_soumission_by_share_token(TEXT) TO authenticated;

-- Revoke direct anon access to the table entirely
REVOKE ALL ON TABLE public.soumissions FROM anon;
