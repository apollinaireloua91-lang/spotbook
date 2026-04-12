-- Atomic reschedule function: frees old slot, reserves new slot, updates booking
-- in a single transaction. Prevents data corruption from partial failures.

CREATE OR REPLACE FUNCTION reschedule_booking_atomic(
  p_booking_id UUID,
  p_old_slot_id UUID,
  p_new_slot_id UUID,
  p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_booking RECORD;
  v_new_slot RECORD;
BEGIN
  -- Verify booking exists and caller is a participant
  SELECT id, client_id, pro_id, status, time_slot_id
    INTO v_booking
    FROM bookings
   WHERE id = p_booking_id
     FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'booking_not_found');
  END IF;

  IF v_booking.client_id != p_user_id AND v_booking.pro_id != p_user_id THEN
    RETURN jsonb_build_object('error', 'forbidden');
  END IF;

  IF v_booking.status NOT IN ('confirmed', 'pending') THEN
    RETURN jsonb_build_object('error', 'booking_not_reschedulable', 'status', v_booking.status);
  END IF;

  IF v_booking.time_slot_id != p_old_slot_id THEN
    RETURN jsonb_build_object('error', 'old_slot_mismatch');
  END IF;

  -- Lock and verify new slot is available
  SELECT id, is_available
    INTO v_new_slot
    FROM time_slots
   WHERE id = p_new_slot_id
     FOR UPDATE NOWAIT;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'new_slot_not_found');
  END IF;

  IF NOT v_new_slot.is_available THEN
    RETURN jsonb_build_object('error', 'new_slot_not_available');
  END IF;

  -- Free old slot
  UPDATE time_slots
     SET is_available = true, locked_by = NULL
   WHERE id = p_old_slot_id;

  -- Reserve new slot
  UPDATE time_slots
     SET is_available = false, locked_by = p_user_id
   WHERE id = p_new_slot_id;

  -- Update booking
  UPDATE bookings
     SET time_slot_id = p_new_slot_id,
         status = 'rescheduled'
   WHERE id = p_booking_id;

  -- Audit log
  PERFORM log_audit_action(
    p_user_id,
    'booking_rescheduled',
    'booking',
    p_booking_id,
    jsonb_build_object('old_slot', p_old_slot_id, 'new_slot', p_new_slot_id)
  );

  RETURN jsonb_build_object('success', true, 'new_slot_id', p_new_slot_id);
END;
$$;
