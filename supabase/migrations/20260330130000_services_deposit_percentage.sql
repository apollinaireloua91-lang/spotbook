-- Add configurable deposit percentage per service.
-- Default 0.30 (30%) matches the previous hardcoded behaviour.
ALTER TABLE services
  ADD COLUMN IF NOT EXISTS deposit_percentage NUMERIC(3,2) NOT NULL DEFAULT 0.30;

-- Constraint: deposit must be between 10% and 100%.
ALTER TABLE services
  ADD CONSTRAINT chk_deposit_percentage
  CHECK (deposit_percentage >= 0.10 AND deposit_percentage <= 1.00);

-- Update create_booking_atomic to read deposit_percentage from the service row
-- instead of the hardcoded 0.30.
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
    -- Use the service's configurable deposit percentage (fallback 30%)
    v_deposit := ROUND(v_total * COALESCE(v_service.deposit_percentage, 0.30), 2);

    UPDATE time_slots
    SET is_available = false, locked_by = p_client_id
    WHERE id = p_slot_id;

    INSERT INTO bookings (
        client_id, pro_id, service_id, time_slot_id,
        status, total_amount, deposit_amount, currency,
        booking_code, promo_code_id
    ) VALUES (
        p_client_id, v_slot.pro_id, p_service_id, p_slot_id,
        'pending_payment', v_total, v_deposit, 'CAD',
        p_booking_code, p_promo_code_id
    )
    RETURNING id INTO v_booking_id;

    RETURN json_build_object(
        'booking_id', v_booking_id,
        'booking_code', p_booking_code,
        'total_amount', v_total,
        'deposit_amount', v_deposit
    );
END;
$$;
