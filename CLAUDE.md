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

Auth       : Google OAuth (PREMIER) + Apple Sign In (iOS natif) + Email/Mot de passe

Paiements  : Stripe Connect UNIQUEMENT

Vidéo      : Cloudflare Stream (upload TUS direct)

Push       : Firebase FCM

Analytics  : PostHog (après consentement RGPD uniquement)

Monitoring : Sentry


## DESIGN — PALETTE SPOTBOOK

### Dark Mode (défaut sur feeds vidéo)
fond          : #000000    (noir pur — true black)
surface       : #121218    (presque noir, touche bleutée subtile)
surfaceAlt    : #0A0A10    (entre noir et surface)
surfaceElev   : #1A1A26    (éléments élevés)
border        : #1E1E2E    (bordures subtiles)
navBar        : #000000    (noir pur)

### Light Mode
fond          : #F5F5F3    (gris chaud très clair)
surface       : #FFFFFF    (blanc pur)
surfaceAlt    : #F7F7F5    (off-white)
border        : #E5E5E5    (gris clair)

### Couleurs partagées (s'adaptent automatiquement via AppColors)
violet (dark)   : #8E05C2  — primary accent, deep purple
violet (light)  : #8039C5  — primary accent, classic purple
violetClair     : #A855F7 (dark) / #9B5DD6 (light)
rose            : #F43E8F
roseClair       : #FF6BAA
success         : #22C55E
error / danger  : #EF4444
warning         : #FFBB33
logout          : #EF4444  (rouge — toujours rouge, les deux modes)

### Texte
blanc (dark)    : #FFFFFF
blanc (light)   : #0C0C0C
gris (dark)     : #A0A0B8  (lumineux pour lisibilité sur noir)
gris (light)    : #6B6B6B
grisInactif     : #555566 (dark) / #B0B0B0 (light)

### Gradients
gradientAccent dark  : #700B97 → #8E05C2
gradientAccent light : #7030B0 → #9B5DD6

### Glow (dark mode uniquement)
glow            : #8E05C2  (neon purple)
glowLight       : #A855F7

Typographie :
  Titres h1/h2  : Sora (google_fonts) — remplace Clash Display
  Corps / labels / boutons : DM Sans (google_fonts)
  Logo "Spotbook" : DM Sans bold, fontSize 20, blanc #FFFFFF — jamais coloré

Bouton primaire   : gradient #700B97→#8E05C2 (dark) / #7030B0→#9B5DD6 (light), texte blanc, borderRadius 14, glow shadow en dark

Bouton secondaire : fond surface, texte blanc, bordure border, radius 12

Bouton danger     : fond rgba(239,68,68,0.08), texte #EF4444, bordure rgba(239,68,68,0.24), radius 12

Bouton logout     : fond rgba(239,68,68,0.08), texte #EF4444, icône logout_rounded, radius 12


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
// !! JAMAIS couleur hex dans Widget → AppColors.xxx (dark/light adaptatif)
// !! JAMAIS const Color(0xFF...) dans un widget → AppColors.xxx (sauf Colors.white/black pour éléments invariants)
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

// ⚠ LE SEUIL 48h CONCERNE LE PAYOUT STRIPE, PAS LA POLITIQUE D'ANNULATION.
// Au-delà de 48h après le paiement, les fonds sont déjà transférés au Pro
// → un refund nécessite stripe.transfers.createReversal(). En-dessous de 48h,
// le simple stripe.refunds.create() suffit (fonds toujours sur la plateforme).
// Voir supabase/functions/cancel-booking/index.ts L144-149.

Refund > 48h après paiement : stripe.refunds.create() + transfers.createReversal()
Refund ≤ 48h après paiement : stripe.refunds.create() uniquement

// NE PAS CONFONDRE avec le seuil 24h ci-dessous (politique d'annulation).

Commission réservation : 18%

Commission événement   : 12%

Commission traiteur    : 18%

Frais de service client : 2.50 $/réservation

Acompte (deposit) : configurable PAR SERVICE uniquement (pas de valeur globale par défaut)
  → payment_mode : 'full' | 'deposit'
  → deposit_type : 'percentage' | 'fixed'
  → deposit_value : 10–30% (max 30%, contraint par CHECK SQL)

