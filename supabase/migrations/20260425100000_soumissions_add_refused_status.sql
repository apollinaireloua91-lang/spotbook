-- ═══════════════════════════════════════════════════════════════════════════════
-- SOUMISSIONS — Add 'refused' status to support client decline flow
-- ═══════════════════════════════════════════════════════════════════════════════
-- Context: the original status workflow (migration 20260412100000) covered
-- draft→sent→viewed→accepted→paid|expired|cancelled but had no terminal state
-- for "client looked at the quote and explicitly said no". Without 'refused',
-- the Pro can't distinguish a quote that was rejected (so they should follow
-- up differently) from one that just expired without a response.
--
-- This unblocks the `refuse-soumission` Edge Function + the
-- `soumission-refuse-pro` Resend template (which existed unwired since
-- 2026-04-22 — see resend_template_aliases.ts header).

ALTER TABLE soumissions DROP CONSTRAINT IF EXISTS soumissions_status_check;

ALTER TABLE soumissions ADD CONSTRAINT soumissions_status_check
  CHECK (status IN (
    'draft',
    'sent',
    'viewed',
    'accepted',
    'refused',
    'paid',
    'expired',
    'cancelled'
  ));

-- Allow client to also flip to 'refused' (in addition to existing 'viewed' +
-- 'accepted' transitions). Note: refuse-soumission Edge Function uses
-- service_role + share_token, but we keep the policy permissive in case a
-- future authenticated-only flow needs it.
DROP POLICY IF EXISTS soumissions_client_update ON soumissions;
CREATE POLICY soumissions_client_update ON soumissions
  FOR UPDATE TO authenticated
  USING (auth.uid() = client_id)
  WITH CHECK (status IN ('viewed', 'accepted', 'refused'));
