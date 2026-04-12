-- ============================================================
-- SECURITY HARDENING MIGRATION
-- Fixes: C1 (role escalation), C2 (profiles_pro stats tampering),
--        C3 (users PII exposure), C4 (audit log injection),
--        H1 (draft events exposed), H2 (reviews tampering),
--        H4 (anon grants), H5 (time_slots leaks locked_by)
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- C1: USERS — Prevent self-promotion (role, is_verified, is_top_pro, stripe fields)
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "users_own_update" ON users;
DROP POLICY IF EXISTS "Users: update propre" ON users;

CREATE POLICY "users_own_update" ON users
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role IS NOT DISTINCT FROM (SELECT u.role FROM users u WHERE u.id = auth.uid())
    AND is_verified IS NOT DISTINCT FROM (SELECT u.is_verified FROM users u WHERE u.id = auth.uid())
    AND is_top_pro IS NOT DISTINCT FROM (SELECT u.is_top_pro FROM users u WHERE u.id = auth.uid())
    AND stripe_account_id IS NOT DISTINCT FROM (SELECT u.stripe_account_id FROM users u WHERE u.id = auth.uid())
    AND stripe_onboarded IS NOT DISTINCT FROM (SELECT u.stripe_onboarded FROM users u WHERE u.id = auth.uid())
  );

-- ────────────────────────────────────────────────────────────
-- C2: PROFILES_PRO — Lock server-managed fields
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "block_commission_update" ON profiles_pro;
DROP POLICY IF EXISTS "Profiles pro: update propre" ON profiles_pro;

CREATE POLICY "profiles_pro_own_update" ON profiles_pro
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND commission_rate IS NOT DISTINCT FROM (SELECT p.commission_rate FROM profiles_pro p WHERE p.id = auth.uid())
    AND total_revenue IS NOT DISTINCT FROM (SELECT p.total_revenue FROM profiles_pro p WHERE p.id = auth.uid())
    AND total_bookings IS NOT DISTINCT FROM (SELECT p.total_bookings FROM profiles_pro p WHERE p.id = auth.uid())
    AND rating_average IS NOT DISTINCT FROM (SELECT p.rating_average FROM profiles_pro p WHERE p.id = auth.uid())
    AND rating_count IS NOT DISTINCT FROM (SELECT p.rating_count FROM profiles_pro p WHERE p.id = auth.uid())
    AND is_top_pro IS NOT DISTINCT FROM (SELECT p.is_top_pro FROM profiles_pro p WHERE p.id = auth.uid())
    AND kyc_status IS NOT DISTINCT FROM (SELECT p.kyc_status FROM profiles_pro p WHERE p.id = auth.uid())
    AND stripe_account_id IS NOT DISTINCT FROM (SELECT p.stripe_account_id FROM profiles_pro p WHERE p.id = auth.uid())
    AND stripe_onboarded IS NOT DISTINCT FROM (SELECT p.stripe_onboarded FROM profiles_pro p WHERE p.id = auth.uid())
    AND stripe_payout_last4 IS NOT DISTINCT FROM (SELECT p.stripe_payout_last4 FROM profiles_pro p WHERE p.id = auth.uid())
  );

-- ────────────────────────────────────────────────────────────
-- C3: USERS — Restrict public read to non-sensitive columns only
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "users_public_read" ON users;
DROP POLICY IF EXISTS "Users: lecture" ON users;

-- Own row: full access
CREATE POLICY "users_own_read" ON users
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

-- Other users: only public fields via a view is ideal,
-- but as a quick RLS fix, we rely on column-level grants.
-- First revoke blanket access, then grant safe columns.
REVOKE SELECT ON TABLE public.users FROM authenticated;
REVOKE SELECT ON TABLE public.users FROM anon;

GRANT SELECT (
  id, full_name, display_name, username, avatar_url, cover_url,
  bio, city, role, is_verified, is_top_pro, followers_count,
  following_count, created_at
) ON TABLE public.users TO authenticated;

-- Re-grant full row to service_role (Edge Functions)
GRANT ALL ON TABLE public.users TO service_role;

-- ────────────────────────────────────────────────────────────
-- C4: AUDIT_LOGS — Remove overly permissive insert policy
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "service_insert_logs" ON audit_logs;

