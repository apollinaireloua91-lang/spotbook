-- Signalements RDV : détails optionnels + notification du pro (client → pro uniquement)
-- RLS reports inchangée : INSERT si auth.uid() = reporter_id

ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS details text;

COMMENT ON COLUMN public.reports.details IS 'Précisions optionnelles du signaleur (max ~500 côté app).';

CREATE OR REPLACE FUNCTION public.tr_notify_booking_reported()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  b public.bookings%ROWTYPE;
BEGIN
  IF NEW.target_type IS DISTINCT FROM 'booking' THEN
    RETURN NEW;
  END IF;

  IF NEW.target_id IS NULL OR NEW.reporter_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT * INTO b FROM public.bookings WHERE id = NEW.target_id;
  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  -- Seul le client ou le pro du RDV peut signaler ; on notifie l’autre partie.
  -- Politique produit v1 : notifier le **pro** quand le **client** signale ;
  -- pas de notification in-app au client quand le pro signale (traitement modération uniquement).
  IF NEW.reporter_id = b.client_id THEN
    INSERT INTO notifications (user_id, type, title, body, resource_id, data)
    VALUES (
      b.pro_id,
      'booking_reported',
      'Signalement sur un rendez-vous',
      'Un client a signalé ce rendez-vous. L’équipe peut examiner le dossier.',
      b.id::text,
      jsonb_build_object(
        'bookingId', b.id::text,
        'reportId', NEW.id::text,
        'route', '/pro/calendar/bookings/' || b.id::text
      )
    );

    PERFORM public.fire_send_push_notification(
      b.pro_id,
      'Signalement sur un rendez-vous',
      'Un client a signalé un de vos rendez-vous.',
      'booking_reported',
      jsonb_build_object(
        'bookingId', b.id::text,
        'route', '/pro/calendar/bookings/' || b.id::text
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_report_booking_notify ON public.reports;
CREATE TRIGGER on_report_booking_notify
  AFTER INSERT ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION public.tr_notify_booking_reported();
