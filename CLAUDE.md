# SPOTBOOK — CLAUDE.md

# Lis ce fichier en ENTIER avant toute action.


## PROJET

Nom         : Spotbook

Type        : Application mobile Flutter (iOS + Android)

Description : Super-app — feed vidéo TikTok-style + réservation de
              services avec acompte + billetterie événements QR.

Marchés     : Canada, France, USA, Côte d'Ivoire

Langues     : Français (défaut) + Anglais


## STACK TECHNIQUE

Framework  : Flutter 3.x + Dart null safety

State      : Riverpod (flutter_riverpod + riverpod_annotation) — anciennement Bloc/Cubit, migration effectuée

Navigation : go_router

Backend    : Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions)

Auth       : Google OAuth (PREMIER) + Email/Mot de passe
             // NOTE Apple Sign In : à ajouter en v1.1 (compte Apple Developer requis)

Paiements  : Stripe Connect UNIQUEMENT

Vidéo      : Cloudflare Stream (upload TUS direct)

Push       : Firebase FCM

Analytics  : PostHog (après consentement RGPD uniquement)

Monitoring : Sentry


## DESIGN — PALETTE SPOTBOOK

fond          : #0D0D14

surface       : #1E1E2E

surfaceAlt    : #16161F

border        : #2A2A3A

blanc         : #FFFFFF

gris          : #9090AA

grisInactif   : #555555

violet        : #6C3EF4

violetClair   : #8B63FF

rose          : #F43E8F

roseClair     : #FF6BAA

success       : #22C55E

error         : #FF4444

warning       : #FFBB33


Typographie :
  Titres h1/h2  : Clash Display (assets locaux)
  Corps / labels / boutons : DM Sans (google_fonts)
  Logo "Spotbook" : DM Sans bold, fontSize 20, blanc #FFFFFF — jamais coloré

Bouton primaire   : fond #6C3EF4 (violet), texte blanc, borderRadius 12

Bouton secondaire : fond #1E1E2E, texte blanc, bordure rgba(255,255,255,0.1), radius 12

Bouton danger     : fond rgba(244,62,143,0.12), texte #FF6BAA, radius 12


## RÔLES UTILISATEURS

CLIENT : Feed vidéo/photo, réservation, achat billets, chat avec pro,
         like/save/commenter posts, suivre des pros

Profil CLIENT : avatar + nom + handle + bio + localisation + bouton modifier
  Stats : RDV | Pros suivis | Événements | Avis
  Sections : Mes Pros favoris (scroll horizontal) + Historique récent
  Paramètres : Notifications, Paiement, Confidentialité, Langue, Mes avis, Devenir Pro

PRO    : Upload vidéo, gestion dispo, scanner QR, dashboard, stats

// !! Les interfaces CLIENT et PRO ne partagent JAMAIS un écran.
// !! Un utilisateur ne peut pas être les deux à la fois.


## ARCHITECTURE — CLEAN ARCHITECTURE STRICTE

lib/features/[feature]/data/         → Repositories (accès Supabase)

lib/features/[feature]/domain/       → Modèles et interfaces

lib/features/[feature]/presentation/ → Screens et Widgets

lib/shared/theme/                    → AppColors, AppTheme

lib/shared/widgets/                  → Widgets réutilisables

lib/shared/utils/                    → Services utilitaires

lib/router/                          → go_router

supabase/functions/                  → Edge Functions Deno/TypeScript

supabase/migrations/                 → Migrations SQL


## ORDRE INITIALISATION main.dart (CRITIQUE)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // 1er — TOUJOURS
  await Supabase.initialize(                  // 2e
    url: String.fromEnvironment("SUPABASE_URL"),
    anonKey: String.fromEnvironment("SUPABASE_ANON_KEY"),
  );
  await Firebase.initializeApp(              // 3e
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();                  // 4e
  runApp(const ProviderScope(child: SpotbookApp())); // DERNIER — wrapped in ProviderScope (Riverpod)
}

// !! Si cet ordre n'est pas respecté → crash au démarrage.


## LOGIN SCREEN — ORDRE

