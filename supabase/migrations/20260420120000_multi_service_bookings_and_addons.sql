-- ============================================================================
-- Multi-service bookings + Service add-ons
-- ============================================================================
-- Enables a single booking to contain multiple services (e.g. haircut + beard)
-- and optional add-ons per service (e.g. hair wash +$5, conditioning +$10).
--
-- Backward compatibility:
--   - bookings.service_id stays NOT NULL and represents the PRIMARY service.
--   - booking_services holds the full ordered list (including primary).
--   - For single-service bookings, booking_services has exactly 1 row.
--
-- Pricing:
--   - Each booking_services row snapshots price + duration at time of booking.
--   - Each booking_addons row snapshots price at time of booking.
--   - Sum of all rows = bookings.total_price (enforced at app level).
-- ============================================================================

-- ── service_addons ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.service_addons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  pro_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 2 AND 80),
  description TEXT CHECK (description IS NULL OR length(description) <= 280),
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0 AND price <= 500),
  duration_minutes INTEGER NOT NULL DEFAULT 0 CHECK (duration_minutes BETWEEN 0 AND 240),
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_service_addons_service ON public.service_addons (service_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_service_addons_pro ON public.service_addons (pro_id);

ALTER TABLE public.service_addons ENABLE ROW LEVEL SECURITY;

-- Public read (active only) — add-ons are visible to clients browsing services
CREATE POLICY "service_addons_public_read_active"
  ON public.service_addons FOR SELECT
  USING (is_active = true);

-- Pro can read all own add-ons (incl. inactive)
CREATE POLICY "service_addons_pro_read_own"
  ON public.service_addons FOR SELECT
  USING (pro_id = auth.uid());

-- Pro can insert own add-ons (must own the parent service)
CREATE POLICY "service_addons_pro_insert_own"
  ON public.service_addons FOR INSERT
  WITH CHECK (
    pro_id = auth.uid()
    AND EXISTS (SELECT 1 FROM public.services s WHERE s.id = service_id AND s.pro_id = auth.uid())
  );

CREATE POLICY "service_addons_pro_update_own"
  ON public.service_addons FOR UPDATE
  USING (pro_id = auth.uid())
  WITH CHECK (pro_id = auth.uid());

CREATE POLICY "service_addons_pro_delete_own"
  ON public.service_addons FOR DELETE
  USING (pro_id = auth.uid());


-- ── booking_services (multi-service junction) ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.booking_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0 AND duration_minutes <= 480),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_booking_services_booking ON public.booking_services (booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_services_service ON public.booking_services (service_id);

ALTER TABLE public.booking_services ENABLE ROW LEVEL SECURITY;

-- Client reads their own booking's services; Pro reads bookings they own
CREATE POLICY "booking_services_participant_read"
  ON public.booking_services FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_id
        AND (b.client_id = auth.uid() OR b.pro_id = auth.uid())
    )
  );

-- Only service role writes (inserts happen via edge function / transactional RPC)
CREATE POLICY "booking_services_service_role_write"
  ON public.booking_services FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ── booking_addons (chosen add-ons per booking) ───────────────────────────
CREATE TABLE IF NOT EXISTS public.booking_addons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  booking_service_id UUID REFERENCES public.booking_services(id) ON DELETE CASCADE,
  addon_id UUID NOT NULL REFERENCES public.service_addons(id) ON DELETE RESTRICT,
  name_snapshot TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  duration_minutes INTEGER NOT NULL DEFAULT 0 CHECK (duration_minutes >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_booking_addons_booking ON public.booking_addons (booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_addons_booking_service ON public.booking_addons (booking_service_id);
CREATE INDEX IF NOT EXISTS idx_booking_addons_addon ON public.booking_addons (addon_id);

ALTER TABLE public.booking_addons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "booking_addons_participant_read"
  ON public.booking_addons FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_id
        AND (b.client_id = auth.uid() OR b.pro_id = auth.uid())
    )
  );

CREATE POLICY "booking_addons_service_role_write"
  ON public.booking_addons FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');


-- ── updated_at trigger for service_addons ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at_service_addons()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_service_addons_updated_at ON public.service_addons;
CREATE TRIGGER trg_service_addons_updated_at
  BEFORE UPDATE ON public.service_addons
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at_service_addons();


-- ── Backfill: create booking_services rows for existing single-service bookings
-- (idempotent — only inserts rows that don't already exist)
INSERT INTO public.booking_services (booking_id, service_id, price, duration_minutes, sort_order)
SELECT
  b.id,
  b.service_id,
  b.total_price,
  EXTRACT(EPOCH FROM (b.end_time - b.start_time))::int / 60,
  0
FROM public.bookings b
WHERE NOT EXISTS (
  SELECT 1 FROM public.booking_services bs WHERE bs.booking_id = b.id
);

COMMENT ON TABLE public.service_addons IS 'Optional paid extras attached to a service (e.g. hair wash). Pro-managed.';
COMMENT ON TABLE public.booking_services IS 'Multi-service junction: a booking can contain multiple services (primary + secondary).';
COMMENT ON TABLE public.booking_addons IS 'Selected add-ons per booking. Snapshots name/price at booking time for historical accuracy.';
