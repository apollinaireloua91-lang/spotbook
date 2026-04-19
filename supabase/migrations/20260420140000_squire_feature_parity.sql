-- ============================================================================
-- Squire feature parity — priorities #2 to #13 schema
-- ============================================================================
-- Consolidated migration adding all tables, columns, and RLS policies for:
--   #2  Availability enhancements (buffer, lunch, max concurrent)
--   #3  Tipping
--   #4  Smart reminders (columns already exist — just indexes)
--   #5  Waitlist
--   #6  Walk-in queue
--   #7  Recurring appointments
--   #8  Client notes + CRM
--   #9  Loyalty points + programs
--   #10 Referrals
--   #11 Group bookings
--   #12 Digital receipts (receipts table)
--   #13 Enhanced reviews (multi-criteria)
--
-- All writes on booking-derived tables (tips, loyalty_points_ledger, receipts)
-- go via service_role (edge functions) to prevent tampering. Reads are RLS-
-- scoped to the participant (client or pro).
-- ============================================================================

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #2 — Availability enhancements                                            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

ALTER TABLE public.availability_rules
  ADD COLUMN IF NOT EXISTS lunch_break_start TIME,
  ADD COLUMN IF NOT EXISTS lunch_break_end TIME,
  ADD COLUMN IF NOT EXISTS buffer_minutes INTEGER NOT NULL DEFAULT 0
    CHECK (buffer_minutes >= 0 AND buffer_minutes <= 60),
  ADD COLUMN IF NOT EXISTS max_concurrent_bookings INTEGER NOT NULL DEFAULT 1
    CHECK (max_concurrent_bookings >= 1 AND max_concurrent_bookings <= 20);

-- Per-day exceptions (vacation, special hours, closed)
CREATE TABLE IF NOT EXISTS public.availability_exceptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  exception_date DATE NOT NULL,
  is_closed BOOLEAN NOT NULL DEFAULT false,
  custom_start TIME,
  custom_end TIME,
  note TEXT CHECK (note IS NULL OR length(note) <= 200),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (pro_id, exception_date)
);

CREATE INDEX IF NOT EXISTS idx_availability_exceptions_pro_date
  ON public.availability_exceptions (pro_id, exception_date);

ALTER TABLE public.availability_exceptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "availability_exceptions_public_read"
  ON public.availability_exceptions FOR SELECT
  USING (true);

CREATE POLICY "availability_exceptions_pro_write"
  ON public.availability_exceptions FOR ALL
  USING (pro_id = auth.uid())
  WITH CHECK (pro_id = auth.uid());


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #3 — Tipping                                                              ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.tips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE RESTRICT,
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  pro_id UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  amount_cents INTEGER NOT NULL CHECK (amount_cents >= 100 AND amount_cents <= 50000),
  currency TEXT NOT NULL DEFAULT 'CAD',
  stripe_payment_intent_id TEXT UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_tips_booking ON public.tips (booking_id);
