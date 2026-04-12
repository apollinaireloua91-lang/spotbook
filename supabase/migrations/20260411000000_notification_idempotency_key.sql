-- Add idempotency_key to notifications for webhook deduplication
-- Prevents duplicate notifications from Stripe webhook replays

ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS idempotency_key text;

-- Unique constraint for deduplication (NULL values are ignored by unique indexes)
CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_idempotency_key
  ON notifications (idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- Index for faster lookups on user notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_type_created
  ON notifications (user_id, type, created_at DESC)
  WHERE is_read = false;
