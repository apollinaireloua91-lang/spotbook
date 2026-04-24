-- Migration: fix_push_notification_route_per_role
--
-- Contexte
-- ────────
-- La fonction `tr_notify_new_message_push()` (cf. migration
-- 20260326121446_remote_schema.sql L901-940) est appelée par le trigger
-- `tr_messages_push_after_insert` à chaque INSERT dans `messages`. Elle
-- résout le destinataire (l'autre participant de la conversation) puis
-- déclenche `fire_send_push_notification(...)` avec le payload FCM.
--
-- Bug : le payload contenait `route: '/client/messages'` HARDCODÉ. Quand
-- le destinataire est un Pro (role='pro'), le push qui arrive sur son
-- iPhone l'invitait à ouvrir le shell client — qui n'existe pas pour
-- son compte. Tap sur la notif → GoRouter redirect (parce que session
-- Pro) ou route 404 → expérience cassée.
--
-- Cf. docs/PRO_NOTIFICATIONS_AUDIT.md §3 bug #2.
--
-- Fix
-- ───
-- Lookup `users.role` du destinataire et router :
--   role = 'pro' → '/pro/messages'
--   role = autre → '/client/messages'
--
-- Bonus : remplacer le fallback emoji '📷 Image' par 'Photo' (règle projet
-- "pas d'emoji dans les strings de notifications").

CREATE OR REPLACE FUNCTION public.tr_notify_new_message_push() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  conv public.conversations%ROWTYPE;
  recipient uuid;
  recipient_role text;
  v_route text;
  preview text;
BEGIN
  SELECT * INTO conv FROM public.conversations WHERE id = NEW.conversation_id;
  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  IF NEW.sender_id = conv.client_id THEN
    recipient := conv.pro_id;
  ELSE
    recipient := conv.client_id;
  END IF;

  IF recipient IS NULL OR recipient = NEW.sender_id THEN
    RETURN NEW;
  END IF;

  -- Lookup role for recipient — drives the route in the FCM payload so
  -- the Flutter handler navigates to the correct shell.
  SELECT role INTO recipient_role FROM public.users WHERE id = recipient;
  v_route := CASE
    WHEN recipient_role = 'pro' THEN '/pro/messages'
    ELSE '/client/messages'
  END;

  preview := LEFT(COALESCE(NEW.content, 'Photo'), 140);

  PERFORM public.fire_send_push_notification(
    recipient,
    'Nouveau message',
    preview,
    'message',
    jsonb_build_object(
      'conversationId', NEW.conversation_id::text,
      'route', v_route
    )
  );

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.tr_notify_new_message_push() OWNER TO postgres;
