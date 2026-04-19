-- =============================================================================
-- Quick Replies (Messenger Marketplace-style suggestions)
-- =============================================================================
-- Adds two tables:
--   * quick_reply_templates : read-only default suggestions, keyed by pro
--     category slug + audience (pro | client). Seeded with common phrases
--     across the most-used categories in all 4 markets (CA/FR/US/CI).
--   * pro_quick_replies     : per-pro custom suggestions. Full CRUD by the
--     owner, invisible to everyone else.
--
-- Merge strategy happens client-side: custom replies come first, then
-- category-seeded templates fill up to ~8 chips in the chat bar.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Templates table (defaults, read-only for clients; admin-seeded)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quick_reply_templates (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_slug text NOT NULL,
  audience      text NOT NULL CHECK (audience IN ('pro','client')),
  text_fr       text NOT NULL CHECK (char_length(text_fr) BETWEEN 1 AND 200),
  text_en       text NOT NULL CHECK (char_length(text_en) BETWEEN 1 AND 200),
  sort_order    int  NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_qrt_lookup
  ON public.quick_reply_templates (category_slug, audience, sort_order);

ALTER TABLE public.quick_reply_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "qrt_read_any_authenticated" ON public.quick_reply_templates;
CREATE POLICY "qrt_read_any_authenticated" ON public.quick_reply_templates
  FOR SELECT TO authenticated USING (true);

-- -----------------------------------------------------------------------------
-- 2. Per-pro custom quick replies
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pro_quick_replies (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pro_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  text       text NOT NULL CHECK (char_length(text) BETWEEN 1 AND 200),
  sort_order int  NOT NULL DEFAULT 0,
  is_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pqr_owner
  ON public.pro_quick_replies (pro_id, sort_order);

ALTER TABLE public.pro_quick_replies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pqr_owner_select" ON public.pro_quick_replies;
CREATE POLICY "pqr_owner_select" ON public.pro_quick_replies
  FOR SELECT TO authenticated USING (pro_id = auth.uid());

DROP POLICY IF EXISTS "pqr_owner_insert" ON public.pro_quick_replies;
CREATE POLICY "pqr_owner_insert" ON public.pro_quick_replies
  FOR INSERT TO authenticated WITH CHECK (pro_id = auth.uid());

DROP POLICY IF EXISTS "pqr_owner_update" ON public.pro_quick_replies;
CREATE POLICY "pqr_owner_update" ON public.pro_quick_replies
  FOR UPDATE TO authenticated
  USING (pro_id = auth.uid())
  WITH CHECK (pro_id = auth.uid());

DROP POLICY IF EXISTS "pqr_owner_delete" ON public.pro_quick_replies;
CREATE POLICY "pqr_owner_delete" ON public.pro_quick_replies
  FOR DELETE TO authenticated USING (pro_id = auth.uid());

-- Keep updated_at fresh on edits.
CREATE OR REPLACE FUNCTION public._set_pqr_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pqr_updated_at ON public.pro_quick_replies;
CREATE TRIGGER pqr_updated_at
  BEFORE UPDATE ON public.pro_quick_replies
  FOR EACH ROW EXECUTE FUNCTION public._set_pqr_updated_at();

-- -----------------------------------------------------------------------------
-- 3. Seed defaults for common categories
--    For each category: 4-5 "pro" replies + 4-5 "client" questions.
--    Emojis light (1-2 max), tone casual-pro, markets CA/FR/US/CI.
-- -----------------------------------------------------------------------------

INSERT INTO public.quick_reply_templates (category_slug, audience, text_fr, text_en, sort_order) VALUES
-- ─── Photographe ──────────────────────────────────────────────
('photographe','pro',   'Merci pour votre message 📸',                                 'Thanks for reaching out 📸',                                    1),
('photographe','pro',   'Oui, je suis disponible à cette date',                        'Yes, I''m available on that date',                              2),
('photographe','pro',   'Voici mes tarifs — je vous envoie le détail',                 'Here are my rates — sending you the breakdown',                 3),
('photographe','pro',   'Pouvez-vous m''envoyer la date et le lieu ?',                 'Can you share the date and location?',                          4),
('photographe','pro',   'Je vous propose un appel pour en discuter ?',                 'Want to hop on a quick call to discuss?',                       5),
('photographe','client','Bonjour, êtes-vous disponible le ?',                          'Hi, are you available on ?',                                    1),
('photographe','client','Quel est votre tarif pour une séance ?',                      'What''s your rate for a session?',                              2),
('photographe','client','Faites-vous les mariages ?',                                  'Do you shoot weddings?',                                        3),
('photographe','client','Où êtes-vous basé(e) ?',                                      'Where are you based?',                                          4),
('photographe','client','Combien de photos retouchées sont incluses ?',                'How many edited photos are included?',                          5),

-- ─── Coiffure ─────────────────────────────────────────────────
('coiffure','pro',      'Bonjour ! Merci de me contacter ✂️',                          'Hi! Thanks for reaching out ✂️',                                1),
('coiffure','pro',      'Quel service souhaitez-vous ?',                               'Which service are you looking for?',                            2),
('coiffure','pro',      'J''ai un créneau ce week-end',                                'I have an opening this weekend',                                3),
('coiffure','pro',      'Pouvez-vous m''envoyer une photo de votre coupe actuelle ?',  'Can you send a photo of your current cut?',                     4),
('coiffure','pro',      'Je confirme votre rendez-vous',                               'Your appointment is confirmed',                                 5),
('coiffure','client',   'Bonjour, avez-vous de la dispo cette semaine ?',              'Hi, any availability this week?',                               1),
('coiffure','client',   'Faites-vous les tresses / braids ?',                          'Do you do braids?',                                             2),
('coiffure','client',   'Quel est le prix pour une coupe + barbe ?',                   'What''s the price for a cut + beard trim?',                     3),
('coiffure','client',   'Puis-je venir à domicile ?',                                  'Do you offer home service?',                                    4),

-- ─── Barbier ──────────────────────────────────────────────────
('barbier','pro',       'Salut ! Merci pour votre message 💈',                         'Hey! Thanks for reaching out 💈',                               1),
('barbier','pro',       'Je suis dispo ce week-end',                                   'I have slots open this weekend',                                2),
('barbier','pro',       'Coupe + barbe : voici mon tarif',                             'Cut + beard: here''s my rate',                                  3),
('barbier','pro',       'Vous voulez passer aujourd''hui ?',                           'Want to come in today?',                                        4),
('barbier','client',    'Bonjour, avez-vous un créneau ?',                             'Hi, any open slots?',                                           1),
('barbier','client',    'Vous acceptez les walk-ins ?',                                'Do you take walk-ins?',                                         2),
('barbier','client',    'C''est combien pour une coupe ?',                             'How much for a haircut?',                                       3),

-- ─── Traiteur / Chef privé ────────────────────────────────────
('traiteur','pro',      'Merci pour votre demande ! 🍽️',                               'Thanks for your inquiry! 🍽️',                                   1),
('traiteur','pro',      'Pour combien de personnes ?',                                 'How many guests?',                                              2),
('traiteur','pro',      'Je vous envoie un devis dans la journée',                     'Sending you a quote today',                                     3),
('traiteur','pro',      'Avez-vous des allergies ou régimes spéciaux ?',               'Any allergies or dietary restrictions?',                        4),
('traiteur','pro',      'Quelle cuisine recherchez-vous ?',                            'What kind of cuisine are you looking for?',                     5),
('traiteur','client',   'Bonjour, faites-vous des événements pour ?',                  'Hi, do you cater events for ?',                                 1),
('traiteur','client',   'Quel est le prix par personne ?',                             'What''s the price per person?',                                 2),
('traiteur','client',   'Êtes-vous disponible le ?',                                   'Are you available on ?',                                        3),
('traiteur','client',   'Pouvez-vous faire de la cuisine africaine ?',                 'Can you do African cuisine?',                                   4),

-- ─── DJ / Musique ─────────────────────────────────────────────
('dj','pro',            'Salut ! Merci pour votre message 🎧',                         'Hey! Thanks for your message 🎧',                               1),
('dj','pro',            'Quel type d''événement ?',                                    'What kind of event is it?',                                     2),
('dj','pro',            'Durée prévue et lieu ?',                                      'Duration and location?',                                        3),
('dj','pro',            'Je peux fournir le son et lumière',                           'I can bring sound and lighting',                                4),
('dj','pro',            'Voici mon tarif pour cette prestation',                       'Here''s my rate for this gig',                                  5),
('dj','client',         'Disponible le soir du ?',                                     'Free the evening of ?',                                         1),
('dj','client',         'Vous avez votre propre matériel ?',                           'Do you bring your own gear?',                                   2),
('dj','client',         'Mariage / soirée privée — votre style ?',                     'Wedding / private party — what''s your style?',                 3),
('dj','client',         'Quel est votre tarif pour 4 heures ?',                        'What''s your rate for 4 hours?',                                4),

-- ─── Plombier ─────────────────────────────────────────────────
('plombier','pro',      'Bonjour, je reviens vers vous rapidement 🔧',                 'Hi, I''ll get back to you shortly 🔧',                          1),
('plombier','pro',      'Pouvez-vous décrire le problème ?',                           'Can you describe the issue?',                                   2),
('plombier','pro',      'Une photo peut aider — pouvez-vous m''en envoyer une ?',      'A photo would help — can you send one?',                        3),
('plombier','pro',      'Je peux passer aujourd''hui ou demain',                       'I can come by today or tomorrow',                               4),
('plombier','pro',      'Déplacement + diagnostic : voici le tarif',                   'Call-out + diagnosis: here''s the rate',                        5),
('plombier','client',   'Bonjour, j''ai une urgence — disponible ?',                   'Hi, I have an emergency — are you available?',                  1),
('plombier','client',   'Quel est votre tarif horaire ?',                              'What''s your hourly rate?',                                     2),
('plombier','client',   'Intervenez-vous le week-end ?',                               'Do you work weekends?',                                         3),
('plombier','client',   'Pouvez-vous passer aujourd''hui ?',                           'Can you come by today?',                                        4),

-- ─── Électricien ──────────────────────────────────────────────
('electricien','pro',   'Merci pour votre message ⚡',                                  'Thanks for your message ⚡',                                     1),
('electricien','pro',   'Pouvez-vous décrire le problème ?',                           'Can you describe the issue?',                                   2),
('electricien','pro',   'Déplacement + diagnostic, voici mon tarif',                   'Call-out + diagnosis, here''s my rate',                         3),
('electricien','pro',   'Je peux intervenir dans la journée',                          'I can come by today',                                           4),
('electricien','client','Panne électrique, êtes-vous disponible ?',                    'Power issue — are you available?',                              1),
('electricien','client','Tarif horaire ?',                                             'Hourly rate?',                                                  2),
('electricien','client','Intervenez-vous la nuit ?',                                   'Do you do after-hours calls?',                                  3),

-- ─── Coach sportif ────────────────────────────────────────────
('coach-sportif','pro', 'Merci pour ton intérêt 💪',                                   'Thanks for reaching out 💪',                                    1),
('coach-sportif','pro', 'Quel est ton objectif ?',                                     'What''s your goal?',                                            2),
('coach-sportif','pro', 'Combien de séances par semaine ?',                            'How many sessions per week?',                                   3),
('coach-sportif','pro', 'Première séance découverte offerte',                          'First discovery session is on me',                              4),
('coach-sportif','client','Salut, tu fais du coaching à domicile ?',                   'Hi, do you offer home coaching?',                               1),
('coach-sportif','client','Prix pour 10 séances ?',                                    'Price for a 10-session pack?',                                  2),
('coach-sportif','client','Tu coaches en ligne ?',                                     'Do you do online coaching?',                                    3),

-- ─── Massage ──────────────────────────────────────────────────
('massage','pro',       'Merci pour votre message 💆',                                 'Thanks for your message 💆',                                    1),
('massage','pro',       'Quel type de massage souhaitez-vous ?',                       'Which type of massage are you looking for?',                    2),
('massage','pro',       'Je propose également le déplacement à domicile',              'I also offer in-home service',                                  3),
('massage','pro',       'Voici mes créneaux disponibles',                              'Here are my open slots',                                        4),
('massage','client',    'Bonjour, massage détente disponible ?',                       'Hi, relaxation massage available?',                             1),
('massage','client',    'Vous venez à domicile ?',                                     'Do you travel for appointments?',                               2),
('massage','client',    'Durée et tarif ?',                                            'Duration and rate?',                                            3),

-- ─── Maquillage ───────────────────────────────────────────────
('maquillage','pro',    'Merci pour votre message 💄',                                 'Thanks for your message 💄',                                    1),
('maquillage','pro',    'Quelle occasion ?',                                           'What''s the occasion?',                                         2),
('maquillage','pro',    'Un essai est-il prévu ?',                                     'Will there be a trial session?',                                3),
('maquillage','pro',    'Voici mes forfaits',                                          'Here are my packages',                                          4),
('maquillage','client', 'Bonjour, mariage le — dispo ?',                               'Hi, wedding on — available?',                                   1),
('maquillage','client', 'Vous vous déplacez ?',                                        'Do you travel?',                                                2),
('maquillage','client', 'Tarif pour la mariée + 3 demoiselles ?',                      'Rate for bride + 3 bridesmaids?',                               3),

-- ─── Nail Art / Manucure ──────────────────────────────────────
('nail-art','pro',      'Coucou ! Merci pour ton message 💅',                          'Hey! Thanks for reaching out 💅',                               1),
('nail-art','pro',      'Quel style tu veux ? Gel / acrylique / chrome ?',             'What style — gel / acrylic / chrome?',                          2),
('nail-art','pro',      'J''ai de la place ce week-end',                               'I have spots open this weekend',                                3),
('nail-art','client',   'Salut, tu fais du gel ?',                                     'Hi, do you do gel?',                                            1),
('nail-art','client',   'Prix pour une pose + nail art ?',                             'Price for set + nail art?',                                     2),
('nail-art','client',   'Tu acceptes les inspirations Pinterest ?',                    'Do you take Pinterest inspo?',                                  3),

-- ─── Soins capillaires / Tresses ──────────────────────────────
('soins-capillaires','pro','Salut ! Merci pour ton message 💇',                        'Hi! Thanks for reaching out 💇',                                1),
('soins-capillaires','pro','Quel style de tresses recherches-tu ?',                    'What style of braids are you going for?',                       2),
('soins-capillaires','pro','Cheveux fournis ou à prévoir ?',                           'Hair provided or do I supply it?',                              3),
('soins-capillaires','pro','Durée estimée de la prestation',                           'Estimated duration of the session',                             4),
('soins-capillaires','client','Tu fais les box braids ?',                              'Do you do box braids?',                                         1),
('soins-capillaires','client','Prix pour des knotless ?',                              'Price for knotless?',                                           2),
('soins-capillaires','client','Tu travailles à domicile ?',                            'Do you work from home?',                                        3),

-- ─── Ménage / Entretien ménager ───────────────────────────────
('menage','pro',        'Merci pour votre message 🧹',                                 'Thanks for your message 🧹',                                    1),
('menage','pro',        'Quelle surface (m² ou pièces) ?',                             'How large (sqm or rooms)?',                                     2),
('menage','pro',        'Ponctuel ou récurrent ?',                                     'One-time or recurring?',                                        3),
('menage','pro',        'Je fournis tous les produits',                                'I bring all supplies',                                          4),
('menage','client',     'Bonjour, ménage hebdomadaire possible ?',                     'Hi, weekly cleaning possible?',                                 1),
('menage','client',     'Tarif pour un 3 pièces ?',                                    'Rate for a 3-bedroom?',                                         2),
('menage','client',     'Vous venez avec votre matériel ?',                            'Do you bring your own equipment?',                              3),

-- ─── Déménagement ─────────────────────────────────────────────
('demenagement','pro',  'Merci pour votre message 📦',                                 'Thanks for your message 📦',                                    1),
('demenagement','pro',  'Départ et arrivée ?',                                         'Pickup and drop-off?',                                          2),
('demenagement','pro',  'Volume approximatif (m³ ou nb de pièces) ?',                  'Approx volume (m³ or # of rooms)?',                             3),
('demenagement','pro',  'Étages et ascenseur ?',                                       'Floors and elevator?',                                          4),
('demenagement','client','Déménagement prévu le — disponible ?',                       'Moving on — available?',                                        1),
('demenagement','client','Tarif forfait ou à l''heure ?',                              'Flat rate or hourly?',                                          2),
('demenagement','client','Vous fournissez les cartons ?',                              'Do you supply boxes?',                                          3),

-- ─── Wedding planner ──────────────────────────────────────────
('wedding-planner','pro','Merci pour votre message 💒',                                'Thanks for your message 💒',                                    1),
('wedding-planner','pro','Date prévue et nombre d''invités ?',                         'Planned date and guest count?',                                 2),
('wedding-planner','pro','Budget approximatif ?',                                      'Rough budget?',                                                 3),
('wedding-planner','pro','On fixe un appel pour en discuter ?',                        'Can we set up a call?',                                         4),
('wedding-planner','client','Bonjour, mariage le — disponible ?',                      'Hi, wedding on — available?',                                   1),
('wedding-planner','client','Forfait complet ou jour J ?',                             'Full planning or day-of only?',                                 2),
('wedding-planner','client','Tarif indicatif ?',                                       'Ballpark rate?',                                                3),

-- ─── Tuteur / Professeur privé ────────────────────────────────
('tuteur','pro',        'Merci pour votre message 📚',                                 'Thanks for your message 📚',                                    1),
('tuteur','pro',        'Quelle matière / niveau ?',                                   'Which subject / level?',                                        2),
('tuteur','pro',        'Combien d''heures par semaine ?',                             'How many hours per week?',                                      3),
('tuteur','pro',        'En ligne ou en présentiel ?',                                 'Online or in-person?',                                          4),
('tuteur','client',     'Cours de maths niveau lycée — dispo ?',                       'High school math tutoring — available?',                        1),
('tuteur','client',     'Tarif horaire ?',                                             'Hourly rate?',                                                  2),
('tuteur','client',     'Cours en visio possibles ?',                                  'Are video lessons possible?',                                   3),

-- ─── Mécanicien automobile ────────────────────────────────────
('mecanicien','pro',    'Merci pour votre message 🔧',                                 'Thanks for your message 🔧',                                    1),
('mecanicien','pro',    'Quelle marque et année ?',                                    'What make and year?',                                           2),
('mecanicien','pro',    'Diagnostic gratuit, je reviens vers vous avec un devis',      'Free diagnosis, I''ll send you a quote',                        3),
('mecanicien','client', 'Problème moteur, pouvez-vous regarder ?',                     'Engine issue — can you take a look?',                           1),
('mecanicien','client', 'Vous faites le remorquage ?',                                 'Do you offer towing?',                                          2),
('mecanicien','client', 'Délai pour une révision ?',                                   'Lead time for a service?',                                      3),

-- ─── Chauffeur privé ──────────────────────────────────────────
('chauffeur-prive','pro','Merci pour votre demande 🚘',                                'Thanks for your request 🚘',                                    1),
('chauffeur-prive','pro','Date, heure et adresses ?',                                  'Date, time, and addresses?',                                    2),
('chauffeur-prive','pro','Véhicule standard ou premium ?',                             'Standard or premium vehicle?',                                  3),
('chauffeur-prive','client','Course aéroport le — dispo ?',                            'Airport pickup on — available?',                                1),
('chauffeur-prive','client','Tarif pour trajet ?',                                     'Rate for a ride?',                                              2),
('chauffeur-prive','client','Voiture pour 4 passagers + bagages ?',                    'Car for 4 pax + luggage?',                                      3),

-- ─── Fallback (autre) — pro générique ─────────────────────────
('autre','pro',         'Merci pour votre message',                                    'Thanks for your message',                                       1),
('autre','pro',         'Je reviens vers vous rapidement',                             'I''ll get back to you shortly',                                 2),
('autre','pro',         'Pouvez-vous me donner plus de détails ?',                     'Can you give me more details?',                                 3),
('autre','pro',         'Voici mon tarif',                                             'Here''s my rate',                                               4),
('autre','pro',         'Je confirme votre rendez-vous',                               'Your appointment is confirmed',                                 5),
('autre','client',      'Bonjour, êtes-vous disponible ?',                             'Hi, are you available?',                                        1),
('autre','client',      'Quel est votre tarif ?',                                      'What''s your rate?',                                            2),
('autre','client',      'Où êtes-vous situé(e) ?',                                     'Where are you based?',                                          3),
('autre','client',      'Pouvez-vous m''en dire plus ?',                               'Can you tell me more?',                                         4)
ON CONFLICT DO NOTHING;

COMMENT ON TABLE  public.quick_reply_templates IS 'Default chat quick-reply suggestions by pro category + audience.';
COMMENT ON TABLE  public.pro_quick_replies     IS 'Pro-authored custom chat quick replies (private to owner).';
