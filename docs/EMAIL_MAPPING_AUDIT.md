# Email mapping audit — Spotbook × Resend

> Phase 0 étape 2 — audit **validé** par Apollinaire le 2026-04-22.
> Les aliases ci-dessous sont ceux publiés dans le dashboard Resend (fetchés via
> `GET /templates?limit=100`). Ils ne seront **pas renommés** — stabilité des
> aliases > cosmétique. Les diacritiques tronqués (`vnement-annul`, `compte-dsactiv`,
> `stripe-connect-activ`) sont dus à Resend qui strippe les accents lors de
> l'auto-génération de l'alias à partir du nom.
>
> Source de vérité code : `supabase/functions/_shared/resend_template_aliases.ts`.

---

## 1 — Templates HTML actuellement présents dans le code

Source : `supabase/functions/_shared/email_templates.ts` (fonction `buildEmail`).
Ces 8 templates restent en place comme **fallback HTML** — jamais supprimés.
Si l'appel Resend échoue (template id invalide, 4xx, network), le wrapper
`sendResendEmail` retombe automatiquement sur `buildEmail` pour garantir la
délivrabilité.

| # | Clé `type` code | Sujet (FR) | Appelée depuis |
|---|-----------------|------------|----------------|
| 1 | `booking_confirmed`  | Réservation confirmée | stripe-webhook-handler, update-booking-status |
| 2 | `booking_cancelled`  | Réservation annulée   | stripe-webhook-handler `charge.refunded`, update-booking-status (rejected) |
| 3 | `payment_receipt`    | Reçu de paiement      | stripe-webhook-handler (booking) |
| 4 | `ticket_purchased`   | Billet confirmé       | stripe-webhook-handler (ticket PI) |
| 5 | `booking_reminder`   | Rappel — RDV demain   | schedule-reminders (J-1, client only) |
| 6 | `welcome`            | Bienvenue sur Spotbook | **JAMAIS INVOQUÉE** — call site à ajouter en Commit 4 |
| 7 | `review_request`     | Donnez votre avis     | update-booking-status (completed), trigger-review-request |
| 8 | `pos_receipt`        | Reçu POS              | send-pos-receipt (Resend direct, sans passer par send-email) |

---

## 2 — Mapping événements Spotbook → template Resend cible

Légende **Statut actuel** :
- `ACTIVE` → un email est déjà envoyé pour cet événement
- `GAP` → l'événement se produit mais aucun email n'est envoyé
- `MISSING` → l'événement n'existe pas encore en code (feature à câbler)
- `DUPLICATE` → deux call sites envoient potentiellement le même email → à dédupliquer en Commit 2

### 2.1 — Client (existants — à migrer en Commit 2)

