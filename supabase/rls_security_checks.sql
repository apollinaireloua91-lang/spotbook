-- ============================================================
-- SPOTBOOK — RLS Security Verification Queries
-- Run these as an authenticated CLIENT user in Supabase SQL Editor
-- Every query should return 0 rows or an RLS error.
-- ============================================================

-- TEST 1: Client cannot see another pro's bookings
-- Expected: 0 rows (RLS filters to client_id = auth.uid() OR pro_id = auth.uid())
SELECT * FROM bookings WHERE pro_id = '00000000-0000-0000-0000-000000000001';

-- TEST 2: Client only sees own audit logs
-- Expected: only rows where user_id = auth.uid()
SELECT * FROM audit_logs;

-- TEST 3: Client cannot modify commission_rate
-- Expected: RLS error or no rows updated (blocked by block_commission_update policy)
UPDATE profiles_pro SET commission_rate = 0 WHERE id = auth.uid();

-- TEST 4: access_token column revoked from authenticated role
-- Expected: error or NULL values (column grant revoked)
SELECT access_token FROM social_connections;

-- TEST 5: Client cannot see other users' tickets
-- Expected: 0 rows (RLS filters to user_id = auth.uid())
SELECT * FROM tickets WHERE user_id = '00000000-0000-0000-0000-000000000002';

-- TEST 6: Client cannot read messages from other conversations
-- Expected: 0 rows (RLS checks conversation participant)
SELECT * FROM messages WHERE conversation_id = '00000000-0000-0000-0000-000000000003';

-- TEST 7: Client cannot insert a booking for another user
-- Expected: RLS error
INSERT INTO bookings (client_id, pro_id, status)
VALUES ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000005', 'pending_payment');

-- TEST 8: Client cannot read kyc-documents bucket
-- (Verify in Dashboard → Storage → kyc-documents: bucket is NOT public)

-- TEST 9: Videos feed only shows approved
-- Expected: only rows where status = 'approved' (or own videos for pro)
SELECT id, status FROM videos WHERE status != 'approved';

-- TEST 10: Notification preferences are user-scoped
-- Expected: only own row
SELECT * FROM notification_preferences;

-- ============================================================
-- Summary: If ANY test returns unexpected data, fix before P9.
-- ============================================================