CREATE INDEX IF NOT EXISTS idx_tips_pro ON public.tips (pro_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tips_client ON public.tips (client_id, created_at DESC);

ALTER TABLE public.tips ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tips_participant_read"
  ON public.tips FOR SELECT
  USING (client_id = auth.uid() OR pro_id = auth.uid());

CREATE POLICY "tips_service_role_write"
  ON public.tips FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #4 — Smart reminders (indexes only — columns already exist on bookings)  ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- Add 30min reminder flag + pro-side reminder
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS reminder_m30_sent TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reminder_pro_m30_sent TIMESTAMPTZ;

-- Partial index for the reminder cron — only scans bookings that haven't
-- received each reminder yet. Massive speedup as the table grows.
CREATE INDEX IF NOT EXISTS idx_bookings_reminder_24h
  ON public.bookings (date, start_time)
  WHERE status = 'confirmed' AND reminder_j1_sent IS NULL;

CREATE INDEX IF NOT EXISTS idx_bookings_reminder_2h
  ON public.bookings (date, start_time)
  WHERE status = 'confirmed' AND reminder_h2_sent IS NULL;

CREATE INDEX IF NOT EXISTS idx_bookings_reminder_30min
  ON public.bookings (date, start_time)
  WHERE status = 'confirmed' AND reminder_m30_sent IS NULL;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #5 — Waitlist                                                             ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- Note: existing `waitlist` table in remote_schema (event-focused). Create a
-- booking-oriented one with a different name.

CREATE TABLE IF NOT EXISTS public.booking_waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  pro_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  preferred_date DATE NOT NULL,
  preferred_time_start TIME,
  preferred_time_end TIME,
  status TEXT NOT NULL DEFAULT 'waiting'
    CHECK (status IN ('waiting', 'notified', 'booked', 'expired', 'cancelled')),
  notified_at TIMESTAMPTZ,
  /* The client has 30 min to confirm after being notified. */
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_booking_waitlist_pro_status
  ON public.booking_waitlist (pro_id, status);
CREATE INDEX IF NOT EXISTS idx_booking_waitlist_client
  ON public.booking_waitlist (client_id, status);
CREATE INDEX IF NOT EXISTS idx_booking_waitlist_queue
  ON public.booking_waitlist (pro_id, preferred_date, created_at)
  WHERE status = 'waiting';

ALTER TABLE public.booking_waitlist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "booking_waitlist_client_read_own"
  ON public.booking_waitlist FOR SELECT
  USING (client_id = auth.uid() OR pro_id = auth.uid());

CREATE POLICY "booking_waitlist_client_insert_own"
  ON public.booking_waitlist FOR INSERT
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "booking_waitlist_client_update_own"
  ON public.booking_waitlist FOR UPDATE
  USING (client_id = auth.uid())
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "booking_waitlist_service_role"
  ON public.booking_waitlist FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #6 — Walk-in queue                                                        ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.walk_in_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  client_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  client_name TEXT NOT NULL CHECK (length(trim(client_name)) BETWEEN 1 AND 100),
  client_phone TEXT CHECK (client_phone IS NULL OR length(client_phone) <= 30),
  service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  position INTEGER NOT NULL CHECK (position >= 1),
  status TEXT NOT NULL DEFAULT 'waiting'
    CHECK (status IN ('waiting', 'in_service', 'completed', 'no_show', 'cancelled')),
  estimated_wait_minutes INTEGER CHECK (estimated_wait_minutes IS NULL OR estimated_wait_minutes >= 0),
  checked_in_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_walk_in_pro_status
  ON public.walk_in_queue (pro_id, status, position);
CREATE INDEX IF NOT EXISTS idx_walk_in_client
  ON public.walk_in_queue (client_id) WHERE client_id IS NOT NULL;

ALTER TABLE public.walk_in_queue ENABLE ROW LEVEL SECURITY;

-- Pro manages their queue; client (if linked) can see their own row
CREATE POLICY "walk_in_pro_full_access"
  ON public.walk_in_queue FOR ALL
  USING (pro_id = auth.uid())
  WITH CHECK (pro_id = auth.uid());

CREATE POLICY "walk_in_client_read_own"
  ON public.walk_in_queue FOR SELECT
  USING (client_id = auth.uid());


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #7 — Recurring appointments                                               ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.recurring_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  pro_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL,
  frequency_weeks INTEGER NOT NULL DEFAULT 2
    CHECK (frequency_weeks IN (1, 2, 3, 4)),
  is_active BOOLEAN NOT NULL DEFAULT true,
  next_booking_date DATE NOT NULL,
  last_generated_booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  cancelled_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_recurring_bookings_client
  ON public.recurring_bookings (client_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_recurring_bookings_pro
  ON public.recurring_bookings (pro_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_recurring_bookings_next
  ON public.recurring_bookings (next_booking_date)
  WHERE is_active = true;

ALTER TABLE public.recurring_bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "recurring_bookings_participant_read"
  ON public.recurring_bookings FOR SELECT
  USING (client_id = auth.uid() OR pro_id = auth.uid());

CREATE POLICY "recurring_bookings_client_manage"
  ON public.recurring_bookings FOR ALL
  USING (client_id = auth.uid())
  WITH CHECK (client_id = auth.uid());

CREATE POLICY "recurring_bookings_service_role"
  ON public.recurring_bookings FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #8 — Client notes (CRM)                                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.client_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  note TEXT NOT NULL CHECK (length(trim(note)) BETWEEN 1 AND 2000),
  tags TEXT[] NOT NULL DEFAULT '{}',
  is_private BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (pro_id, client_id)  -- one note row per (pro, client); can be edited
);

CREATE INDEX IF NOT EXISTS idx_client_notes_pro
  ON public.client_notes (pro_id, updated_at DESC);

ALTER TABLE public.client_notes ENABLE ROW LEVEL SECURITY;

-- CRITICAL: client_notes are PRIVATE to the pro. Clients never see them.
CREATE POLICY "client_notes_pro_only"
  ON public.client_notes FOR ALL
  USING (pro_id = auth.uid())
  WITH CHECK (pro_id = auth.uid());


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #9 — Loyalty programs + points ledger                                     ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.loyalty_programs (
  pro_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'Programme fidélité'
    CHECK (length(trim(name)) BETWEEN 2 AND 80),
  points_per_dollar INTEGER NOT NULL DEFAULT 1
    CHECK (points_per_dollar BETWEEN 1 AND 10),
  points_for_free_service INTEGER NOT NULL DEFAULT 100
    CHECK (points_for_free_service BETWEEN 10 AND 10000),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.loyalty_programs ENABLE ROW LEVEL SECURITY;

-- Public read of active programs (clients browse a pro's loyalty rules)
CREATE POLICY "loyalty_programs_public_read_active"
  ON public.loyalty_programs FOR SELECT
  USING (is_active = true);

CREATE POLICY "loyalty_programs_pro_manage"
  ON public.loyalty_programs FOR ALL
  USING (pro_id = auth.uid())
  WITH CHECK (pro_id = auth.uid());

-- Points ledger — append-only per convention. Never update or delete rows.
CREATE TABLE IF NOT EXISTS public.loyalty_points_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  pro_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
  points INTEGER NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('earned', 'redeemed', 'expired', 'bonus', 'adjustment')),
  description TEXT CHECK (description IS NULL OR length(description) <= 200),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_loyalty_ledger_client_pro
  ON public.loyalty_points_ledger (client_id, pro_id, created_at DESC);

ALTER TABLE public.loyalty_points_ledger ENABLE ROW LEVEL SECURITY;

CREATE POLICY "loyalty_ledger_participant_read"
  ON public.loyalty_points_ledger FOR SELECT
  USING (client_id = auth.uid() OR pro_id = auth.uid());

-- Writes via service_role only (triggered by booking completion / redemption)
CREATE POLICY "loyalty_ledger_service_role_write"
  ON public.loyalty_points_ledger FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- Convenience view: current balance per (client, pro)
CREATE OR REPLACE VIEW public.loyalty_balances AS
SELECT
  client_id,
  pro_id,
  COALESCE(SUM(points), 0)::integer AS balance
FROM public.loyalty_points_ledger
WHERE type != 'expired'
GROUP BY client_id, pro_id;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #10 — Referrals                                                           ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- Existing `referrals` table uses different column names. Create a new
-- `user_referrals` table with the Squire-style mechanics (referral code,
-- reward credits).

CREATE TABLE IF NOT EXISTS public.user_referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  referred_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  referral_code TEXT NOT NULL UNIQUE CHECK (length(referral_code) BETWEEN 4 AND 20),
  reward_cents INTEGER NOT NULL DEFAULT 1000 CHECK (reward_cents >= 0),
  currency TEXT NOT NULL DEFAULT 'CAD',
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'expired', 'revoked')),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT (now() + interval '180 days')
);

