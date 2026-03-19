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

State      : Riverpod 2.x — AsyncNotifier UNIQUEMENT

Navigation : go_router

Backend    : Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions)

Auth       : Google OAuth (PREMIER) + Email/Mot de passe
             // NOTE Apple Sign In : à ajouter en v1.1 (compte Apple Developer requis)

Paiements  : Stripe Connect UNIQUEMENT

Vidéo      : Cloudflare Stream (upload TUS direct)

Push       : Firebase FCM

Analytics  : PostHog (après consentement RGPD uniquement)

Monitoring : Sentry


## DESIGN — NOIR ET BLANC STRICT

fond        : #000000

surface     : #111111

surfaceAlt  : #1A1A1A

border      : #2A2A2A

blanc       : #FFFFFF

gris        : #888888

grisClair   : #CCCCCC

success     : #00C851

error       : #FF4444

warning     : #FFBB33


Bouton primaire   : fond blanc, texte noir, borderRadius 12

Bouton secondaire : fond #1A1A1A, texte blanc, bordure #2A2A2A, radius 12

// !! Jamais de violet, cyan, ou toute autre couleur décorative.


## RÔLES UTILISATEURS

CLIENT : Feed vidéo, réservation, achat billets, chat avec pro

Profil CLIENT : cover + avatar + nom + username + ville + bouton modifier
  3 onglets : Favoris | Historique RDV | Mes Billets
  // !! Pas d'abonnés, pas de following, pas de réseaux sociaux, pas de stats

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
  runApp(const ProviderScope(child: SpotbookApp())); // DERNIER
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
// !! JAMAIS setState dans un écran → Riverpod AsyncNotifier
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


## BASE DE DONNÉES — 25 TABLES

users, profiles_pro, social_connections, services,
availability_rules, time_slots, bookings,
videos, video_likes, video_comments,
events, ticket_types, tickets, waitlist,
conversations, messages,
notifications, notification_preferences,
favorites, follows, blocks, reviews,
promo_codes, pro_subscriptions, referrals, reports

// RLS activé sur toutes les tables.


## RÈGLES VIDÉO — SPOTBOOK N'EST PAS TIKTOK

Seuls les Pros peuvent uploader des vidéos.

Chaque vidéo DOIT représenter une prestation de service réelle.

Champs obligatoires : titre (5-80 chars) + catégorie (liste fermée) + description (min 20 chars)

Durée max : 60 secondes.

Toute vidéo passe par moderate-video avant publication.

Statuts : pending_review → approved (visible) | rejected | flagged (3 signalements)

Le feed n'affiche QUE les vidéos status = "approved".

TOP PRO : auto-approbation immédiate.

// !! Jamais afficher une vidéo sans status = "approved" dans le feed.
// !! Un client ne peut JAMAIS uploader une vidéo.


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
Le design Stitch fait autorité sur les layouts et espacements.
Si une couleur dans les maquettes diffère de AppColors → signaler avant de coder.

// !! ATTENTION : Les maquettes utilisent un accent cyan (#00D4FF) et du violet (#7B61FF).
// !! La charte Spotbook est NOIR ET BLANC STRICT. AppColors fait autorité sur les couleurs.
// !! Les layouts et espacements Stitch font autorité sur la structure.


## LANCER L'APP

flutter run --dart-define-from-file=.env.json

flutter build ipa --release --dart-define-from-file=.env.json

flutter build appbundle --release --dart-define-from-file=.env.json
