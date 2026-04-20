-- Fix create_booking_atomic: include required NOT NULL columns in the INSERT
-- Previous version was missing date, start_time, end_time, total_price which are
-- NOT NULL without defaults in public.bookings. Result: every booking creation
-- failed with "null value in column \"date\" violates not-null constraint",
-- surfaced to the app as 500 internal_error from create-booking-atomic.
--
-- Also:
--  - Honor service.payment_mode ('full' vs 'deposit')
--  - Respect service.deposit_type / deposit_value (percentage | fixed)
--    with fallback to legacy services.deposit_percentage
--  - Return remaining_amount and payment_mode so the Edge Function can
--    charge the correct amount via Stripe
--  - Add explicit guard on slot date/times

CREATE OR REPLACE FUNCTION public.create_booking_atomic(
    p_client_id uuid,
    p_slot_id uuid,
    p_service_id uuid,
    p_promo_code_id uuid DEFAULT NULL::uuid,
    p_booking_code text DEFAULT 'SPT-00000000'::text
)
RETURNS json
LANGUAGE plpgsql
AS $function$
DECLARE
    v_slot time_slots%ROWTYPE;
    v_service services%ROWTYPE;
    v_discount DECIMAL DEFAULT 0;
    v_total DECIMAL;
    v_deposit DECIMAL;
    v_remaining DECIMAL;
    v_booking_id UUID;
    v_currency TEXT;
    v_payment_mode TEXT;
BEGIN
    -- Lock the time slot row
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

    IF v_slot.date IS NULL OR v_slot.start_time IS NULL OR v_slot.end_time IS NULL THEN
        RAISE EXCEPTION 'slot_invalid_times';
    END IF;

    -- Load service
    SELECT * INTO v_service FROM services WHERE id = p_service_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'service_not_found';
    END IF;

    -- Promo code discount (if any)
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
    v_currency := COALESCE(v_service.currency, 'CAD');
    v_payment_mode := COALESCE(v_service.payment_mode, 'full');

    -- Deposit logic based on service configuration
    IF v_payment_mode = 'full' THEN
        v_deposit := v_total;
    ELSE
        IF v_service.deposit_type = 'fixed' AND v_service.deposit_value IS NOT NULL THEN
            v_deposit := LEAST(v_service.deposit_value, v_total);
        ELSIF v_service.deposit_type = 'percentage' AND v_service.deposit_value IS NOT NULL THEN
            v_deposit := ROUND(v_total * v_service.deposit_value / 100.0, 2);
        ELSE
            v_deposit := ROUND(v_total * COALESCE(v_service.deposit_percentage, 0.30), 2);
        END IF;
    END IF;

    v_remaining := GREATEST(v_total - v_deposit, 0);

    -- Lock the slot
    UPDATE time_slots
    SET is_available = false, locked_by = p_client_id
    WHERE id = p_slot_id;

    -- Create booking with ALL required NOT NULL columns
    INSERT INTO bookings (
        client_id, pro_id, service_id, time_slot_id,
        date, start_time, end_time,
        status,
        total_price, total_amount, deposit_amount, remaining_amount,
        currency, payment_mode,
        booking_code, promo_code_id
    ) VALUES (
        p_client_id, v_slot.pro_id, p_service_id, p_slot_id,
        v_slot.date, v_slot.start_time, v_slot.end_time,
        'pending_payment',
        v_total, v_total, v_deposit, v_remaining,
        v_currency, v_payment_mode,
        p_booking_code, p_promo_code_id
    )
    RETURNING id INTO v_booking_id;

    RETURN json_build_object(
        'booking_id', v_booking_id,
        'booking_code', p_booking_code,
        'total_amount', v_total,
        'deposit_amount', v_deposit,
        'remaining_amount', v_remaining,
        'payment_mode', v_payment_mode,
        'currency', v_currency
    );
END;
$function$;