Politique annulation (déclarée par service dans `services.cancellation_policy`) :
  moderate  → 100 % remboursé si >24h avant le RDV, sinon 50 % remboursé (défaut)
  strict    → 0 % remboursé (acompte + total gardés par le Pro)

// ⚠ La policy `flexible` a été retirée (migration 20260420170000_remove_flexible_cancellation).
//    Toute valeur non reconnue en DB tombe sur `moderate` côté Edge Function.
// Source de vérité : supabase/functions/cancel-booking/index.ts (constante POLICY)
// + endpoint GET `cancellation-policy` pour que l'UI affiche la même chose
// que ce qui sera effectivement appliqué.

// Pas de tiers premium — même taux pour tous les Pros.
// Taux configurables UNIQUEMENT via table app_config :
//   commission_bookings, commission_events, commission_catering, service_fee_client
// Flutter les lit via `appConfigProvider` (lib/core/services/app_config_provider.dart) —
// ne JAMAIS hardcoder 0.18 / 0.12 / 2.50 dans un widget.


## BASE DE DONNÉES

### Tables existantes (Pro + Shared)
users, profiles_pro, social_connections, services,
availability_rules, time_slots, bookings,
events, ticket_types, tickets, waitlist,
conversations, messages,
notifications, notification_preferences,
blocks, promo_codes, referrals, reports, app_config

### Tables Client (nouvelles)
videos             — publications vidéo des Pros (ex-« posts ») avec caption,
                     media, spotify_track_title/artist, status (approved par défaut)
video_likes        — likes sur vidéos (PK: video_id + user_id)
post_saves         — sauvegardes vidéos (FK → videos.id, PK user_id + post_id)
video_comments     — commentaires sur vidéos (author_id, text, like_count)
comment_likes      — likes sur commentaires (PK: comment_id + user_id)
follows            — abonnements client→pro (PK: follower_id + following_id)
notifications_client — notifications client (type, title, body, ref_id, is_read)
favorites          — favoris génériques (target_type IN ('pro','service','event'))
client_favorite_pros — pros favoris d'un client (PK: client_id + pro_id) —
                     redondance historique avec favorites(target_type='pro'),
                     conservée pour compat code Flutter existant
client_profiles    — profil client (display_name, handle, bio, avatar_url, location)
reviews            — avis client sur réservation (rating 1-5, comment)

// ⚠ Tables listées dans d'anciens audits mais INEXISTANTES en DB :
//   `posts`, `post_likes`, `post_comments`, `reservations`, `ticket_purchases`.
//   Les vues Flutter utilisent respectivement : `videos`, `video_likes`,
//   `video_comments`, `bookings`, `tickets`. Le RPC `delete_account_rpc`
//   contient des DELETE wrappés dans `BEGIN/EXCEPTION WHEN undefined_table`
//   pour ces phantom tables — no-op sûr.
// Voir docs/AUDIT_REPORT_CORRECTIONS.md §1 pour l'historique.

// RLS activé sur toutes les tables.


## RÈGLES VIDÉOS — SPOTBOOK N'EST PAS TIKTOK

// Table réelle : `videos` (et NON `posts`). Historiquement décrites comme
// « posts » dans les specs → utiliser le terme « vidéo » dans le code et
// la doc pour rester aligné avec la DB.

Seuls les Pros peuvent créer des vidéos.

Chaque vidéo DOIT représenter une prestation de service réelle.

Champs obligatoires : titre (5-80 chars) + catégorie (liste fermée) + description (min 20 chars)

Durée max vidéo : 2 minutes (120 secondes).

Les vidéos sont publiées immédiatement avec status = "approved" (pas de modération).

Le feed n'affiche QUE les vidéos avec status = "approved".

Une vidéo peut être liée à un service (service_id) ou un événement (event_id).

Une vidéo peut avoir un morceau Spotify (spotify_track_title + spotify_track_artist).

// !! Jamais afficher une vidéo sans status = "approved" dans le feed.
// !! Un client ne peut JAMAIS créer une vidéo ou uploader un média.
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

1. Feed temps réel : Supabase Realtime stream sur `videos` (table réelle)
   - Tab Découvrir = getScoredVideos() / getMoreVideos()
   - Tab Abonnements = getFollowingFeed() (JOIN follows.following_id)

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


## LAST VERIFIED — 2026-04-21

