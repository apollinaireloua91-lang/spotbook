-- Lier une vidéo à une prestation (tarif / nom dans le feed) ou à un événement.
ALTER TABLE "public"."videos"
  ADD COLUMN IF NOT EXISTS "service_id" "uuid",
  ADD COLUMN IF NOT EXISTS "event_id" "uuid";

ALTER TABLE "public"."videos"
  DROP CONSTRAINT IF EXISTS "videos_service_id_fkey";

ALTER TABLE "public"."videos"
  ADD CONSTRAINT "videos_service_id_fkey"
  FOREIGN KEY ("service_id") REFERENCES "public"."services"("id") ON DELETE SET NULL;

ALTER TABLE "public"."videos"
  DROP CONSTRAINT IF EXISTS "videos_event_id_fkey";

ALTER TABLE "public"."videos"
  ADD CONSTRAINT "videos_event_id_fkey"
  FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS "idx_videos_service_id" ON "public"."videos" ("service_id");
CREATE INDEX IF NOT EXISTS "idx_videos_event_id" ON "public"."videos" ("event_id");
