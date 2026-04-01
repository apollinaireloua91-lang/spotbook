-- Add Spotify track metadata columns to videos table
ALTER TABLE videos
  ADD COLUMN IF NOT EXISTS spotify_track_title TEXT,
  ADD COLUMN IF NOT EXISTS spotify_track_artist TEXT;
