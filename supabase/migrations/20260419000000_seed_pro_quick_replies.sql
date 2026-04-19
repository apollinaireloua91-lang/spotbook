-- =============================================================================
-- Pro Quick Replies — first-access seeding
-- =============================================================================
-- Goal: give every pro at least 3 editable quick replies out of the box, picked
-- from `quick_reply_templates` based on their category (falls back to 'autre'
-- if the specific category has nothing seeded).
--
-- Design:
--   * A nullable `quick_replies_seeded_at` marker on `profiles_pro` so we can
--     tell "never initialized" apart from "pro deleted everything".
--     Seeding is one-shot: deleted replies are NOT re-seeded.
--   * A SECURITY DEFINER RPC `seed_my_quick_replies()` so the operation is
--     atomic (flag flip + inserts in one transaction) and idempotent.
--   * The client calls it before every fetch of the pro's custom replies;
--     the RPC short-circuits on the marker so subsequent calls are ~free.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Marker column
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles_pro
  ADD COLUMN IF NOT EXISTS quick_replies_seeded_at timestamptz;

-- -----------------------------------------------------------------------------
-- 2. Seeding RPC
-- -----------------------------------------------------------------------------
-- Returns the number of rows inserted (0 if already seeded, or up to 3).
CREATE OR REPLACE FUNCTION public.seed_my_quick_replies()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid            uuid := auth.uid();
  v_already_seeded timestamptz;
  v_category_label text;
  v_slug           text;
  v_inserted       int  := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Guard: only seed once, ever.
  SELECT quick_replies_seeded_at, category
    INTO v_already_seeded, v_category_label
    FROM public.profiles_pro
   WHERE id = v_uid;

  -- No pro profile yet (e.g. the user is a client) — nothing to do.
  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  IF v_already_seeded IS NOT NULL THEN
    RETURN 0;
  END IF;

  -- Resolve label → slug (profiles_pro stores the human label, templates key
  -- on the stable slug).
  IF v_category_label IS NOT NULL AND v_category_label <> '' THEN
    SELECT slug INTO v_slug
      FROM public.pro_categories
     WHERE name_fr = v_category_label
     LIMIT 1;
  END IF;

  -- Either no category set, or the label doesn't match any known slug.
  IF v_slug IS NULL THEN
    v_slug := 'autre';
  END IF;

  -- If the resolved slug has no pro-facing templates seeded, fall back to
  -- the generic bucket (always populated).
  IF NOT EXISTS (
    SELECT 1 FROM public.quick_reply_templates
     WHERE category_slug = v_slug AND audience = 'pro'
  ) THEN
    v_slug := 'autre';
  END IF;

  -- Pick top 3 pro-facing templates and insert them with sort_order 1..3.
  INSERT INTO public.pro_quick_replies (pro_id, text, sort_order, is_enabled)
  SELECT v_uid,
         t.text_fr,
         row_number() OVER (ORDER BY t.sort_order, t.id),
         true
    FROM public.quick_reply_templates t
   WHERE t.category_slug = v_slug
     AND t.audience = 'pro'
   ORDER BY t.sort_order, t.id
   LIMIT 3;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;

  -- Flip the marker even if we inserted 0 rows — otherwise we'd retry forever.
  UPDATE public.profiles_pro
     SET quick_replies_seeded_at = now()
   WHERE id = v_uid;

  RETURN v_inserted;
END;
$$;

-- Allow any authenticated user to call it (the RPC itself enforces that it
-- only operates on the caller's own profile via auth.uid()).
GRANT EXECUTE ON FUNCTION public.seed_my_quick_replies() TO authenticated;

-- -----------------------------------------------------------------------------
-- 3. Back-seed existing pros
-- -----------------------------------------------------------------------------
-- For pros who already existed before this migration and have zero custom
-- replies, insert 3 defaults and stamp the marker. Pros who have *any* custom
-- reply already are left alone (we assume they've already curated their list,
-- so we just stamp the marker to prevent future seeding).
DO $$
DECLARE
  r      record;
  v_slug text;
BEGIN
  FOR r IN
    SELECT p.id AS pro_id, p.category
      FROM public.profiles_pro p
     WHERE p.quick_replies_seeded_at IS NULL
  LOOP
    -- Resolve slug
    v_slug := NULL;
    IF r.category IS NOT NULL AND r.category <> '' THEN
      SELECT slug INTO v_slug
        FROM public.pro_categories
       WHERE name_fr = r.category
       LIMIT 1;
    END IF;
    IF v_slug IS NULL THEN
      v_slug := 'autre';
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM public.quick_reply_templates
       WHERE category_slug = v_slug AND audience = 'pro'
    ) THEN
      v_slug := 'autre';
    END IF;

    -- Only insert defaults for pros with zero existing custom replies —
    -- leave curated lists alone.
    IF NOT EXISTS (
      SELECT 1 FROM public.pro_quick_replies WHERE pro_id = r.pro_id
    ) THEN
      INSERT INTO public.pro_quick_replies (pro_id, text, sort_order, is_enabled)
      SELECT r.pro_id,
             t.text_fr,
             row_number() OVER (ORDER BY t.sort_order, t.id),
             true
        FROM public.quick_reply_templates t
       WHERE t.category_slug = v_slug
         AND t.audience = 'pro'
       ORDER BY t.sort_order, t.id
       LIMIT 3;
    END IF;

    -- Stamp the marker either way so future opens don't retry seeding.
    UPDATE public.profiles_pro
       SET quick_replies_seeded_at = now()
     WHERE id = r.pro_id;
  END LOOP;
END $$;