CREATE INDEX IF NOT EXISTS idx_user_referrals_referrer
  ON public.user_referrals (referrer_id, status);
CREATE INDEX IF NOT EXISTS idx_user_referrals_referred
  ON public.user_referrals (referred_id) WHERE referred_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_referrals_code_active
  ON public.user_referrals (referral_code) WHERE status = 'pending';

ALTER TABLE public.user_referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_referrals_read_own"
  ON public.user_referrals FOR SELECT
  USING (referrer_id = auth.uid() OR referred_id = auth.uid());

CREATE POLICY "user_referrals_service_role"
  ON public.user_referrals FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #11 — Group bookings                                                      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.booking_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  group_name TEXT CHECK (group_name IS NULL OR length(group_name) <= 80),
  total_members INTEGER NOT NULL CHECK (total_members >= 1 AND total_members <= 20),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.booking_group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.booking_groups(id) ON DELETE CASCADE,
  member_booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
  member_name TEXT NOT NULL CHECK (length(trim(member_name)) BETWEEN 1 AND 80),
  service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_booking_groups_primary
  ON public.booking_groups (primary_booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_group_members_group
  ON public.booking_group_members (group_id, sort_order);

ALTER TABLE public.booking_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "booking_groups_participant_read"
  ON public.booking_groups FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = primary_booking_id
        AND (b.client_id = auth.uid() OR b.pro_id = auth.uid())
    )
  );

CREATE POLICY "booking_groups_service_role"
  ON public.booking_groups FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "booking_group_members_participant_read"
  ON public.booking_group_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.booking_groups g
      JOIN public.bookings b ON b.id = g.primary_booking_id
      WHERE g.id = group_id
        AND (b.client_id = auth.uid() OR b.pro_id = auth.uid())
    )
  );

