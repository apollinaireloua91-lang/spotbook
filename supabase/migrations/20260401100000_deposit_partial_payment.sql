-- Deposit / partial payment system.
-- Adds full vs deposit toggle, percentage-or-fixed deposit, remaining payment tracking.

-- ─── services: payment mode columns ─────────────────────────────────────────

ALTER TABLE services
  ADD COLUMN IF NOT EXISTS payment_mode TEXT NOT NULL DEFAULT 'full'
    CHECK (payment_mode IN ('full', 'deposit'));

ALTER TABLE services
  ADD COLUMN IF NOT EXISTS deposit_type TEXT
    CHECK (deposit_type IN ('percentage', 'fixed'));

ALTER TABLE services
  ADD COLUMN IF NOT EXISTS deposit_value DECIMAL(10,2);

-- Migrate existing deposit_percentage data to new columns.
UPDATE services SET
  payment_mode = CASE
    WHEN deposit_percentage >= 1.00 THEN 'full'
    ELSE 'deposit'
  END,
  deposit_type = CASE
    WHEN deposit_percentage < 1.00 THEN 'percentage'
    ELSE NULL
  END,
  deposit_value = CASE
    WHEN deposit_percentage < 1.00 THEN ROUND(deposit_percentage * 100, 2)
    ELSE NULL
  END
WHERE deposit_percentage IS NOT NULL;

-- ─── bookings: remaining payment columns ────────────────────────────────────

ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS payment_mode TEXT NOT NULL DEFAULT 'full';

ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS remaining_amount DECIMAL(10,2) NOT NULL DEFAULT 0;

ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS remaining_payment_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (remaining_payment_status IN ('pending', 'paid_on_site', 'waived'));

-- Migrate existing bookings.
UPDATE bookings SET
  payment_mode = CASE
    WHEN deposit_amount >= total_amount THEN 'full'
    ELSE 'deposit'
  END,
  remaining_amount = GREATEST(total_amount - deposit_amount, 0);

-- ─── Updated create_booking_atomic RPC ──────────────────────────────────────

CREATE OR REPLACE FUNCTION public.create_booking_atomic(
    p_client_id uuid,
    p_slot_id uuid,
    p_service_id uuid,
    p_promo_code_id uuid DEFAULT NULL,
    p_booking_code text DEFAULT 'SPT-00000000'
) RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    v_slot time_slots%ROWTYPE;
    v_service services%ROWTYPE;
    v_discount DECIMAL DEFAULT 0;
    v_total DECIMAL;
    v_deposit DECIMAL;
    v_remaining DECIMAL;
    v_payment_mode TEXT;
    v_booking_id UUID;
BEGIN
    SELECT * INTO v_slot
    FROM time_slots
    WHERE id = p_slot_id
    FOR UPDATE NOWAIT;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'slot_unavailable';
    END IF;

    IF NOT v_slot.is_available THEN
        RAISE EXCEPTION 'slot_unavailable';
    END IF;

    SELECT * INTO v_service FROM services WHERE id = p_service_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'service_not_found';
    END IF;

    IF p_promo_code_id IS NOT NULL THEN
        SELECT COALESCE(
            CASE discount_type
                WHEN 'percentage' THEN v_service.price * discount_value / 100
                WHEN 'fixed' THEN discount_value
                ELSE 0
            END, 0
        ) INTO v_discount
        FROM promo_codes
        WHERE id = p_promo_code_id
          AND is_active = true
          AND (expires_at IS NULL OR expires_at > NOW())
          AND (max_uses IS NULL OR uses_count < max_uses);

        IF FOUND AND p_promo_code_id IS NOT NULL THEN
            UPDATE promo_codes SET uses_count = uses_count + 1 WHERE id = p_promo_code_id;
        END IF;
    END IF;

    v_total := GREATEST(v_service.price - v_discount, 0);
    v_payment_mode := COALESCE(v_service.payment_mode, 'full');

    IF v_payment_mode = 'full' THEN
        v_deposit := v_total;
        v_remaining := 0;
    ELSIF v_service.deposit_type = 'percentage' THEN
        v_deposit := ROUND(v_total * COALESCE(v_service.deposit_value, 30) / 100, 2);
        v_remaining := v_total - v_deposit;
    ELSIF v_service.deposit_type = 'fixed' THEN
        v_deposit := LEAST(COALESCE(v_service.deposit_value, v_total), v_total);
        v_remaining := v_total - v_deposit;
    ELSE
        -- Fallback: use legacy deposit_percentage
        v_deposit := ROUND(v_total * COALESCE(v_service.deposit_percentage, 0.30), 2);
        v_remaining := v_total - v_deposit;
        v_payment_mode := 'deposit';
    END IF;

    UPDATE time_slots
    SET is_available = false, locked_by = p_client_id
    WHERE id = p_slot_id;

    INSERT INTO bookings (
        client_id, pro_id, service_id, time_slot_id,
        status, total_amount, deposit_amount, remaining_amount,
        payment_mode, remaining_payment_status,
        currency, booking_code, promo_code_id
    ) VALUES (
        p_client_id, v_slot.pro_id, p_service_id, p_slot_id,
        'pending_payment', v_total, v_deposit, v_remaining,
        v_payment_mode, 'pending',
        'CAD', p_booking_code, p_promo_code_id
    )
    RETURNING id INTO v_booking_id;

    RETURN json_build_object(
        'booking_id', v_booking_id,
        'booking_code', p_booking_code,
        'total_amount', v_total,
        'deposit_amount', v_deposit,
        'remaining_amount', v_remaining,
        'payment_mode', v_payment_mode
    );
END;
$$;
