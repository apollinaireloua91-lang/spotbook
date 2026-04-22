# APOLLINAIRE_TODO — Tâches humaines restantes

> Ce document liste les actions que **Claude ne peut pas exécuter**
> (approbations manuelles, accès physique à un device, décisions business,
> déploiements de production). Dernière mise à jour : **2026-04-21**.

---

## 🔴 Bloqueurs de release — à faire avant soumission App Store / Play Store

### 1. Capability Apple « Tap to Pay on iPhone »

- [ ] Ouvrir un ticket chez **Apple Developer Support**
- [ ] Demander l'ajout de la capability :
      `com.apple.developer.proximity-reader.payment.acceptance`
      (sur l'App ID `com.spotbook.app` ou équivalent)
- [ ] Joindre : lien App Store Connect + description du use case (« paiements
      sans contact pour prestations de service et événements, via Stripe
      Terminal SDK »)
- [ ] **Délai typique** : 5–15 jours ouvrés
- [ ] Sans cette approbation, tout build incluant l'entitlement échouera à
      l'upload — voir `ios/Runner/RunnerRelease.entitlements`

**Référence** :
  - Stripe docs : https://stripe.com/docs/terminal/payments/setup-integration?reader=tap-to-pay
  - Apple : `ProximityReader` framework

### 2. Activation Stripe Terminal côté dashboard

- [ ] Dashboard Stripe → Terminal → activer l'API pour le compte Connect plateforme
- [ ] Configurer `location_id` par défaut pour les tests et par Pro en prod
- [ ] Vérifier que le mode `test` ET `live` sont activés
- [ ] Régénérer les `connectionToken` Edge Function si nécessaire

### 2-bis. « Confirm email » — réactiver avant App Store

- [x] **Actuellement désactivé** (MVP — vérifié dashboard Supabase 2026-04-22).
      Auth → Sign In / Providers → User Signups → "Confirm email" = off.
      Permet au signup email/password de créer une session directe sans passer
      par la boîte mail (sinon `signUp` retourne `session == null` →
      `/complete-profile` kick vers /login, cf. `auth_repository.dart:109`).
- [ ] **À réactiver avant release App Store** : obligatoire pour éviter les
      comptes spam + valider la propriété de l'email.
- [ ] Quand réactivé, **coder en amont** un écran `/signup-confirm-email` qui :
      - explique « Un email a été envoyé à <email>, clique le lien »
      - propose un bouton « Renvoyer » (`authRepository.resendConfirmationEmail`)
      - propose un bouton « Retour login »
      - gère le deep-link `app.spotbook://login-callback` au retour du lien
        confirmé (session auto-créée → navigate direct vers /complete-profile)
- [ ] Le throw défensif `AuthException('Un e-mail de confirmation a été envoyé...')`
      dans `signUpWithEmail` reste comme filet de sécurité (voir commit 2026-04-22).

### 3. Apple Sign In (v1.1 selon CLAUDE.md)

- [ ] Compte Apple Developer payant actif → activer Sign In with Apple pour l'App ID
- [ ] Côté Flutter : intégrer `sign_in_with_apple` + flow Supabase OAuth
- [ ] Ajouter le bouton UI dans `login_screen.dart` entre Google et email
- [ ] Obligatoire si l'app propose un autre SSO (Google) d'après les guidelines Apple

### 4. iOS crash au démarrage (Chantier 1 non fait)

- [ ] Reproduire sur un device iOS physique (simulator peut masquer)
- [ ] Capturer le crash dump (`~/Library/Logs/DiagnosticReports`) ou la
      trace Xcode Organizer → Crashes
- [ ] Vérifier l'ordre exact d'initialisation dans `main.dart` vs ce que
      demande CLAUDE.md (WidgetsFlutterBinding → Supabase → Firebase → Hive → runApp)
- [ ] Si le crash est post-init : inspecter `SpotbookApp` + providers chargés
      en eager (bootstrap realtime, FCM, PostHog)

---

## 🟠 Tests device-dependent (Chantiers 6 + 7)

### 5. Stripe Terminal SDK Flutter — intégration runtime

- [ ] Ajouter `stripe_terminal` (plugin community) ou bridge natif custom
- [ ] Créer `lib/features/pos/data/terminal_service.dart` avec :
      - `discoverReaders()` (BT local + internet SBA)
      - `connectReader(readerId)`
      - `collectPaymentMethod(clientSecret)` → `processPayment()`
- [ ] Tester sur un **BBPOS WisePad 3** (ou équivalent) en mode `test`
- [ ] Tester le path **Tap to Pay** sur iPhone XS+ avec iOS 16.7+

### 6. TTP device-dependent QA

- [ ] Tester plusieurs modèles iPhone (XS, 12, 15 Pro)
- [ ] Tester une Visa + Mastercard + Amex + carte sans contact FR/CAD
- [ ] Tester un refund initié depuis l'app (ou confirmer qu'il faut passer par
      le dashboard Stripe — décision UX)
