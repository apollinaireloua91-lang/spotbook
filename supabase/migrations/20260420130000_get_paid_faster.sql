-- ============================================================================
-- Get Paid Faster — Stripe Instant Payouts support (priority #1 follow-up)
-- ============================================================================
-- Adds Pro-side payout preferences + history tracking for Stripe Instant Payouts.
--
-- Why this exists:
--   - Standard Stripe payouts take 2-7 business days. That's too slow for Pros
--     who rely on daily earnings.
--   - Stripe Instant Payouts land in ~30 minutes (1.5% fee, capped at $15 USD).
--   - This migration stores each Pro's preference (standard vs instant) and
--     tracks every payout request for audit + UI history.
--
-- Security:
--   - `stripe_account_id` is read via JOIN to `profiles_pro` (already RLS-locked).
--   - `payout_requests` writes happen ONLY via edge function (service_role).
--   - Pro can READ own payout_requests but never write (prevents race conditions
--     and duplicate instant payout attempts).
-- ============================================================================

-- ── payout_preferences (one row per pro) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.payout_preferences (
  pro_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  schedule TEXT NOT NULL DEFAULT 'standard'
    CHECK (schedule IN ('standard', 'daily', 'weekly', 'manual')),
  instant_enabled BOOLEAN NOT NULL DEFAULT false,
  -- Minimum balance required before auto-triggering a payout (in cents)
  min_auto_payout_cents INTEGER NOT NULL DEFAULT 5000
    CHECK (min_auto_payout_cents >= 1000 AND min_auto_payout_cents <= 1000000),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.payout_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payout_preferences_read_own"
  ON public.payout_preferences FOR SELECT
  USING (pro_id = auth.uid());

CREATE POLICY "payout_preferences_upsert_own"
  ON public.payout_preferences FOR INSERT
  WITH CHECK (pro_id = auth.uid());

CREATE POLICY "payout_preferences_update_own"
  ON public.payout_preferences FOR UPDATE
  USING (pro_id = auth.uid())
  WITH CHECK (pro_id = auth.uid());


-- ── payout_requests (audit log of every payout attempt) ───────────────────
CREATE TABLE IF NOT EXISTS public.payout_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
  currency TEXT NOT NULL DEFAULT 'CAD',
  method TEXT NOT NULL CHECK (method IN ('standard', 'instant')),
  fee_cents INTEGER NOT NULL DEFAULT 0 CHECK (fee_cents >= 0),
  net_cents INTEGER NOT NULL CHECK (net_cents >= 0),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'paid', 'failed', 'cancelled')),
  stripe_payout_id TEXT UNIQUE,
  failure_reason TEXT,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  expected_arrival TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_payout_requests_pro ON public.payout_requests (pro_id, requested_at DESC);
CREATE INDEX IF NOT EXISTS idx_payout_requests_status ON public.payout_requests (status) WHERE status IN ('pending', 'processing');

ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payout_requests_read_own"
  ON public.payout_requests FOR SELECT
  USING (pro_id = auth.uid());

-- Writes only via service_role (edge function) — prevents race conditions and
-- double-spending an instant payout before Stripe confirms.
CREATE POLICY "payout_requests_service_role_write"
  ON public.payout_requests FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ── updated_at trigger for payout_preferences ────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at_payout_prefs()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payout_prefs_updated_at ON public.payout_preferences;
CREATE TRIGGER trg_payout_prefs_updated_at
  BEFORE UPDATE ON public.payout_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at_payout_prefs();


COMMENT ON TABLE public.payout_preferences IS 'Per-Pro payout schedule + instant-enabled flag. One row per user.';
COMMENT ON TABLE public.payout_requests IS 'Audit log of every payout request (instant or standard). Writes via service_role only.';
COMMENT ON COLUMN public.payout_requests.fee_cents IS 'Stripe Instant Payout fee (1.5% capped at $15 USD equivalent). Zero for standard.';
COMMENT ON COLUMN public.payout_requests.net_cents IS 'amount_cents - fee_cents. What actually lands in the Pros bank.';
