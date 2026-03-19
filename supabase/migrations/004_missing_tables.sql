-- Table social_connections
CREATE TABLE IF NOT EXISTS social_connections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id) ON DELETE CASCADE,
  platform text CHECK (platform IN ('instagram','tiktok','youtube')),
  handle text,
  followers_count int DEFAULT 0,
  access_token text,
  refresh_token text,
  token_expires_at timestamptz,
  last_synced_at timestamptz,
  UNIQUE(pro_id, platform)
);
ALTER TABLE social_connections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_social" ON social_connections
  FOR ALL USING (
    pro_id IN (SELECT id FROM profiles_pro WHERE id = auth.uid())
  );

-- Table favorites
CREATE TABLE IF NOT EXISTS favorites (
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  target_id uuid,
  target_type text CHECK (target_type IN ('pro','event')),
  PRIMARY KEY (user_id, target_id)
);
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_favorites" ON favorites
  FOR ALL USING (auth.uid() = user_id);

-- Table follows
CREATE TABLE IF NOT EXISTS follows (
  follower_id uuid REFERENCES users(id) ON DELETE CASCADE,
  following_id uuid REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_follows" ON follows
  FOR ALL USING (auth.uid() = follower_id);

-- Table blocks
CREATE TABLE IF NOT EXISTS blocks (
  blocker_id uuid REFERENCES users(id) ON DELETE CASCADE,
  blocked_id uuid REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (blocker_id, blocked_id)
);
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_blocks" ON blocks
  FOR ALL USING (auth.uid() = blocker_id);

-- Table reviews
CREATE TABLE IF NOT EXISTS reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid UNIQUE,
  client_id uuid REFERENCES users(id),
  pro_id uuid REFERENCES profiles_pro(id),
  rating int CHECK (rating BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_reviews" ON reviews
  FOR ALL USING (auth.uid() = client_id);

-- Table promo_codes
CREATE TABLE IF NOT EXISTS promo_codes (
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
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_promo_codes" ON promo_codes
  FOR ALL USING (
    pro_id IN (SELECT id FROM profiles_pro WHERE id = auth.uid())
  );

-- Table referrals
CREATE TABLE IF NOT EXISTS referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id uuid REFERENCES users(id),
  referred_id uuid REFERENCES users(id),
  referral_code text,
  reward_given bool DEFAULT false,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_referrals" ON referrals
  FOR ALL USING (auth.uid() = referrer_id);

-- Table reports
CREATE TABLE IF NOT EXISTS reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid REFERENCES users(id),
  target_id uuid,
  target_type text,
  reason text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_reports" ON reports
  FOR ALL USING (auth.uid() = reporter_id);

-- Table pro_subscriptions
CREATE TABLE IF NOT EXISTS pro_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id uuid REFERENCES profiles_pro(id),
  stripe_subscription_id text UNIQUE,
  status text,
  current_period_end timestamptz
);
ALTER TABLE pro_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_subscriptions" ON pro_subscriptions
  FOR ALL USING (
    pro_id IN (SELECT id FROM profiles_pro WHERE id = auth.uid())
  );

-- Table notification_preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  bookings bool DEFAULT true,
  messages bool DEFAULT true,
  reminders bool DEFAULT true,
  promotions bool DEFAULT true
);
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_notif_prefs" ON notification_preferences
  FOR ALL USING (auth.uid() = user_id);

-- Table waitlist
CREATE TABLE IF NOT EXISTS waitlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_type_id uuid,
  user_id uuid REFERENCES users(id),
  position int,
  notified_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_waitlist" ON waitlist
  FOR ALL USING (auth.uid() = user_id);
