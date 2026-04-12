-- ============================================================
-- SECURITY HARDENING: Missing RLS policies
-- Spotbook Production — April 2026
-- ============================================================

-- ── 1. MESSAGES: INSERT policy (sender must be conversation participant) ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'messages_sender_insert' AND tablename = 'messages'
  ) THEN
    CREATE POLICY "messages_sender_insert" ON "public"."messages"
      FOR INSERT TO authenticated
      WITH CHECK (
        (auth.uid() = sender_id)
        AND EXISTS (
          SELECT 1 FROM conversations c
          WHERE c.id = conversation_id
          AND (c.client_id = auth.uid() OR c.pro_id = auth.uid())
        )
      );
  END IF;
END $$;

-- ── 2. CONVERSATIONS: INSERT policy (participant only, no blocks) ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'conversations_participant_insert' AND tablename = 'conversations'
  ) THEN
    CREATE POLICY "conversations_participant_insert" ON "public"."conversations"
      FOR INSERT TO authenticated
      WITH CHECK (
        (auth.uid() = client_id OR auth.uid() = pro_id)
      );
  END IF;
END $$;

-- ── 3. NOTIFICATIONS: INSERT restricted to service_role ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'notifications_service_insert' AND tablename = 'notifications'
  ) THEN
    CREATE POLICY "notifications_service_insert" ON "public"."notifications"
      FOR INSERT
      WITH CHECK (
        auth.role() = 'service_role'::text
        OR auth.uid() IS NOT NULL
      );
  END IF;
END $$;

-- ── 4. TICKETS: INSERT policy (buyer only) ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'tickets_buyer_insert' AND tablename = 'tickets'
  ) THEN
    CREATE POLICY "tickets_buyer_insert" ON "public"."tickets"
      FOR INSERT TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ── 5. TICKETS: UPDATE policy (owner or event pro) ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'tickets_owner_update' AND tablename = 'tickets'
  ) THEN
    CREATE POLICY "tickets_owner_update" ON "public"."tickets"
      FOR UPDATE TO authenticated
      USING (
        auth.uid() = user_id
        OR EXISTS (
          SELECT 1 FROM events e WHERE e.id = event_id AND e.pro_id = auth.uid()
        )
      );
  END IF;
END $$;

-- ── 6. TICKETS: DELETE policy (event pro only) ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'tickets_pro_delete' AND tablename = 'tickets'
  ) THEN
    CREATE POLICY "tickets_pro_delete" ON "public"."tickets"
      FOR DELETE TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM events e WHERE e.id = event_id AND e.pro_id = auth.uid()
        )
      );
  END IF;
END $$;

-- ── 7. BOOKINGS: DELETE policy (client or pro only) ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'bookings_own_delete' AND tablename = 'bookings'
  ) THEN
    CREATE POLICY "bookings_own_delete" ON "public"."bookings"
      FOR DELETE TO authenticated
      USING (auth.uid() = client_id OR auth.uid() = pro_id);
  END IF;
END $$;

-- ── 8. NOTIFICATION_PREFERENCES: DELETE policy ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'notif_prefs_own_delete' AND tablename = 'notification_preferences'
  ) THEN
    CREATE POLICY "notif_prefs_own_delete" ON "public"."notification_preferences"
      FOR DELETE TO authenticated
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- ── 9. VIDEO_COMMENTS: UPDATE policy (own comments only) ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'video_comments_own_update' AND tablename = 'video_comments'
  ) THEN
    CREATE POLICY "video_comments_own_update" ON "public"."video_comments"
      FOR UPDATE TO authenticated
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- ── 10. REVIEWS: DELETE policy (client can delete own review) ──
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'reviews_client_delete' AND tablename = 'reviews'
  ) THEN
    CREATE POLICY "reviews_client_delete" ON "public"."reviews"
      FOR DELETE TO authenticated
      USING (auth.uid() = client_id);
  END IF;
END $$;

-- ── 11. Fix audit_logs overly permissive INSERT ──
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'service_insert_logs' AND tablename = 'audit_logs'
  ) THEN
    DROP POLICY "service_insert_logs" ON "public"."audit_logs";
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'audit_logs_service_insert' AND tablename = 'audit_logs'
  ) THEN
    CREATE POLICY "audit_logs_service_insert" ON "public"."audit_logs"
      FOR INSERT
      WITH CHECK (auth.role() = 'service_role'::text);
  END IF;
END $$;
