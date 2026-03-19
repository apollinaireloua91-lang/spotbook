Génère et exécute des tests TestSprite pour ces flows critiques de Spotbook :

TEST 1 — Authentification
- Login Google -> vérifier que users.payment_provider = "stripe"
- Register email -> vérifier email de confirmation envoyé
- Mauvais mot de passe -> vérifier message d'erreur précis
- 5 tentatives échouées -> vérifier rate limiting actif (HTTP 429)

TEST 2 — Réservation
- Sélectionner service -> calendrier -> créneau -> CardField -> confirmer
- Vérifier: bookings.status = "pending_payment" après étape 4
- Vérifier: time_slots.is_available = false après atomique
- Simuler double-booking: 2 users sur même slot -> 1 seul réussit

TEST 3 — Paiement Stripe
- Carte 4242 4242 4242 4242 -> paiement réussi
- Vérifier: bookings.status = "confirmed" après webhook
- Vérifier: transfer_id rempli
- Carte 4000 0000 0000 9995 -> paiement refusé
- Vérifier: time_slot libéré après échec

TEST 4 — Annulation et remboursement
- Annuler RDV > 48h -> remboursement intégral
- Vérifier: Transfer Reversal exécuté
- Annuler RDV < 48h -> pas de remboursement
- Vérifier: pro garde l'acompte

TEST 5 — QR Code et scanner
- Acheter billet -> afficher QR -> scanner -> fond vert
- Scanner même QR 2 fois -> fond orange "DÉJÀ UTILISÉ"
- Scanner QR falsifié -> fond rouge "INVALIDE"

TEST 6 — Sécurité
- Client A tente d'accéder aux bookings de Client B -> 403
- Client tente de modifier commission_rate -> RLS bloque
- Requête sans JWT -> 401 sur Edge Functions protégées
- Montant négatif dans PaymentIntent -> 400
- UUID invalide dans les paramètres -> 400

TEST 7 — Modération vidéo
- Uploader vidéo sans catégorie -> 400
- Uploader vidéo description < 20 chars -> 400
- Uploader vidéo > 60s -> rejet Flutter avant upload
- Pro sans stripe_onboarded -> 403
- Vidéo approved -> visible feed
- Vidéo pending_review -> non visible feed
- 3 signalements -> status = "flagged" et masquée feed
- Client signale contenu -> INSERT reports + flag_count++

TEST 8 — Réseaux sociaux
- Connecter Instagram -> followers_count mis à jour
- Déconnecter -> suppression ligne
- SocialBadgeWidget < 10k followers -> badge non affiché
- SocialBadgeWidget >= 10k -> badge affiché format 450K

TEST 9 — Performances
- FeedScreen: chargement < 2 secondes
- Recherche avec filtres: résultats < 1 seconde
- BookingBottomSheet: ouverture < 500ms
- Rotation d'écran: pas de crash ni perte de données

Pour chaque test qui échoue : corrige le bug avant de passer à P9.
