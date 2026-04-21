-- tickets INSERT — fermer le vecteur de fraude.
--
-- Contexte
-- --------
-- `20260411100000_security_rls_hardening.sql` L50-59 crée la policy
-- `tickets_buyer_insert` avec `WITH CHECK (auth.uid() = user_id)`. Ça
-- autorise n'importe quel client authentifié à INSÉRER un ticket pour
-- lui-même depuis le Flutter, **sans avoir payé**. Le code
-- `lib/features/events/data/event_repository.dart` (méthode `createTickets`)
-- utilise effectivement ce chemin : il INSERT les N tickets avec
-- `qr_code_url=null` après avoir payé côté Stripe, mais rien côté DB ne
-- vérifie que le PaymentIntent est réellement `succeeded`.
--
-- Impact rapporté par `docs/CLIENT_FLOWS_AUDIT.md` (🔴) :
--   → billets gratuits pour peu qu'on ait l'id d'un `ticket_types` public.
--
-- Décision
-- --------
-- 1. On *remplace* la policy par une version restreinte au `service_role`.
--    Seule l'Edge Function `purchase-tickets-atomic` (Chantier 3) aura
--    le droit d'insérer — après avoir vérifié avec Stripe que le PI
--    est bien réglé, signé le QR en HMAC serveur, etc.
-- 2. Le Flutter devra cesser d'appeler `createTickets` côté client.
--    Fix traqué dans Chantier 4.
--
-- Cette migration se contente de la partie DB. Si elle est déployée avant
-- l'Edge Function, l'application continue à "fonctionner" mais les INSERT
-- client-side remonteront en erreur RLS — ce qui est le comportement
-- souhaité (fail-closed) pour la durée courte de la bascule.

begin;

-- On drop l'ancienne policy (garde-fou si elle a été régénérée hors
-- migration). Puis on re-crée la version service_role-only. On garde le
-- même nom pour qu'elle reste idempotent-friendly pour les futures
-- migrations conditionnelles.

drop policy if exists tickets_buyer_insert on public.tickets;

create policy tickets_buyer_insert
  on public.tickets
  for insert
  to authenticated
  with check (auth.role() = 'service_role'::text);

comment on policy tickets_buyer_insert on public.tickets is
  'INSERT reservé au service_role. L''Edge Function purchase-tickets-atomic signe les tickets côté serveur après vérification du PaymentIntent Stripe.';

-- Note : `service_role` bypasse déjà RLS, donc cette policy est un
-- filet de sécurité contre les bascules accidentelles où un JWT `authenticated`
-- aurait des droits étendus. Elle documente surtout l'intention.

commit;

-- ── DOWN (manuel, commenté) ──────────────────────────────────────────────
-- begin;
-- drop policy if exists tickets_buyer_insert on public.tickets;
-- create policy tickets_buyer_insert
--   on public.tickets
--   for insert
--   to authenticated
--   with check (auth.uid() = user_id);
-- commit;
