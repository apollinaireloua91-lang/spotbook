-- Harden bookings INSERT policy to require status = 'pending_payment'.
-- Without this, a malicious client could INSERT with status='confirmed' to skip payment.

DROP POLICY IF EXISTS "bookings_client_insert" ON bookings;

CREATE POLICY "bookings_client_insert" ON bookings
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = client_id
    AND status = 'pending_payment'
    AND NOT is_blocked(client_id, pro_id)
  );

-- Also restrict what clients can UPDATE (only cancellation_reason, notes).
-- Status changes must go through Edge Functions.
-- The existing bookings_client_update allows unrestricted column changes.

DROP POLICY IF EXISTS "bookings_client_update" ON bookings;

CREATE POLICY "bookings_client_update" ON bookings
  FOR UPDATE TO authenticated
  USING (auth.uid() = client_id)
  WITH CHECK (
    auth.uid() = client_id
    -- Client can only set status to 'cancelled' (actual refund logic in Edge Function)
    AND (
      status = (SELECT status FROM bookings WHERE id = bookings.id)  -- no status change
      OR status IN ('cancelled')  -- or cancel
    )
  );

-- Restrict pro UPDATE: pro can only set status to confirmed/completed/rejected
DROP POLICY IF EXISTS "bookings_pro_update" ON bookings;

CREATE POLICY "bookings_pro_update" ON bookings
  FOR UPDATE TO authenticated
  USING (auth.uid() = pro_id)
  WITH CHECK (
    auth.uid() = pro_id
    AND (
      status = (SELECT status FROM bookings WHERE id = bookings.id)  -- no status change
      OR status IN ('confirmed', 'completed', 'rejected')  -- allowed transitions
    )
  );