CREATE POLICY "booking_group_members_service_role"
  ON public.booking_group_members FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #12 — Digital receipts                                                    ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL UNIQUE REFERENCES public.bookings(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES public.users(id),
  pro_id UUID NOT NULL REFERENCES public.users(id),
  receipt_number TEXT NOT NULL UNIQUE,
  subtotal_cents INTEGER NOT NULL CHECK (subtotal_cents >= 0),
  addons_cents INTEGER NOT NULL DEFAULT 0 CHECK (addons_cents >= 0),
  promo_discount_cents INTEGER NOT NULL DEFAULT 0 CHECK (promo_discount_cents >= 0),
  loyalty_discount_cents INTEGER NOT NULL DEFAULT 0 CHECK (loyalty_discount_cents >= 0),
  tip_cents INTEGER NOT NULL DEFAULT 0 CHECK (tip_cents >= 0),
  tax_cents INTEGER NOT NULL DEFAULT 0 CHECK (tax_cents >= 0),
  total_cents INTEGER NOT NULL CHECK (total_cents >= 0),
  currency TEXT NOT NULL DEFAULT 'CAD',
  payment_method TEXT CHECK (payment_method IS NULL OR length(payment_method) <= 50),
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  emailed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_receipts_client
  ON public.receipts (client_id, generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_receipts_pro
  ON public.receipts (pro_id, generated_at DESC);

ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "receipts_participant_read"
  ON public.receipts FOR SELECT
  USING (client_id = auth.uid() OR pro_id = auth.uid());

CREATE POLICY "receipts_service_role_write"
  ON public.receipts FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ #13 — Enhanced reviews (multi-criteria)                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS punctuality_rating INTEGER
    CHECK (punctuality_rating IS NULL OR (punctuality_rating >= 1 AND punctuality_rating <= 5)),
  ADD COLUMN IF NOT EXISTS quality_rating INTEGER
    CHECK (quality_rating IS NULL OR (quality_rating >= 1 AND quality_rating <= 5)),
  ADD COLUMN IF NOT EXISTS ambiance_rating INTEGER
    CHECK (ambiance_rating IS NULL OR (ambiance_rating >= 1 AND ambiance_rating <= 5)),
  ADD COLUMN IF NOT EXISTS would_recommend BOOLEAN;


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ Triggers: updated_at for tables that need it                              ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION public._set_updated_at_generic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_client_notes_updated_at ON public.client_notes;
CREATE TRIGGER trg_client_notes_updated_at
  BEFORE UPDATE ON public.client_notes
  FOR EACH ROW EXECUTE FUNCTION public._set_updated_at_generic();

DROP TRIGGER IF EXISTS trg_loyalty_programs_updated_at ON public.loyalty_programs;
CREATE TRIGGER trg_loyalty_programs_updated_at
  BEFORE UPDATE ON public.loyalty_programs
  FOR EACH ROW EXECUTE FUNCTION public._set_updated_at_generic();


-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║ Receipt number generator                                                  ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
-- Format: SPB-YYYY-XXXXX (sequential per year)

CREATE SEQUENCE IF NOT EXISTS public.receipt_number_seq START 1;

CREATE OR REPLACE FUNCTION public.generate_receipt_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  yr TEXT;
  n BIGINT;
BEGIN
  yr := to_char(now(), 'YYYY');
  n := nextval('public.receipt_number_seq');
  RETURN 'SPB-' || yr || '-' || lpad(n::text, 5, '0');
END;
$$;


COMMENT ON TABLE public.booking_waitlist IS 'Priority #5 — clients waiting for a slot to open up. Status-driven with 30-min confirm window.';
COMMENT ON TABLE public.walk_in_queue IS 'Priority #6 — pro-managed live queue for drop-in clients.';
COMMENT ON TABLE public.recurring_bookings IS 'Priority #7 — scheduled recurring appointments. Generator cron creates individual bookings from these templates.';
COMMENT ON TABLE public.client_notes IS 'Priority #8 — PRIVATE pro notes about clients. Never visible to clients.';
COMMENT ON TABLE public.loyalty_programs IS 'Priority #9 — per-pro loyalty rules. Points earned per $ spent; redeemable for a free service at configurable thresholds.';
COMMENT ON TABLE public.loyalty_points_ledger IS 'Priority #9 — append-only points ledger. Balance = SUM(points) where type != expired.';
COMMENT ON TABLE public.user_referrals IS 'Priority #10 — referral codes. Both parties get credit when the referred user books their first service.';
COMMENT ON TABLE public.booking_groups IS 'Priority #11 — group bookings (multiple people sharing a time slot or back-to-back).';
COMMENT ON TABLE public.receipts IS 'Priority #12 — digital receipts generated post-payment. Unique per booking. Emailed via Resend.';
COMMENT ON TABLE public.tips IS 'Priority #3 — client tips. 100% to pro (no Spotbook commission). Separate Stripe PaymentIntent.';
