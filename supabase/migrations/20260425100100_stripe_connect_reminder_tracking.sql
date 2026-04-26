-- ═══════════════════════════════════════════════════════════════════════════════
-- STRIPE CONNECT REMINDER TRACKING — column to dedupe nudge emails
-- ═══════════════════════════════════════════════════════════════════════════════
-- The `stripe-connect-reminder` cron (paired with this migration) emails Pros
-- who created a Stripe Connect account but never finished onboarding. Without
-- a `last_sent_at` timestamp, the cron would re-spam every Pro on every run.
--
-- Cadence rule (enforced in the Edge Function, not in SQL):
--   - First reminder: 7 days after Pro created their account, if not onboarded
--   - Subsequent reminders: every 7 days, capped at 4 total reminders
--   - Stops re-sending once `stripe_onboarded = true`

ALTER TABLE profiles_pro
  ADD COLUMN IF NOT EXISTS stripe_connect_reminder_sent_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS stripe_connect_reminder_count INTEGER NOT NULL DEFAULT 0;

-- Cap to keep the histogram sane (UI/analytics).
ALTER TABLE profiles_pro
  DROP CONSTRAINT IF EXISTS profiles_pro_stripe_connect_reminder_count_check;
ALTER TABLE profiles_pro
  ADD CONSTRAINT profiles_pro_stripe_connect_reminder_count_check
  CHECK (stripe_connect_reminder_count >= 0 AND stripe_connect_reminder_count <= 10);

-- Index for the cron scan: cheap to skip already-onboarded + recently-pinged Pros.
CREATE INDEX IF NOT EXISTS idx_profiles_pro_stripe_reminder_due
  ON profiles_pro (stripe_connect_reminder_sent_at)
  WHERE stripe_onboarded = false AND stripe_account_id IS NOT NULL;
