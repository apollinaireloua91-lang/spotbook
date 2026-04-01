-- Fix bookings_status_check constraint to include all statuses used by Edge Functions.
-- cancel-booking uses 'cancelled_full_refund' and 'cancelled_no_refund'.
-- stripe-webhook-handler uses 'payment_failed'.
-- create-booking-atomic uses 'pending_payment'.
-- update-booking-status will use 'rejected'.
-- Without this fix, those Edge Function UPDATE calls silently fail.

ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;

ALTER TABLE bookings ADD CONSTRAINT bookings_status_check CHECK (
  status IN (
    'pending_payment',
    'pending',
    'confirmed',
    'completed',
    'cancelled',
    'cancelled_full_refund',
    'cancelled_no_refund',
    'payment_failed',
    'no_show',
    'rescheduled',
    'rejected'
  )
);
