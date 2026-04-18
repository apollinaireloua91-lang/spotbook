-- ─────────────────────────────────────────────────────────────────────
-- cities_cache — world-wide geocoding cache populated by the Edge
-- Function `geocode-city`. Allows us to place any Pro on the map using
-- their city/country as a fallback when exact coordinates are missing,
-- without re-hitting Google Geocoding for every client request.
-- ─────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.cities_cache (
    -- Normalized lookup key: lower(city) + '|' + lower(country)
    -- Ex: "montréal|canada", "paris|france", "abidjan|côte d''ivoire"
    key         text PRIMARY KEY,
    city        text NOT NULL,
    country     text,
    latitude    double precision NOT NULL,
    longitude   double precision NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.cities_cache IS
    'Geocoded (city, country) → (lat, lng) cache. Populated lazily by the geocode-city Edge Function.';

-- Any authenticated user may read (data is public geographic reference).
ALTER TABLE public.cities_cache ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cities_cache_read_authenticated" ON public.cities_cache;
CREATE POLICY "cities_cache_read_authenticated"
    ON public.cities_cache
    FOR SELECT
    TO authenticated
    USING (true);

-- No INSERT/UPDATE/DELETE policies → only service_role (via Edge Function) writes.
