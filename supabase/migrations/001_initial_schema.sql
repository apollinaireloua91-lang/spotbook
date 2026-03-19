-- ============================================================
-- SPOTBOOK — 001_initial_schema.sql
-- 25 tables + indexes + RLS + trigger top_pro
-- ============================================================

-- 1. users
CREATE TABLE users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  full_name text,
  username text UNIQUE,
  avatar_url text,
  cover_url text,
  bio text,
  role text CHECK (role IN ('client', 'pro')),
  city text,
  country text,
  currency text DEFAULT 'CAD',
  payment_provider text NOT NULL DEFAULT 'stripe',
  fcm_token text,
  is_verified bool DEFAULT false,
  deleted_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 2. profiles_pro
CREATE TABLE profiles_pro (
  id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  business_name text,
  category text,
  description text,
  stripe_account_id text,
  stripe_onboarded bool DEFAULT false,
  commission_rate decimal DEFAULT 0.12,
  average_rating decimal DEFAULT 0,
  review_count int DEFAULT 0,
  is_top_pro bool DEFAULT false,
  kyc_status text DEFAULT 'pending'
);

-- 3. social_connections
CREATE TABLE social_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id) ON DELETE CASCADE,
  platform text CHECK (platform IN ('instagram', 'tiktok', 'youtube')),
  handle text,
  followers_count int DEFAULT 0,
  access_token text,
  refresh_token text,
  token_expires_at timestamptz,
  last_synced_at timestamptz,
  UNIQUE(pro_id, platform)
);

-- 4. services
CREATE TABLE services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id) ON DELETE CASCADE,
  name text,
  description text,
  duration_minutes int,
  price decimal,
  is_active bool DEFAULT true
);

-- 5. availability_rules
CREATE TABLE availability_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id) ON DELETE CASCADE,
  day_of_week int CHECK (day_of_week BETWEEN 0 AND 6),
  start_time time,
  end_time time,
  slot_duration_minutes int DEFAULT 60
);

-- 6. time_slots
CREATE TABLE time_slots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id) ON DELETE CASCADE,
  date date,
  start_time time,
  end_time time,
  is_available bool DEFAULT true,
  locked_by uuid REFERENCES users(id)
);

-- 7. bookings
CREATE TABLE bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES users(id),
  pro_id uuid REFERENCES profiles_pro(id),
  service_id uuid REFERENCES services(id),
  time_slot_id uuid REFERENCES time_slots(id),
  status text DEFAULT 'pending_payment',
  deposit_amount decimal,
  total_amount decimal,
  currency text DEFAULT 'CAD',
  stripe_payment_intent_id text,
  transfer_id text,
  refund_amount decimal,
  refund_status text,
  promo_code_id uuid,
  review_requested_at timestamptz,
  booking_code text UNIQUE,
  created_at timestamptz DEFAULT now()
);

-- 8. videos
CREATE TABLE videos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id) ON DELETE CASCADE,
  cloudflare_id text,
  stream_url text,
  thumbnail_url text,
  title text,
  hashtags text[],
  category text,
  status text DEFAULT 'pending_review',
  likes_count int DEFAULT 0,
  comments_count int DEFAULT 0,
  views_count int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- 9. video_likes
CREATE TABLE video_likes (
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  video_id uuid REFERENCES videos(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, video_id)
);

-- 10. video_comments
CREATE TABLE video_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id uuid REFERENCES videos(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id),
  content text,
  created_at timestamptz DEFAULT now()
);

-- 11. events
CREATE TABLE events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id) ON DELETE CASCADE,
  title text,
  description text,
  cover_url text,
  event_date timestamptz,
  location text,
  address text,
  is_active bool DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- 12. ticket_types
CREATE TABLE ticket_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid REFERENCES events(id) ON DELETE CASCADE,
  name text,
  price decimal,
  quantity int,
  sold_count int DEFAULT 0
);

