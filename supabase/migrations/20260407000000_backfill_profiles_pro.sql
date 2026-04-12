-- ============================================================
-- BACKFILL: Create missing profiles_pro rows for existing Pro users
--
-- Problem: Users who signed up as 'pro' before the fix never got
--          a profiles_pro row, so Edge Functions reject them (403).
--
-- This inserts a row for every user with role='pro' who is missing
-- from profiles_pro. The trigger `sync_role_on_profiles_pro_insert`
-- will also ensure users.role stays 'pro'.
-- ============================================================

INSERT INTO public.profiles_pro (
  id,
  business_name,
  category,
  city,
  is_public,
  search_visible
)
SELECT
  u.id,
  COALESCE(NULLIF(u.full_name, ''), NULLIF(u.display_name, ''), 'Mon Business'),
  'Autre',
  COALESCE(u.city, ''),
  true,
  true
FROM public.users u
LEFT JOIN public.profiles_pro pp ON pp.id = u.id
WHERE u.role = 'pro'
  AND pp.id IS NULL;
