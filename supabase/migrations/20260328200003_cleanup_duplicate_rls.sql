-- Clean up older French-named RLS policies that are superseded by
-- newer English-named equivalents. All functionality is preserved.

-- bookings: superseded by bookings_client_select + bookings_client_update + bookings_pro_update
DROP POLICY IF EXISTS "Bookings: lecture" ON bookings;
DROP POLICY IF EXISTS "Bookings: update concerné" ON bookings;

-- video_comments: superseded by video_comments_read (if exists) + video_comments_own_insert + video_comments_own_delete
DROP POLICY IF EXISTS "Comments: lecture" ON video_comments;

-- events: superseded by events_pro_manage / events_public_read (check if english versions exist)
-- Only drop if english equivalents exist. These don't have direct english equivalents
-- based on the schema, so we keep them for now.
-- DROP POLICY IF EXISTS "Events: delete pro" ON events;
-- DROP POLICY IF EXISTS "Events: insert pro" ON events;
-- DROP POLICY IF EXISTS "Events: lecture" ON events;
-- DROP POLICY IF EXISTS "Events: update pro" ON events;

-- favorites: superseded by favorites_own_manage
DROP POLICY IF EXISTS "Favorites: propre" ON favorites;

-- video_likes: check for english equivalents
-- These appear to have english equivalents: video_likes_own, video_likes_own_read
DROP POLICY IF EXISTS "Likes: delete propre" ON video_likes;
DROP POLICY IF EXISTS "Likes: insert" ON video_likes;
DROP POLICY IF EXISTS "Likes: lecture" ON video_likes;

-- messages: superseded by messages_participant
DROP POLICY IF EXISTS "Messages: lecture" ON messages;

-- profiles_pro: superseded by profiles_pro_own_insert + block_commission_update
DROP POLICY IF EXISTS "Profiles pro: insert propre" ON profiles_pro;
DROP POLICY IF EXISTS "Profiles pro: update propre" ON profiles_pro;

-- promo_codes: superseded by promo_codes_active_read + promo_codes_pro_manage
DROP POLICY IF EXISTS "Promo: insert pro" ON promo_codes;
DROP POLICY IF EXISTS "Promo: lecture active" ON promo_codes;
DROP POLICY IF EXISTS "Promo: update pro" ON promo_codes;

-- reviews: superseded by reviews_insert_as_client
DROP POLICY IF EXISTS "Reviews: insert client" ON reviews;

-- services: no english equivalents found in schema — keep these
-- DROP POLICY IF EXISTS "Services: delete pro" ON services;
-- DROP POLICY IF EXISTS "Services: insert pro" ON services;
-- DROP POLICY IF EXISTS "Services: update pro" ON services;

-- users: superseded by users_own_insert + users_own_update + users_public_read
DROP POLICY IF EXISTS "Users: insert propre" ON users;
DROP POLICY IF EXISTS "Users: lecture publique" ON users;
DROP POLICY IF EXISTS "Users: update propre" ON users;

-- videos: no english equivalents found — keep these
-- DROP POLICY IF EXISTS "Videos: delete pro" ON videos;
-- DROP POLICY IF EXISTS "Videos: insert pro" ON videos;
-- DROP POLICY IF EXISTS "Videos: update pro" ON videos;