-- 13. tickets
CREATE TABLE tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid REFERENCES events(id),
  ticket_type_id uuid REFERENCES ticket_types(id),
  user_id uuid REFERENCES users(id),
  stripe_payment_intent_id text,
  qr_hash text,
  status text DEFAULT 'valid',
  scanned_at timestamptz,
  purchased_at timestamptz DEFAULT now()
);

-- 14. waitlist
CREATE TABLE waitlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_type_id uuid REFERENCES ticket_types(id),
  user_id uuid REFERENCES users(id),
  position int,
  notified_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 15. conversations
CREATE TABLE conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid REFERENCES bookings(id) UNIQUE,
  client_id uuid REFERENCES users(id),
  pro_id uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now()
);

-- 16. messages
CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES users(id),
  content text,
  image_url text,
  read_at timestamptz,
  typing_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 17. notifications
CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  type text,
  title text,
  body text,
  resource_id text,
  is_read bool DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- 18. notification_preferences
CREATE TABLE notification_preferences (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  bookings bool DEFAULT true,
  messages bool DEFAULT true,
  reminders bool DEFAULT true,
  promotions bool DEFAULT true
);

-- 19. favorites
CREATE TABLE favorites (
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  target_id uuid,
  target_type text CHECK (target_type IN ('pro', 'event')),
  PRIMARY KEY (user_id, target_id)
);

-- 20. follows
CREATE TABLE follows (
  follower_id uuid REFERENCES users(id) ON DELETE CASCADE,
  following_id uuid REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);

-- 21. blocks
CREATE TABLE blocks (
  blocker_id uuid REFERENCES users(id) ON DELETE CASCADE,
  blocked_id uuid REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (blocker_id, blocked_id)
);

-- 22. reviews
CREATE TABLE reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid REFERENCES bookings(id) UNIQUE,
  client_id uuid REFERENCES users(id),
  pro_id uuid REFERENCES profiles_pro(id),
  rating int CHECK (rating BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz DEFAULT now()
);

-- 23. promo_codes
CREATE TABLE promo_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id),
  code text UNIQUE,
  discount_type text,
  discount_value decimal,
  max_uses int,
  uses_count int DEFAULT 0,
  expires_at timestamptz,
  is_active bool DEFAULT true
);

-- 24. pro_subscriptions
CREATE TABLE pro_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id),
  stripe_subscription_id text UNIQUE,
  status text,
  current_period_end timestamptz
);

-- 25. referrals
CREATE TABLE referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id uuid REFERENCES users(id),
  referred_id uuid REFERENCES users(id),
  referral_code text,
  reward_given bool DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- 26. reports
CREATE TABLE reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid REFERENCES users(id),
  target_id uuid,
  target_type text,
  reason text,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- INDEX CRITIQUES
-- ============================================================
CREATE INDEX idx_bookings_client_id ON bookings(client_id);
CREATE INDEX idx_bookings_pro_id ON bookings(pro_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_videos_pro_id ON videos(pro_id);
CREATE INDEX idx_videos_status ON videos(status);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_time_slots_pro_date ON time_slots(pro_id, date);

-- ============================================================
-- RLS — toutes les tables
-- ============================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles_pro ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE availability_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pro_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- TRIGGER — top_pro automatique
-- ============================================================
CREATE OR REPLACE FUNCTION update_top_pro() RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles_pro SET
    average_rating = (SELECT AVG(rating) FROM reviews WHERE pro_id = NEW.pro_id),
    review_count   = (SELECT COUNT(*) FROM reviews WHERE pro_id = NEW.pro_id),
    is_top_pro     = (
      (SELECT AVG(rating) FROM reviews WHERE pro_id = NEW.pro_id) >= 4.8
      AND (SELECT COUNT(*) FROM reviews WHERE pro_id = NEW.pro_id) >= 10
    )
  WHERE id = NEW.pro_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_top_pro
  AFTER INSERT OR UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_top_pro();
