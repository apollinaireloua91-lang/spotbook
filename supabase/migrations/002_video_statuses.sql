-- ============================================================
-- SPOTBOOK — 002_video_statuses.sql
-- Add description, rejection_reason, flag_count + constraints + trigger
-- ============================================================

-- Add missing columns
ALTER TABLE videos ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE videos ADD COLUMN IF NOT EXISTS rejection_reason text;
ALTER TABLE videos ADD COLUMN IF NOT EXISTS flag_count int DEFAULT 0;

-- Add CHECK constraint on status
ALTER TABLE videos DROP CONSTRAINT IF EXISTS videos_status_check;
ALTER TABLE videos ADD CONSTRAINT videos_status_check
  CHECK (status IN ('pending_review', 'approved', 'rejected', 'flagged'));

-- Index for approved videos (feed performance)
CREATE INDEX IF NOT EXISTS idx_videos_approved
  ON videos(created_at DESC)
  WHERE status = 'approved';

-- ============================================================
-- TRIGGER — auto-flag when flag_count >= 3
-- ============================================================
CREATE OR REPLACE FUNCTION auto_flag_video() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.flag_count >= 3 AND OLD.flag_count < 3 THEN
    NEW.status := 'flagged';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_flag_video ON videos;
CREATE TRIGGER trigger_auto_flag_video
  BEFORE UPDATE ON videos
  FOR EACH ROW EXECUTE FUNCTION auto_flag_video();
