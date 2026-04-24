# APOLLINAIRE_TODO — Tâches humaines restantes

> Ce document liste les actions que **Claude ne peut pas exécuter**
> (approbations manuelles, accès physique à un device, décisions business,
> déploiements de production). Dernière mise à jour : **2026-04-24**.

---

## 🔴 Bloqueurs de release — à faire avant soumission App Store / Play Store

### 1. Capability Apple « Tap to Pay on iPhone »

> **Statut 2026-04-23** : capability **ACCORDÉE** par Apple (Hanumath Sai,
> Wallet Entitlements — Case **#19552730**), avec restriction de distribution
> dev-only en attendant validation des 3 vidéos de démo + check-list de
> revue applicative. Entitlement
> `com.apple.developer.proximity-reader.payment.acceptance` **ACTIF** dans
> `ios/Runner/RunnerRelease.entitlements`.
>
> **🚨 Bundle ID typo en cours de correction** : la réponse d'Apple
> référence `com.spotbook.spotbook` au lieu du vrai `com.getspotbook.spotbook`.
> Mail de correction envoyé à Hanumath le **2026-04-23** (cf.
> `docs/APPLE_REPLY_BUNDLE_ID_CORRECTION.md`). Ne PAS soumettre les vidéos
> tant que le bon App ID n'a pas été confirmé par Apple.

- [x] ~~Ouvrir un ticket Apple Developer Support~~ → fait (Case #19552730).
- [x] ~~Demander la capability `com.apple.developer.proximity-reader.payment.acceptance`~~
      → **accordée** (dev-only).
- [ ] **Recevoir la confirmation d'Apple que la capability est bien sur
      `com.getspotbook.spotbook`** (réponse au mail du 2026-04-23 attendue
      sous 1-3 jours ouvrés). Escalader à J+5 sur le même fil si pas de retour.
- [ ] Lire les 2 documents Apple Box :
      `https://apple.box.com/v/ttpoirequirements`
      → App Requirements + App Review Checklist
- [ ] Tourner les **3 vidéos de démo** (iPhone physique, pas simulator) :
      - New User Journey : création compte Pro + onboarding Stripe Connect
        + premier encaissement Tap to Pay
      - Existing User Flow : Pro existant qui se connecte → écran
        d'encaissement
      - Checkout Flow : focus UX paiement (saisie montant → tap → reçu)
- [ ] Remplir l'App Review Requirements Checklist (joindre les 3 vidéos).
- [ ] Renvoyer la check-list complétée à Apple sur le même fil
      (Case #19552730) pour lever la restriction dev-only.
- [ ] **Tester en prod sur iPhone physique** (XS+ avec iOS 16.7+) une fois
      la restriction dev-only levée : flow Stripe Terminal `discoverReaders`
      → Tap-to-Pay reader → `collectPaymentMethod` → `processPayment`.
      Vérifier qu'une carte sans contact réelle est acceptée.

**Bloquants côté code (pas encore intégré)** :
- Edge Function `stripe-terminal-connection-token` : ✅ codée et committée
  (`supabase/functions/stripe-terminal-connection-token/index.ts`).
- SDK Flutter `mek_stripe_terminal` : ❌ pas encore dans `pubspec.yaml`.
- Écran POS Pro `/pro/pos` : ❌ à coder (saisie montant → discover reader
  → collect payment → afficher reçu).

**Référence** :
  - Stripe docs : https://stripe.com/docs/terminal/payments/setup-integration?reader=tap-to-pay
  - Apple : `ProximityReader` framework
  - Case Apple : #19552730 — Hanumath Sai, Wallet Entitlements

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

### 4-bis. Push notifications Pro — Vault + migrations + validation runtime

> **Contexte** : Phase A — diagnostic complet dans
> `docs/PRO_NOTIFICATIONS_AUDIT.md`. Le code Flutter et les migrations SQL
> ont été livrés (commits `fix(push)` / `feat(push)` / `chore(push)`
> 2026-04-24), mais **la cascade push reste cassée tant que les secrets
> Vault ne sont pas créés sur la base distante**. Sans ces deux secrets,
> la helper `fire_send_push_notification` exit silencieusement
> (RAISE LOG + RETURN).
>
> **⚠ Update 2026-04-24** : la voie GUC (`ALTER DATABASE postgres SET
> app.settings.X`) initialement prévue est **bloquée par Supabase Cloud**
> (`permission denied (42501)` — superuser-only). On bascule sur Vault
> (extension `supabase_vault`, vue `vault.decrypted_secrets`) — voir
> migration `20260424130000_migrate_push_config_to_vault.sql`.

- [ ] **Créer les secrets Vault en prod** (Supabase Dashboard → SQL editor) :
      ```sql
      SELECT vault.create_secret(
        '<service_role_key>',
        'service_role_key',
        'Service role key used by fire_send_push_notification helper'
      );
      SELECT vault.create_secret(
        'https://vvczayvrurgfabnkxfap.supabase.co/functions/v1/send-push-notification',
        'push_function_url',
        'URL of the send-push-notification Edge Function'
      );
      ```
      Le `service_role_key` est dans Supabase Dashboard → Settings → API →
      `service_role` `secret`. **Ne jamais commit ce secret.**
- [ ] **Vérifier la présence des secrets** (même SQL editor) :
      ```sql
      SELECT name FROM vault.secrets
      WHERE name IN ('push_function_url', 'service_role_key');
      ```
      Doit retourner **2 rows**. Si moins → re-créer le manquant.
- [ ] **Vérifier que la helper lit bien les secrets** :
      ```sql
      -- Force un appel manuel sur ton propre user pour smoke-test :
      SELECT public.fire_send_push_notification(
        auth.uid(),
        'Test Vault',
        'Smoke test depuis SQL editor',
        'message',
        '{"route":"/notifications"}'::jsonb
      );
      -- Puis vérifier les logs Edge Functions :
      --   Dashboard → Functions → send-push-notification → Logs
      -- Doit montrer une invocation 200 dans les ~10 s suivantes.
      ```
- [ ] **Appliquer les deux migrations** dans l'ordre :
      ```bash
      supabase db push
      ```
      Migrations concernées :
        - `20260424120000_fix_push_notification_route_per_role.sql` (route /pro vs /client)
        - `20260424130000_migrate_push_config_to_vault.sql` (Vault au lieu de GUC)
- [ ] **Tester sur iPhone Pro physique** :
      - Connecter un compte Pro et un compte client (sur 2 devices ou
        2 comptes du même device).
      - Depuis le client, ouvrir une conversation existante (ou créer
        via flow réservation) et envoyer un message texte.
      - **Vérifier sur le device Pro** :
        - [ ] Push FCM reçue (banner OS) **app au foreground**.
        - [ ] Push FCM reçue (banner OS) **app en background**.
        - [ ] Tap sur le push → ouvre `/pro/messages` (et non `/client/messages`).
        - [ ] Le banner Material en foreground (CTA « Voir le message »)
              s'affiche dans l'app et navigue correctement au tap.
        - [ ] Badge unread sur la nav bar Pro se met à jour live (sans
              redémarrer l'app), via Realtime.
- [ ] **Vérifier en DB** :
      ```sql
      SELECT user_id, type, title, push_sent, created_at
      FROM notifications
      WHERE user_id = '<pro_uid>'
      ORDER BY created_at DESC
      LIMIT 10;
      ```
      - Confirmer qu'il y a **2 rows** par message (1 du trigger via EF
        avec `push_sent=true`, 1 de Flutter `_notifyRecipient` —
        comportement transitoire).
      - `push_sent` doit être `true` pour la row EF (sinon le FCM token
        est probablement invalide/stale).
- [ ] **Une fois validation runtime faite**, créer un commit qui
      supprime `chat_repository._notifyRecipient` (et son call site
      L117) pour éliminer les doublons. Voir commentaire en place dans
      `lib/features/chat/data/chat_repository.dart:117` qui pointe vers
      cette TODO.

> **Diagnostic complet** : `docs/PRO_NOTIFICATIONS_AUDIT.md`.
> **Commits Phase A** :
>   - `fix(push)`: route FCM par rôle (migration SQL)
>   - `fix(messages)`: aligner _notifyRecipient avec EF
>   - `feat(push)`: wire FCM foreground/tap/cold-start handlers

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

---

## Déploiements manuels requis (refonte booking 2026-04-22)

- [ ] **Migration DB** : `supabase/migrations/20260422100000_bookings_push_only_on_confirmed.sql`
      → à pousser avec `supabase db push` avant le prochain test iPhone.
      Sans ça, le Pro continue de recevoir une notif push FCM "Nouvelle
      réservation" dès qu'un client initie un booking (avant paiement),
      même si le paiement n'est jamais finalisé.
      Cf. `docs/BOOKING_FLOW_REFONTE_PLAN.md` §P2 + commit 2.

- [ ] Vérifier **manuellement** après push : créer un booking test, vérifier
      que le Pro ne reçoit PAS de push, puis confirmer le paiement et vérifier
      que le push arrive alors. Si le trigger se déclenche deux fois ou pas
      du tout, rollback avec :
      ```sql
      DROP TRIGGER IF EXISTS tr_bookings_push_on_confirmed ON bookings;
      CREATE TRIGGER tr_bookings_push_after_insert
        AFTER INSERT ON bookings FOR EACH ROW
        EXECUTE FUNCTION tr_notify_new_booking_push();
      ```

### Chantiers exécutés — récap commits

Voir `git log --oneline agent/refonte-totale-premium` pour la liste complète.
Branches affectées : `supabase/migrations/2026042110*` à `140*`,
`supabase/functions/{purchase-tickets-atomic,join-waitlist-atomic,cancel-booking,cancellation-policy,send-message-notification}`,
`lib/features/{auth,booking,chat,events,feed,profile}/**`, native configs.

---

## Migration emails Resend — tâches staged (2026-04-22)

Contexte : Phase 0 Commit 1 de la migration `buildEmail` HTML → Resend
templates (via nested `template: { id, variables }`). Détails complets dans
`docs/EMAIL_MAPPING_AUDIT.md`. **Claude ne pousse aucune migration SQL ni
deploy de fonction** — tout est listé ici pour exécution manuelle.

### 15. SQL staged — à pousser APRÈS Commit 3 (nouveaux cron email)

Les deux colonnes ci-dessous sont nécessaires aux nouveaux events `reminder_1h_before`
et `remaining_payment_reminder` (décisions 4.3 et 4.5). **Ne PAS les créer avant
que le code Commit 3 soit mergé** — sinon le cron s'exécuterait avec la nouvelle
colonne mais sans l'email correspondant.

```sql
-- 15.a — Renommage flag H-2 → H-1 (décision 4.3 Option A)
-- Le cron schedule-reminders/send-reminders utilise actuellement un delta 2h.
-- On aligne sur l'alias Resend `rappel-1h-avant`.
-- À pousser AU MÊME COMMIT que le changement de code (delta 2h → 1h) pour éviter
-- les bookings en zombie (row avec nouveau flag mais ancien delta, ou l'inverse).
ALTER TABLE bookings
  RENAME COLUMN reminder_h2_sent TO reminder_h1_sent;

-- 15.b — Flag solde restant à payer (décision 4.5 Option A)
-- Cron J-1 pour bookings payment_mode='deposit' dont le RDV est dans ≤24h.
-- Dedup via ce flag, remis à true après envoi du template `solde-restant-payer`.
ALTER TABLE bookings
  ADD COLUMN remaining_reminder_sent BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_bookings_remaining_reminder_pending
  ON bookings (scheduled_at)
  WHERE payment_mode = 'deposit'
    AND remaining_reminder_sent = false
    AND status IN ('confirmed', 'pending_deposit');
```

**Vérifier avant push** :
- [ ] `reminder_h2_sent` existe bien en DB (sinon adapter la migration — cf. décision 4.3).
- [ ] Le nom réel de la colonne `payment_mode` (booking vs services vs payments).
- [ ] Tester `supabase migration up --local` avant `supabase db push`.
- [ ] Pas d'email `message_notification` → **pas** de table `email_log` à créer
      (décision 4.7 annule le besoin initial de throttle 1/h/thread).

### 16. Migration Supabase Auth → Resend (hors périmètre 4 commits)

Templates Resend existants mais non câblés : `rinitialisation-mot-de-passe`,
`vrification-email`. Supabase Auth utilise son SMTP built-in par défaut.

- [ ] Évaluer si on bascule sur **Auth Email Hooks** (Supabase feature) pour
      router via Resend → cohérence visuelle avec les transactional mails.
- [ ] Si oui : créer une EF `send-auth-email` + config Auth Hook via dashboard
      (jamais via `supabase config push` — cf. memory `feedback_no_config_push`).
- [ ] Décision à prendre post-release : confort visuel vs risque de régression
      sur un flow critique (reset mot de passe).

### 17. Detection login suspect (`connexion-suspecte`)

- [ ] Feature non implémentée. Template Resend existe côté dashboard mais
      aucun backend ne détecte les logins inhabituels (IP inconnue, device
      nouveau, pays différent).
- [ ] Conception : trigger `auth.login` → table `login_events` avec IP+UA+country.
      Heuristique : signaler si country ≠ dernier login réussi (fenêtre 30j).
- [ ] **Post-v1** — pas dans la roadmap actuelle.

### 18. Reschedule booking — feature backend manquante

- [ ] Template Resend `rendez-vous-reprogramm` publié mais **aucune EF**
      `reschedule-booking` n'existe, aucun champ DB pour proposer un nouveau
      créneau sans annuler-re-créer.
- [ ] Décision prise : **ne pas câbler l'email** tant que la feature backend
      n'existe pas (décision 4.6).
- [ ] Quand le backend sera ajouté (post-v1 ?) : mettre à jour
      `resend_template_aliases.ts` en ajoutant `booking_rescheduled` dans
      `EmailEventKey` et `RESEND_TEMPLATES`, retirer de `KNOWN_UNWIRED_ALIASES`.

### 19. Rappel Stripe Connect incomplet (`rappel-stripe-connect`)

- [ ] Cron journalier : pour chaque Pro avec `stripe_onboarded = false` depuis
      > 48h, envoyer le template `rappel-stripe-connect` (pas encore dans
      `RESEND_TEMPLATES` — à ajouter si on câble).
- [ ] **Post-Commit 4** — priorité basse, mais améliore le conversion funnel
      Pro → compte activé → paiements acceptés.
- [ ] Nouvelle EF `pro-stripe-connect-reminder` + entrée crontab Supabase.

### 20. Catering / devis — vérifier si feature existe

- [ ] 4 templates Resend publiés : `soumission-reue`, `soumission-accepte-pro`,
      `soumission-refuse-pro`, `soumission-expire`.
- [ ] **Action** : vérifier en DB s'il existe une table `quotes` /
      `catering_requests` / similaire. Grep repo pour usages du mot
      « soumission » / « devis » / « quote ».
- [ ] Si la feature existe mais n'est pas wired email → Commit 5 ou +.
- [ ] Si la feature n'existe pas → les templates Resend peuvent rester en
      draft en attendant.

### 21. Fusion `schedule-reminders` vs `send-reminders` — risque prod

Deux crons écrivent sur les **mêmes flags DB** (`reminder_j1_sent`,
`reminder_h2_sent`/`_h1_sent`, `reminder_m30_sent`) sans coordination :

- `schedule-reminders/index.ts` : email J-1 + push J-1/H-2 client+pro.
- `send-reminders/index.ts` : push only 24h/2h/30min via insert `notifications`.

Race potentielle : les deux tournent au même moment, flip le flag, envoient
en double ou ratent un envoi si la course est perdue.

- [ ] **Hors périmètre migration email**, mais à flagger comme risque.
- [ ] Option A : fusionner dans `schedule-reminders` uniquement, retirer
      `send-reminders` (ses inserts de notifications peuvent migrer).
- [ ] Option B : garder les deux mais ajouter un verrou `pg_advisory_xact_lock`
      sur `hashtext(booking_id::text)` avant de flip le flag.
- [ ] Décider avant Commit 3 (le renommage H-2 → H-1 va toucher les deux).

### 22. Cohérence `account_deactivated` avec `delete_account_rpc`

- [ ] Template `compte-dsactiv` (id `0ee5e562…`) wire en Commit 4.
- [ ] Déclenchement : **avant** l'appel Flutter à `delete_account_rpc` — sinon
      la row `users` est purgée et on perd l'email destinataire.
- [ ] Option implémentation : EF `request-account-deletion` qui envoie l'email
      puis appelle le RPC. Éviter de séquencer côté client (fragile).

### 23. Aliases Resend manquants à créer (Commit 3)

Commit 3 a câblé des `event` keys qui pointent vers des aliases Resend **pas
encore publiés dans le dashboard**. Le wrapper `sendResendEmail` retombe
automatiquement sur le builder HTML existant (`buildEmail`) — aucun blocage
fonctionnel — mais l'expérience visuelle du template Resend est perdue tant
que ces aliases ne sont pas créés.

Templates à créer côté dashboard Resend puis à câbler dans
`supabase/functions/_shared/resend_template_aliases.ts` (`RESEND_TEMPLATES`) :

- [ ] `booking-acceptee-par-pro` → `EmailEventKey.booking_accepted_by_pro`
      Déclencheur : `update-booking-status` quand le Pro accepte (status
      `pending` → `confirmed`), paiement **pas** encore capturé.
      Variables injectées : `clientName, serviceName, providerName, date,
      time, address, amountPaid, bookingId`.
- [ ] `booking-paid-and-confirmed` → `EmailEventKey.booking_paid_and_confirmed`
      Déclencheur : `stripe-webhook payment_intent.succeeded` (booking).
      Mêmes variables que `booking-acceptee-par-pro` — le paiement est cette
      fois capturé + transfer auto-créé côté Stripe.
- [ ] `pro-transfer-reversed` → `EmailEventKey.pro_transfer_reversed`
      Déclencheur : `stripe-webhook transfer.reversed` (refund > 48h).
      Variables : `bookingCode, bookingId, transferId, amount, currency`.

> Tant que ces aliases n'existent pas, la fallback HTML réutilise les
> builders existants (voir `email_templates.ts` — `booking_accepted_by_pro`
> → `bookingConfirmed`, `pro_transfer_reversed` → `bookingCancelled`).

### 25. Welcome email pour premiers logins Google/Apple

Commit 4 câble `send-welcome-email` uniquement depuis `signUpWithEmail` (flow
email/password). Les premiers logins Google/Apple ne déclenchent **pas**
l'email de bienvenue — `signInWithOAuth` / `signInWithIdToken` ne distinguent
pas « nouveau compte » de « connexion récurrente ».

- [ ] Option A (Flutter-side) : comparer `users.created_at` à `DateTime.now()`
      dans le callback OAuth. Si < 60s, invoke `send-welcome-email`.
- [ ] Option B (DB-side) : ajouter une colonne `welcome_sent_at timestamptz`
      dans `public.users` + un call site qui fait `UPDATE ... WHERE welcome_sent_at IS NULL`
      via le RPC avant `invoke` pour garantir l'unicité (multi-device).
- [ ] Préférer Option B : évite la race entre deux devices qui se connectent
      en quasi-simultané et évite que l'utilisateur reçoive l'email à chaque
      réinstall.
- [ ] Priorité : basse (l'email welcome est un nice-to-have, pas bloqueur).

### 24. EF `event-cancel` à créer

Commit 3 a câblé l'event key `event_cancelled` côté template (alias
`vnement-annul` déjà dans `RESEND_TEMPLATES`), mais **aucune EF ne
l'appelle**. Pour fermer la boucle quand un Pro annule un événement :

- [ ] Créer `supabase/functions/event-cancel/index.ts` :
      1. Vérifier que `user.id === events.pro_id` (auth + RLS).
      2. Transition `events.status` → `cancelled` (atomique, TOCTOU guard sur
         le status actuel).
      3. Refund tous les `tickets` non utilisés via `stripe.refunds.create`
         avec idempotency key `event-refund-{ticket.id}`.
      4. Si refund > 48h sur un ticket : `transfers.createReversal`.
      5. `sendResendEmail({ event: "event_cancelled", to: holder.email, … })`
         pour chaque détenteur de ticket (batch — un par ticket, pas par
         order, car les billets peuvent être transférés nominativement).
      6. Audit `event_cancelled` via `log_audit_action`.
- [ ] Side-effect : mettre à jour les `waitlist` liées → notif push
      `Vous n'êtes plus sur la liste d'attente`.
- [ ] Scope hors migration email (infra métier). À faire **après** Commit 4
      sauf si un Pro en a un besoin urgent avant.
