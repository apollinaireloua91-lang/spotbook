-- Statut `processing` (encodage Cloudflare + attente modération) + visibilité explicite.
-- Les vidéos nouvellement enregistrées restent `private` jusqu'à passage manuel / future modération.

ALTER TABLE "public"."videos" DROP CONSTRAINT IF EXISTS "videos_status_check";

ALTER TABLE "public"."videos" ADD CONSTRAINT "videos_status_check" CHECK (
  ("status" = ANY (ARRAY[
    'processing'::text,
    'pending_review'::text,
    'approved'::text,
    'rejected'::text,
    'flagged'::text
  ]))
);

ALTER TABLE "public"."videos"
  ADD COLUMN IF NOT EXISTS "visibility" text;

UPDATE "public"."videos"
SET "visibility" = 'public'
WHERE "status" = 'approved' AND ("visibility" IS NULL OR "visibility" = '');

UPDATE "public"."videos"
SET "visibility" = 'private'
WHERE "visibility" IS NULL OR trim("visibility") = '';

ALTER TABLE "public"."videos" ALTER COLUMN "visibility" SET DEFAULT 'private';
ALTER TABLE "public"."videos" ALTER COLUMN "visibility" SET NOT NULL;

ALTER TABLE "public"."videos" DROP CONSTRAINT IF EXISTS "videos_visibility_check";
ALTER TABLE "public"."videos" ADD CONSTRAINT "videos_visibility_check" CHECK (
  ("visibility" = ANY (ARRAY['private'::text, 'public'::text]))
);

CREATE INDEX IF NOT EXISTS "idx_videos_public_feed"
  ON "public"."videos" ("created_at" DESC)
  WHERE ("status" = 'approved'::text AND "visibility" = 'public'::text);

-- Auto-approve TOP PRO uniquement si la ligne arrive en `pending_review` (pas depuis `processing`).
CREATE OR REPLACE FUNCTION "public"."auto_approve_top_pro_video"() RETURNS "trigger"
  LANGUAGE "plpgsql"
  AS $$
DECLARE
  is_top BOOLEAN;
BEGIN
  IF NEW.status IS DISTINCT FROM 'pending_review' THEN
    RETURN NEW;
  END IF;
  SELECT COALESCE(is_top_pro, false) INTO is_top FROM public.users WHERE id = NEW.pro_id;
  IF is_top = true THEN
    NEW.status := 'approved';
    NEW.visibility := 'public';
  END IF;
  RETURN NEW;
END;
$$;

DROP POLICY IF EXISTS "videos_public_read" ON "public"."videos";

CREATE POLICY "videos_public_read" ON "public"."videos"
  FOR SELECT TO "authenticated"
  USING (
    (
      ("status" = 'approved'::text AND "visibility" = 'public'::text)
      OR ("pro_id" = "auth"."uid"())
    )
    AND (NOT "public"."is_blocked"("auth"."uid"(), "pro_id"))
  );