- [ ] Vérifier le comportement hors-ligne (le SDK accepte-t-il ?)

---

## 🟡 Décisions business (attente de Papy / stakeholder)

### 7. Politique d'annulation `strict` — conditions d'éligibilité

La policy `strict` est disponible (cf. `cancel-booking` Edge Function) mais
aucun service ne l'utilise aujourd'hui. **Décision attendue** : quels types
de prestation peuvent la sélectionner ? Faut-il une validation admin pour
l'autoriser sur un service ?

### 8. Frais de service client — arrondi

Actuellement `service_fee_client = 2.50 $` fixe. **Question** : faut-il
l'ajuster par devise ou par marché (France €2, CI 1000 XOF, etc.) ? Si oui,
il faut ajouter des colonnes `service_fee_client_eur`, `service_fee_client_xof`
à `app_config`.

### 9. Commission Pro événement vs réservation — cohérence

`commission_bookings = 18%`, `commission_events = 12%`. Décision : c'est
volontaire (événement = plus gros volume, moins de risque) ou artefact
historique ? Documenter dans CLAUDE.md.

### 10. Waitlist — politique de notification

Quand une place se libère (annulation billet), qui prévenir ? Le premier
de la waitlist uniquement, ou tous avec un timer ? Combien de temps lui
laisser avant de notifier le suivant ? **Edge Function à concevoir** :
`waitlist-promote` (appelée par webhook Stripe sur refund).

---

## 🟢 Ops / Infra

### 11. Rotation des clés injectées en build

- [ ] Rotate `MAPS_API_KEY` (désormais via `android/local.properties`) — l'ancienne
      `AIzaSyC2dCh1egkwgqDx-o5mnPlAbYWOtNPd_v8` a été exposée dans l'historique git
- [ ] Restrict la nouvelle clé par bundle ID + SHA-1 dans Google Cloud Console
- [ ] Idem Stripe publishable key → restrict par domain si webhook

### 12. Monitoring Edge Functions

- [ ] Configurer alertes Sentry sur les Edge Functions critiques :
      - `purchase-tickets-atomic` (erreurs > 1% → page)
      - `cancel-booking` (REFUND_PENDING_RETRY > 0 sur 5 min → page)
      - `stripe-create-intent` / `stripe-create-ticket-intent` (5xx)
- [ ] Dashboard Supabase → alertes on connection pool > 80%

### 13. Supabase — migration `db push`

Claude ne déclenche jamais `supabase db push`. Toutes les migrations créées
dans cette session (`20260421100000_*` → `20260421140000_*`) sont en attente :

```bash
supabase db push                     # applique en prod
supabase migration up --local        # teste en local d'abord
```

### 14. Edge Functions — déploiement

Claude ne déclenche jamais `supabase functions deploy`. Fonctions à déployer :

```bash
supabase functions deploy purchase-tickets-atomic --no-verify-jwt
supabase functions deploy join-waitlist-atomic
supabase functions deploy cancel-booking
supabase functions deploy cancellation-policy
supabase functions deploy send-message-notification
```

⚠ `--no-verify-jwt` **uniquement** pour les fonctions qui valident le JWT
manuellement (cf. CLAUDE.md memory `feedback_no_config_push`).

---

## Annexes

### Chantiers non exécutés (bloqués par contraintes Claude)

| Chantier | Pourquoi |
|---------|----------|
| 1 — iOS crash | nécessite device physique + debug Xcode |
| 6 — Stripe Terminal SDK | nécessite device + SDK natif à intégrer |
| 7 — Apple TTP runtime | bloqué par capability Apple (cf. §1) |

### Chantiers exécutés — récap commits

Voir `git log --oneline agent/refonte-totale-premium` pour la liste complète.
Branches affectées : `supabase/migrations/2026042110*` à `140*`,
`supabase/functions/{purchase-tickets-atomic,join-waitlist-atomic,cancel-booking,cancellation-policy,send-message-notification}`,
`lib/features/{auth,booking,chat,events,feed,profile}/**`, native configs.
