-- Enable FULL replica identity on videos table so that Supabase Realtime
-- UPDATE events include the old row values (needed to detect status changes
-- e.g. non-approved → approved).
ALTER TABLE public.videos REPLICA IDENTITY FULL;