| Événement Spotbook | `EmailEventKey` | Template Resend alias (id) | Edge Function source | Destinataire | Statut actuel |
|--------------------|-----------------|----------------------------|----------------------|--------------|---------------|
| Paiement réservation confirmé (capture) | `booking_confirmed` | `rservation-confirme` (b49bd62b…) | stripe-webhook-handler `payment_intent.succeeded` (booking) L404 | Client | ACTIVE |
| Reçu paiement — montant total | `payment_receipt_full` | `reu-de-paiement` (0ae33cee…) | stripe-webhook-handler `payment_intent.succeeded` L419 (si `payment_mode='full'`) | Client | ACTIVE (à scinder par mode en Commit 2) |
| Reçu paiement — acompte (avec solde restant affiché) | `payment_receipt_deposit` | `acompte-reu` (d1f0bb61…) | stripe-webhook-handler `payment_intent.succeeded` L419 (si `payment_mode='deposit'`) | Client | ACTIVE (à scinder par mode en Commit 2) |
| Pro a accepté la réservation | `booking_confirmed` | `rservation-confirme` (b49bd62b…) | update-booking-status newStatus=confirmed L275 | Client | DUPLICATE — **décision 4.1** : garder webhook uniquement pour le flow paiement ; update-booking-status sera retiré du chemin email en Commit 2 |
| Pro a refusé la réservation | `booking_cancelled` | `rservation-annule` (550764b8…) | update-booking-status newStatus=rejected L290 | Client | ACTIVE |
| Réservation annulée par le client | `booking_cancelled` | `rservation-annule` (550764b8…) | cancel-booking (branch `user.id === booking.client_id`) | Client | GAP — email immédiat à câbler en Commit 3 (**décision 4.1 Option B** : annulation ≠ remboursement) |
| Remboursement effectué (Stripe `charge.refunded`) | `refund_completed` | `remboursement-effectu` (59f85f27…) | stripe-webhook-handler `charge.refunded` L525 | Client | ACTIVE — clé à renommer de `booking_cancelled` vers `refund_completed` en Commit 2 (**décision 4.1** : deux emails distincts, pattern Stripe/Airbnb) |
| Billet acheté (QR) | `ticket_purchased` | `votre-billet` (89027df2…) | stripe-webhook-handler `payment_intent.succeeded` (ticket) L272 | Acheteur | ACTIVE |
| Rappel J-1 du RDV | `booking_reminder_j1` | `rappel-de-rendez-vous` (55e1702c…) | schedule-reminders L122 | Client | ACTIVE |
| Rappel 1h avant le RDV | `reminder_1h_before` | `rappel-1h-avant` (b1b54ab3…) | schedule-reminders (flag `reminder_h1_sent` — **renommage staged en APOLLINAIRE_TODO §15**) | Client | GAP — **décision 4.3 Option A** : migrer code H-2 → H-1 (alias Resend dit `1h-avant`) |
| Service terminé → demande d'avis | `review_request` | `donnez-votre-avis` (d8532fa1…) | update-booking-status newStatus=completed L301 + trigger-review-request L68 | Client | ACTIVE (dédup naturel via `review_requested_at`) |
| Reçu POS | `pos_receipt` | **HTML-only** (intentionnellement absent de `RESEND_TEMPLATES`) | send-pos-receipt L211 | Customer | ACTIVE — **décision 4.4** : trop de variables dynamiques (subtotal/tip/TPS/TVQ/last4), HTML fallback préservé ; à aligner sur `sendResendEmail` wrapper en Commit 2 (qui détectera l'absence et tombera direct sur `buildEmail`) |

### 2.2 — Client (gaps à câbler — Commit 3)

| Événement Spotbook | `EmailEventKey` | Template Resend alias (id) | Edge Function source | Destinataire | Statut actuel |
|--------------------|-----------------|----------------------------|----------------------|--------------|---------------|
| Paiement échoué | `payment_failed` | `paiement-chou` (cb167b78…) | stripe-webhook-handler `payment_intent.payment_failed` L466 (notif déjà insérée, email à compléter) | Client | GAP |
| Réservation annulée par le pro | `appointment_cancelled_by_pro` | `annulation-par-le-professionnel` (4f39b54e…) | cancel-booking — branch `booking.pro_id === user.id` | Client | GAP |
| Rappel solde restant à payer (J-1 avant RDV si `payment_mode='deposit'`) | `remaining_payment_reminder` | `solde-restant-payer` (b3dbae47…) | schedule-reminders — nouvelle branche, flag `remaining_reminder_sent` (**staged APOLLINAIRE_TODO §15**) | Client | GAP — **décision 4.5 Option A** : cron J-1 dédié avant le RDV |
| Évènement annulé | `event_cancelled` | `vnement-annul` (4776e58e…) | Nouveau handler `cancel-event` (à créer en Commit 3) | Tous détenteurs de billets | MISSING (feature backend) |
| Rappel événement (J-1 pour les billets) | `event_reminder` | `rappel-vnement` (e2cba0a1…) | schedule-reminders — nouvelle branche ticket | Détenteur billet | GAP |
| Signup réussi → email bienvenue | `welcome` | `bienvenue-sur-spotbook` (d9c9bd24…) | **Flutter** `auth_repository.dart:77` — `supabase.functions.invoke('send-welcome-email')` fire-and-forget après `AuthResponse` ok. **Jamais via trigger SQL**. | Nouveau user | GAP (Commit 4) |
| Compte désactivé (delete account) | `account_deactivated` | `compte-dsactiv` (0ee5e562…) | Hook juste avant `delete_account_rpc` OU via `on_delete` edge function | User | GAP (Commit 4) |
| Stripe Connect activé (Pro) | `pro_stripe_connect_activated` | `stripe-connect-activ` (d55b142d…) | stripe-webhook-handler `account.updated` L682 quand `onboarded` passe `false → true` | Pro | GAP (Commit 4) |

### 2.3 — Pro (gaps à câbler — Commit 3)

| Événement Spotbook | `EmailEventKey` | Template Resend alias (id) | Edge Function source | Destinataire | Statut actuel |
|--------------------|-----------------|----------------------------|----------------------|--------------|---------------|
| Nouvelle réservation reçue | `pro_new_booking` | `nouvelle-rservation-pro` (783397f6…) | stripe-webhook-handler `payment_intent.succeeded` (booking) L386 (actuellement notif in-app uniquement) | Pro | GAP |
| Paiement encaissé (après payout) | `pro_payment_received` | `paiement-reu-pro` (540a9bd6…) | process-payout L164 après `log_audit_action pro_payout_reconciled` | Pro | GAP |
| RDV annulé par le client | `pro_cancellation_by_client` | `annulation-client-pro` (d1301036…) | cancel-booking — branch `user.id === booking.client_id` | Pro | GAP |
| Virement envoyé (payout Stripe) | `pro_payout_sent` | `virement-envoy` (09e067f5…) | process-payout (événement distinct du `pro_payment_received` — déclenché sur `payout.paid` webhook, à ajouter) | Pro | GAP |
| Nouvel avis reçu | `pro_new_review` | `nouvel-avis-reu-pro` (d83e2185…) | trigger DB après INSERT dans `reviews` OU review creation RPC | Pro | GAP |

### 2.4 — Push-only (pas d'email — décision 4.7)

Ces événements restent en **push FCM + notif in-app uniquement**. Pas de
template Resend créé, pas de wiring email. Décision Apollinaire — ces
notifications sont trop fréquentes / trop volatiles pour justifier un email
(risque de spam inbox + fatigue utilisateur).

| Événement | Statut | Commentaire |
|-----------|--------|-------------|
| `pro_ticket_sold` | Push-only | Billet vendu sur un event — le pro voit dans son dashboard |
| `pro_tip_received` | Push-only | Pourboire reçu — satisfaisant en push immédiat |
| `pro_transfer_reversed` | Push-only | Refund > 48h — critique mais déjà couvert par l'email `refund_completed` côté client ; le pro voit le stripe dashboard |
| `message_notification` | Push-only | Nouveau message chat — email serait trop bruyant (pas de table `email_log` throttle à créer finalement) |
| `waitlist_promoted` | Push-only | Place attribuée depuis waitlist — action immédiate requise, push est plus urgent qu'un email |

### 2.5 — Aliases existants mais **non câblés** (hors périmètre migration)

Ces templates existent dans le dashboard Resend mais n'ont pas de call site
prévu dans les 4 commits annoncés. Référencés dans
`resend_template_aliases.ts::KNOWN_UNWIRED_ALIASES` pour éviter qu'un futur
dev ne les croie orphelins.

| Alias | Raison non-câblage | Suivi |
|-------|--------------------|-------|
| `rinitialisation-mot-de-passe` | Géré par Supabase Auth SMTP (built-in). Migration vers Auth Email Hook = projet séparé. | APOLLINAIRE_TODO §16 |
| `vrification-email` | Idem — Supabase Auth confirm email. | APOLLINAIRE_TODO §16 |
| `connexion-suspecte` | Heuristique détection login inhabituel (IP/device) — pas implémentée. | APOLLINAIRE_TODO §17 |
| `rendez-vous-reprogramm` | **Décision 4.6** : feature reschedule booking **n'existe pas en backend**. Ne pas câbler. | APOLLINAIRE_TODO §18 |
| `rappel-stripe-connect` | Cron rappel Pro avec onboarding incomplet > 48h. | APOLLINAIRE_TODO §19 — post-Commit 4 |
| `soumission-reue` | Feature catering/devis — **à vérifier** si le backend l'a ou non. | APOLLINAIRE_TODO §20 |
| `soumission-accepte-pro` | Idem. | APOLLINAIRE_TODO §20 |
| `soumission-refuse-pro` | Idem. | APOLLINAIRE_TODO §20 |
| `soumission-expire` | Idem. | APOLLINAIRE_TODO §20 |

Drafts Resend ignorés (`RESEND_DRAFT_ALIASES`) : `untitled-template`, `untitled-template-1`.

---

## 3 — Dédup / chevauchements détectés

1. **`booking_confirmed` — double envoi**
   - Webhook `payment_intent.succeeded` envoie `booking_confirmed` + `payment_receipt_*` dès la capture.
   - `update-booking-status` newStatus=confirmed renverrait `booking_confirmed` si l'UI appelle la fonction après (cas `pending` → `confirmed` par action du pro).
   - **Plan Commit 2** : retirer l'envoi email de `update-booking-status` — le webhook est source de vérité (le paiement est la preuve que la réservation est « confirmée »). Le statut DB `pending → confirmed` continue d'exister pour la logique pro mais ne déclenche plus d'email. Si besoin d'un email « acceptée sans paiement », créer un event distinct en phase ultérieure.

2. **`review_request` — double trigger**
   - `update-booking-status` newStatus=completed envoie l'email.
   - `trigger-review-request` cron le renvoie 2h après `updated_at` si `review_requested_at IS NULL`.
   - Dedup naturel via `review_requested_at` — OK, à conserver en Commit 2.

3. **Reminders J-1 — deux fonctions en parallèle**
   - `schedule-reminders` (flags `reminder_j1_sent` / `reminder_h2_sent`, email J-1 + push client+pro).
   - `send-reminders` (flags `reminder_j1_sent` / `reminder_h2_sent` / `reminder_m30_sent`, push only).
   - Les deux écrivent sur les MÊMES flags → course potentielle. **Hors périmètre migration email** mais risque prod à flagger → APOLLINAIRE_TODO §21.

4. **H-2 vs H-1 — mismatch code/alias Resend (décision 4.3 Option A)**
   - Alias Resend publié : `rappel-1h-avant`.
   - Code actuel : `reminder_h2_sent` (2h avant).
   - **Plan** : migrer le code à H-1 (renommer flag DB + ajuster delta temps dans schedule-reminders/send-reminders). Migration SQL staged en APOLLINAIRE_TODO §15.

---

## 4 — Décisions validées par Apollinaire (2026-04-22)

Ces décisions closent le §6 de la version précédente. Consignées ici pour
traçabilité ; tout changement ultérieur doit être explicitement ré-approuvé.

- **4.1 — `booking_cancelled` vs `refund_completed`** : Option B retenue. Deux
  events distincts (pattern Stripe/Airbnb). `booking_cancelled` est envoyé
  immédiatement au moment de l'action d'annulation (cancel-booking / rejet pro) ;
  `refund_completed` est envoyé quand Stripe confirme le refund via
  `charge.refunded`. L'utilisateur reçoit donc deux emails cohérents : « on a
  bien reçu votre annulation » puis « votre remboursement est arrivé ».

- **4.2 — `payment_receipt` par mode de paiement** : Option B retenue. Le reçu
  diffère selon `booking.payment_mode`. Le template `acompte-reu` DOIT afficher
  le solde restant à payer (variable `remaining_amount`). Scission en deux
  `EmailEventKey` distinctes (`payment_receipt_full`, `payment_receipt_deposit`).

- **4.3 — Rappel H-2 → H-1** : Option A retenue. On migre le code pour utiliser
  H-1 avant le RDV (cohérent avec l'alias Resend `rappel-1h-avant`). Avant de
  faire le changement de code, **vérifier que la colonne DB existe** :
  - Si `reminder_h1_sent` existe déjà → juste adapter le delta temps.
  - Sinon → migration SQL staged (APOLLINAIRE_TODO §15) : renommer
    `reminder_h2_sent` → `reminder_h1_sent`. **Pas d'auto-push de migration**.

- **4.4 — `pos_receipt`** : conservé en HTML-only. Trop de variables dynamiques
  (subtotal, tip, TPS 5%, TVQ 9.975%, last4 de la carte, numéros de série POS).
  Les normes fiscales QC sont respectées dans le HTML existant. Le wrapper
  `sendResendEmail` détecte l'absence dans `RESEND_TEMPLATES` et tombe
  directement sur `buildEmail` — pas besoin de changement de call site.

- **4.5 — `remaining_payment_reminder`** : Option A retenue. Cron J-1 dédié
  envoie l'email aux bookings en `payment_mode='deposit'` dont le RDV est
  dans ≤ 24h et où le solde n'a pas encore été réclamé. Nouvelle colonne
  `bookings.remaining_reminder_sent BOOLEAN DEFAULT false` staged en
  APOLLINAIRE_TODO §15.

- **4.6 — Reschedule booking** : la feature **n'existe pas côté backend**
  (pas d'EF `reschedule-booking`, pas de champ DB pour proposer un nouveau
  créneau). On **ne câble pas** l'email. Le template `rendez-vous-reprogramm`
  reste dans `KNOWN_UNWIRED_ALIASES`. Note dans APOLLINAIRE_TODO §18.

- **4.7 — Push-only events** : pas d'email pour `pro_ticket_sold`,
  `pro_tip_received`, `pro_transfer_reversed`, `message_notification`,
  `waitlist_promoted`. Push FCM + notif in-app suffisent. **Conséquence** :
  pas de table `email_log` à créer (le throttle 1/h/thread pour messages
  n'est plus requis).

---

## 5 — Tableau récapitulatif statut global (post-décisions)

| Catégorie | Events cartographiés | Email ciblé | Push-only | MISSING (backend) | À câbler d'ici Commit 4 |
|-----------|---------------------:|------------:|----------:|------------------:|------------------------:|
| Client existants (2.1) | 12 | 12 | 0 | 0 | 0 (déjà ACTIVE) |
| Client nouveaux (2.2) | 8 | 8 | 0 | 1 (`event_cancelled`) | 8 |
| Pro (2.3) | 5 | 5 | 0 | 0 | 5 |
| Push-only (2.4) | 5 | 0 | 5 | 0 | 0 |
| Non câblé (2.5) | 9 | 0 | 0 | 4 (reschedule, catering×3 à vérifier, suspicious-login) | 0 |
| **TOTAL** | **39** | **25** | **5** | **5** | **13** |

---

## 6 — Découpage migration confirmé

- **Commit 1 — Infra (ce commit)** :
  - `_shared/send_resend_email.ts` (wrapper nested `template: { id, variables }` + HTML fallback)
  - `_shared/resend_template_aliases.ts` (constantes typées, 23 aliases réels)
  - `docs/EMAIL_MAPPING_AUDIT.md` (ce fichier)
  - `docs/APOLLINAIRE_TODO.md` — SQL staged (jamais dans `supabase/migrations/`)
  - **Aucune modification de call site.**

- **Commit 2 — Migrer l'existant** : stripe-webhook-handler,
  update-booking-status, schedule-reminders, send-pos-receipt (aligner sur
  wrapper), trigger-review-request. Chaque call site passe par
  `sendResendEmail({ event, to, variables })`. HTML restent dans
  `_shared/email_templates.ts` comme fallback. Dédup `booking_confirmed` côté
  webhook. Scission `payment_receipt_full` vs `_deposit`. Scission
  `booking_cancelled` (immédiat) vs `refund_completed` (stripe).

- **Commit 3 — Nouveaux events** : `pro_new_booking`, `pro_payment_received`,
  `pro_cancellation_by_client`, `pro_payout_sent`, `pro_new_review`,
  `payment_failed`, `appointment_cancelled_by_pro`,
  `remaining_payment_reminder`, `event_cancelled` (nouveau handler),
  `event_reminder`. Après décision §4.3, migration flag `reminder_h1_sent`
  + ajustement schedule-reminders/send-reminders.

- **Commit 4 — Welcome + Connect + deactivation** : nouvelle EF
  `send-welcome-email` + invoke Flutter depuis `auth_repository.dart` après
  `signUp` (fire-and-forget, JAMAIS via trigger SQL). Handler `account.updated`
  false→true → email Stripe Connect activé. Hook `account_deactivated` avant
  `delete_account_rpc`. Note APOLLINAIRE_TODO pour cron reminder Stripe Connect
  incomplet (§19).

---

*Fin du document. Decisions figées 2026-04-22 — reprendre ce fichier comme
référence lors de chaque commit suivant.*