1. Bouton "Continuer avec Google"  (fond #1A1A1A, texte blanc)

2. Séparateur ─── ou ───

3. Champ Email + Mot de passe

4. Bouton "Se connecter"

5. Lien "Pas de compte ? S'inscrire" → RegisterScreen


## FLUX UTILISATEUR

SplashScreen
  → OnboardingScreen (3 slides — premier lancement uniquement)
    → LoginScreen / RegisterScreen
      → RoleSelectionScreen (si role IS NULL)
        → ClientOnboarding → /client/feed
        → ProOnboarding    → /pro/dashboard


## RÈGLES ABSOLUES — VIOLATIONS = PHASE REFUSÉE

// !! JAMAIS Supabase dans un Widget → Repository uniquement
// !! JAMAIS setState dans un écran → Riverpod (ConsumerWidget / ConsumerStatefulWidget) uniquement
// !! JAMAIS Image.network() → CachedNetworkImage
// !! JAMAIS Navigator.push() → context.go() go_router
// !! JAMAIS couleur hex dans Widget → AppColors.xxx
// !! JAMAIS clé API dans Flutter → String.fromEnvironment()
// !! JAMAIS PawaPay, Mobile Money, Orange Money, Wave, MTN MoMo
// !! JAMAIS Column + .map() pour des listes → ListView.builder
// !! JAMAIS sk_xxx Stripe dans Flutter → Edge Functions uniquement
// !! JAMAIS uploader vidéo via serveurs Spotbook → Cloudflare TUS direct
// !! JAMAIS calculer hash QR côté Flutter → Edge Function uniquement
// OK  TOUJOURS flutter analyze = 0 avant chaque commit
// OK  TOUJOURS const constructors
// OK  TOUJOURS dispose() les controllers vidéo
// OK  TOUJOURS idempotency_key sur chaque PaymentIntent
// OK  TOUJOURS vérifier auth.uid() == resource.owner côté serveur
// OK  TOUJOURS montants Stripe en centimes (x100)


## PAIEMENTS — RÈGLES CRITIQUES

payment_provider = "stripe" pour TOUS les users SANS EXCEPTION

Transfer Reversal OBLIGATOIRE si remboursement après payout au pro

Remboursement > 48h : stripe.refunds.create() + createReversal()

Remboursement < 48h : pro garde l'acompte

Commission réservation : 12% (8% si pro premium)

Commission événement   : 7%


## BASE DE DONNÉES

### Tables existantes (Pro + Shared)
users, profiles_pro, social_connections, services,
availability_rules, time_slots, bookings,
events, ticket_types, tickets, waitlist,
conversations, messages,
notifications, notification_preferences,
blocks, promo_codes, pro_subscriptions, referrals, reports

### Tables Client (nouvelles)
posts              — publications Pro (video/photo/event) avec caption, media, spotify track
post_likes         — likes sur posts (PK: post_id + user_id)
post_saves         — sauvegardes posts (PK: post_id + user_id)
post_comments      — commentaires sur posts (author_id, text, like_count)
comment_likes      — likes sur commentaires (PK: comment_id + user_id)
follows            — abonnements client→pro (PK: client_id + pro_id)
notifications_client — notifications client (type, title, body, ref_id, is_read)
reservations       — réservations client (status: pending/confirmed/done/cancelled)
ticket_purchases   — billets achetés (quantity, total_price, qr_code_url, status)
client_profiles    — profil client (display_name, handle, bio, avatar_url, location)
client_favorite_pros — pros favoris d'un client (PK: client_id + pro_id)
reviews            — avis client sur réservation (rating 1-5, comment)

// RLS activé sur toutes les tables.


## RÈGLES POSTS & VIDÉO — SPOTBOOK N'EST PAS TIKTOK

Seuls les Pros peuvent créer des posts (vidéo, photo, événement).

Chaque post vidéo DOIT représenter une prestation de service réelle.

Champs obligatoires : titre (5-80 chars) + catégorie (liste fermée) + description (min 20 chars)

Durée max vidéo : 60 secondes.

Toute vidéo passe par moderate-video avant publication.

Statuts : pending_review → approved (visible) | rejected | flagged (3 signalements)

Le feed n'affiche QUE les posts avec vidéos status = "approved".

TOP PRO : auto-approbation immédiate.

Un post peut être lié à un service (service_id) ou un événement (event_id).

Un post peut avoir un morceau Spotify (spotify_track_title + spotify_track_artist).

// !! Jamais afficher une vidéo sans status = "approved" dans le feed.
// !! Un client ne peut JAMAIS créer un post ou uploader une vidéo.
// !! Le bouton commenter est EXCLUSIF au feed Client (absent du ProFeedScreen).


## Design References — Maquettes Stitch

Dossier principal : design/stitch/

AUTH : design/stitch/auth/
  onboarding_discover.png, onboarding_book_attend.png, onboarding_create_earn.png,
  login_screen.png, sign_up_step_1..5.png, role_selection_screen.png,
  client_interest_categories.png, client_interest_goals.png, permission_location.png

CLIENT : design/stitch/client/
  feed_screen.png, discover_screen.png, bookings_screen.png, profile_screen.png,
  settings_screen.png, booking_step_1_service..6_confirmation.png,
  event_page_screen.png, ticket_purchase_screen.png, ticket_order_summary.png,
  ticket_digital_screen.png, favorites_screen.png, refund_request_screen.png

PRO : design/stitch/pro/
  dashboard_screen.png, feed_screen.png, search_screen.png, camera_screen.png,
  bookings_screen.png, profile_screen.png, performance_sales.png,
  ticket_sales_list.png, event_sales_management.png, qr_scanner_screen.png,
  create_event_details.png, create_event_date_location.png,
  create_event_media.png, create_event_pricing.png, create_event_publish.png,
  promo_codes_list.png, promo_code_add.png, my_qr_code.png,
  stripe_connect_setup.png, video_upload_progress.png, post_booking_review.png

SHARED : design/stitch/shared/
  notifications_screen.png, payment_receipt_1.png, payment_receipt_2.png,
  reschedule_select.png, reschedule_confirm.png, reschedule_notification.png,
  generated_screen_1..3.png

RÈGLE DESIGN : Consulter la maquette correspondante AVANT de coder un écran.
Le design Stitch fait autorité sur les layouts, espacements et couleurs.
AppColors doit refléter la palette Spotbook définie ci-dessus.

// !! Les layouts et espacements Stitch font autorité sur la structure.
// !! Toute couleur doit passer par AppColors.xxx — jamais de hex brut dans un Widget.


## ROUTING — SÉPARATION PRO / CLIENT

Auth provider vérifie AccountType au démarrage :
- AccountType.client → GoRouter redirige /client/feed
- AccountType.pro → GoRouter redirige /pro/feed
- Non authentifié → /auth/login

### Client Shell (4 onglets — PAS de bouton caméra)

| Index | Icône          | Label      | Route            |
|-------|----------------|------------|------------------|
| 0     | grid_2x2       | Feed       | /client/feed     |
| 1     | search         | Recherche  | /client/search   |
| 2     | calendar_today | Mes RDV    | /client/bookings |
| 3     | person         | Profil     | /client/profile  |

Routes supplémentaires Client :
- /client/booking/:serviceId/:proId → BookingScreen
- /client/ticket/:eventId → TicketPurchaseScreen
- /client/pro/:proId → ProPublicProfileScreen

### Pro Shell (5 onglets avec bouton caméra central)

| Index | Icône     | Label     | Route        |
|-------|-----------|-----------|--------------|
| 0     | grid_2x2  | Feed      | /pro/feed    |
| 1     | search    | Recherche | /pro/search  |
| 2     | camera    | (central) | /pro/camera  |
| 3     | calendar  | RDV       | /pro/rdv     |
| 4     | person    | Profil    | /pro/profile |


## CLIENT FEED — COMPORTEMENTS CRITIQUES

1. Feed temps réel : Supabase Realtime stream sur posts
   - Tab Découvrir = tous les posts récents
   - Tab Abonnements = posts des pros suivis (JOIN follows)

2. VideoPlayer : autoplay au snap PageView, pause au scroll, loop, dispose au destroy

3. Like / Save / Follow : optimistic update + sync Supabase en arrière-plan
   Rollback si erreur + SnackBar

4. Double tap : déclenche like si non liké + animation gros cœur 80px au centre

5. MusicTicker : visible seulement si post.spotifyTrackTitle != null

6. Bouton Commenter : EXCLUSIF Client (absent de ProFeedScreen)

7. Bouton caméra : ABSENT de la nav bar Client

8. Logo : Text "Spotbook" blanc #FFFFFF, DM Sans bold 20, jamais coloré


## LANCER L'APP

flutter run --dart-define-from-file=.env.json

flutter build ipa --release --dart-define-from-file=.env.json

flutter build appbundle --release --dart-define-from-file=.env.json
