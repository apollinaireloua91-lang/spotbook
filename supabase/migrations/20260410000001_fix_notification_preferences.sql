-- Add missing notification preference columns
ALTER TABLE public.notification_preferences
  ADD COLUMN IF NOT EXISTS review_requests boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS waitlist_updates boolean DEFAULT true;
