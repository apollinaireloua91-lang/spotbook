-- =====================================================
-- NOT NULL constraints on critical columns
-- =====================================================

-- Bookings: status must never be NULL
UPDATE public.bookings SET status = 'pending_payment' WHERE status IS NULL;
ALTER TABLE public.bookings ALTER COLUMN status SET NOT NULL;
ALTER TABLE public.bookings ALTER COLUMN status SET DEFAULT 'pending_payment';

-- Bookings: amounts must never be NULL
UPDATE public.bookings SET total_amount = 0 WHERE total_amount IS NULL;
ALTER TABLE public.bookings ALTER COLUMN total_amount SET NOT NULL;
ALTER TABLE public.bookings ALTER COLUMN total_amount SET DEFAULT 0;

UPDATE public.bookings SET deposit_amount = 0 WHERE deposit_amount IS NULL;
ALTER TABLE public.bookings ALTER COLUMN deposit_amount SET NOT NULL;
ALTER TABLE public.bookings ALTER COLUMN deposit_amount SET DEFAULT 0;

-- Event tickets: status must never be NULL
UPDATE public.tickets SET status = 'valid' WHERE status IS NULL;
ALTER TABLE public.tickets ALTER COLUMN status SET NOT NULL;
ALTER TABLE public.tickets ALTER COLUMN status SET DEFAULT 'valid';

-- Confirmed bookings MUST have a Stripe payment intent
ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_pi_on_confirmed;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_pi_on_confirmed
  CHECK ((status != 'confirmed') OR (stripe_payment_intent_id IS NOT NULL));

-- =====================================================
-- Performance indexes
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_bookings_client_status ON public.bookings(client_id, status);
CREATE INDEX IF NOT EXISTS idx_bookings_pro_status ON public.bookings(pro_id, status);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_videos_pro_status ON public.videos(pro_id, status);
CREATE INDEX IF NOT EXISTS idx_videos_status_created ON public.videos(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows(following_id);
CREATE INDEX IF NOT EXISTS idx_tickets_user ON public.tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_event ON public.tickets(event_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at DESC);