-- ────────────────────────────────────────────────────────────
-- H1: EVENTS — Fix draft/cancelled events visible to public
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "events_public_read" ON events;
DROP POLICY IF EXISTS "Events: lecture" ON events;

CREATE POLICY "events_public_read" ON events
  FOR SELECT TO authenticated
  USING (
    (is_active = true AND status = 'published')
    OR auth.uid() = pro_id
  );

-- ────────────────────────────────────────────────────────────
-- H2: REVIEWS — Restrict client update to safe columns only
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "reviews_update_as_client" ON reviews;

CREATE POLICY "reviews_update_as_client" ON reviews
  FOR UPDATE TO authenticated
  USING (auth.uid() = client_id)
  WITH CHECK (
    auth.uid() = client_id
    AND pro_id IS NOT DISTINCT FROM (SELECT r.pro_id FROM reviews r WHERE r.id = reviews.id)
    AND booking_id IS NOT DISTINCT FROM (SELECT r.booking_id FROM reviews r WHERE r.id = reviews.id)
    AND client_id IS NOT DISTINCT FROM (SELECT r.client_id FROM reviews r WHERE r.id = reviews.id)
  );

-- ────────────────────────────────────────────────────────────
-- H4: Revoke GRANT ALL from anon on sensitive tables
-- ────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.bookings FROM anon;
REVOKE ALL ON TABLE public.messages FROM anon;
REVOKE ALL ON TABLE public.conversations FROM anon;
REVOKE ALL ON TABLE public.notifications FROM anon;
REVOKE ALL ON TABLE public.notification_preferences FROM anon;
REVOKE ALL ON TABLE public.profiles_pro FROM anon;
REVOKE ALL ON TABLE public.reviews FROM anon;
REVOKE ALL ON TABLE public.reports FROM anon;
REVOKE ALL ON TABLE public.social_connections FROM anon;
REVOKE ALL ON TABLE public.pro_subscriptions FROM anon;
REVOKE ALL ON TABLE public.rate_limit_counters FROM anon;
REVOKE ALL ON TABLE public.rate_limit_counters FROM authenticated;
REVOKE ALL ON TABLE public.audit_logs FROM anon;
REVOKE ALL ON TABLE public.referrals FROM anon;
REVOKE ALL ON TABLE public.blocks FROM anon;
REVOKE ALL ON TABLE public.favorites FROM anon;

-- ────────────────────────────────────────────────────────────
-- H3: SOCIAL_CONNECTIONS — Revoke token column access
-- ────────────────────────────────────────────────────────────
REVOKE ALL ON TABLE public.social_connections FROM authenticated;
GRANT SELECT (id, pro_id, platform, handle, followers_count, last_synced_at, updated_at)
  ON TABLE public.social_connections TO authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.social_connections TO authenticated;

-- ────────────────────────────────────────────────────────────
-- H5: TIME_SLOTS — Don't leak locked_by to other users
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "time_slots_public_read" ON time_slots;

CREATE POLICY "time_slots_public_read" ON time_slots
  FOR SELECT TO authenticated
  USING (
    is_available = true
    OR pro_id = auth.uid()
    OR locked_by = auth.uid()
  );

-- ────────────────────────────────────────────────────────────
-- STORAGE: Set file type and size restrictions
-- ────────────────────────────────────────────────────────────
UPDATE storage.buckets
SET file_size_limit = 5242880,  -- 5MB
    allowed_mime_types = ARRAY['image/png', 'image/jpeg', 'image/webp']
WHERE id = 'avatars';

UPDATE storage.buckets
SET file_size_limit = 5242880,  -- 5MB
    allowed_mime_types = ARRAY['image/png', 'image/jpeg', 'image/webp']
WHERE id = 'covers';

UPDATE storage.buckets
SET file_size_limit = 10485760,  -- 10MB
    allowed_mime_types = ARRAY['image/png', 'image/jpeg', 'image/webp']
WHERE id = 'event-covers';

UPDATE storage.buckets
SET file_size_limit = 10485760,  -- 10MB
    allowed_mime_types = ARRAY['image/png', 'image/jpeg', 'image/webp', 'video/mp4', 'video/quicktime']
WHERE id = 'event-media';

UPDATE storage.buckets
SET file_size_limit = 5242880,  -- 5MB
    allowed_mime_types = ARRAY['image/png', 'image/jpeg', 'image/webp']
WHERE id = 'chat-images';