Cette section doit être mise à jour à chaque resync majeure de CLAUDE.md.
Resync précédente : pre-refonte-totale-premium (date inconnue).

Divergences connues résolues dans cette resync :
- Table `posts` → `videos` dans la doc (la DB n'a jamais eu `posts`)
- Policy `flexible` retirée (migration 20260420170000)
- Seuil 48h (payout Stripe) distingué du seuil 24h (politique annulation)
- Phantom tables `post_likes`, `post_comments`, `reservations`, `ticket_purchases`
  marquées comme n'existant pas en DB (cf. delete_account_rpc avec EXCEPTION)
- Commission rates : source unique `appConfigProvider`, jamais hardcodés

Voir docs/AUDIT_REPORT_CORRECTIONS.md pour l'historique complet des divergences
audit-vs-réalité et docs/APOLLINAIRE_TODO.md pour les tâches humaines restantes.


## KNOWN QUIRKS

Petits comportements qui déroutent si on ne les connaît pas.

1. **delete_account_rpc et phantom tables** — La fonction RPC
   `delete_account_rpc` contient des DELETE sur des tables qui n'existent
   peut-être plus (`post_likes`, `post_comments`, etc.), wrappés dans
   `BEGIN ... EXCEPTION WHEN undefined_table THEN NULL`. C'est volontaire,
   ne pas « nettoyer » sans vérifier les autres environnements.

2. **Apple Sign In** — Implémenté end-to-end (flow natif iOS via
   `sign_in_with_apple`). Code: `lib/features/auth/data/auth_repository.dart`
   (`signInWithApple()` avec nonce SHA-256 + `signInWithIdToken`). Entitlement
   `com.apple.developer.applesignin` actif sur Runner.entitlements +
   RunnerRelease.entitlements. Provider Apple activé dans Supabase Dashboard
   (Client ID = `com.getspotbook.spotbook` = bundle ID, pas de Service ID
   séparé pour le flow natif iOS-only). Le `full_name` Apple n'est renvoyé
   qu'à la PREMIÈRE connexion → persisté dans `profiles` à ce moment-là.
   Test physique iOS (avec compte iCloud) requis pour validation finale.

3. **Commission = 18 % bookings ≠ 12 % events** — Volontaire. Les événements
   sont des volumes plus importants, moins de risque d'annulation tardive.
   À confirmer avec stakeholder (cf. APOLLINAIRE_TODO §9).

4. **`services.deposit_value` CHECK 10-30%** — Contrainte SQL déjà en place
   (pas besoin de la ré-appliquer au niveau Flutter, mais l'UI doit valider
   côté client pour le feedback utilisateur).

5. **`tickets` INSERT** — Seul le `service_role` peut insérer dans `tickets`
   depuis la migration 20260421120000. Client Flutter passe OBLIGATOIREMENT
   par l'Edge Function `purchase-tickets-atomic` qui re-vérifie les metadata
   du PaymentIntent Stripe avant insert.

6. **`waitlist` concurrency** — Ne jamais faire `count + upsert` côté client
   (race condition). Utiliser l'Edge Function `join-waitlist-atomic` qui
   sérialise via `pg_advisory_xact_lock(hashtext(ticket_type_id))`.

7. **Fraction de remboursement** — Ne pas calculer côté Flutter. L'Edge
   Function `cancel-booking` renvoie `{policy, hoursThreshold, refundFraction,
   refundAmount}` → l'UI doit afficher ces valeurs telles quelles. Pour un
   affichage pré-soumission, utiliser le GET `/cancellation-policy`.

8. **MAPS_API_KEY Android** — Injectée via `manifestPlaceholders` depuis
   `android/local.properties` (non commité). L'ancienne clé en dur dans
   le manifest a été retirée — pensez à rotater si l'historique git est
   public (cf. APOLLINAIRE_TODO §11).

9. **l10n ARB-first** — Ne JAMAIS éditer `app_localizations*.dart` à la main.
   Éditer les `.arb`, puis `flutter gen-l10n`. Cf. memory
   `feedback_l10n_arb_source.md`.

10. **Pas de `supabase db push` ni `functions deploy` automatique** — Claude
    ne déclenche jamais ces commandes (risque d'écraser le dashboard /
    surcharger les triggers). L'humain les lance manuellement après revue.
