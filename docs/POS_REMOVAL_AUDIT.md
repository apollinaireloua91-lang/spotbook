# POS Removal Audit — v1.0 launch

**Branche** : `agent/refonte-totale-premium`
**Date** : 2026-04-24
**Objectif** : Retirer **POS + Tap-to-Pay (Stripe Terminal)** du périmètre v1.0
pour permettre une soumission App Store **sans dépendre de l'approbation
manuelle Apple** de la capability `proximity-reader.payment.acceptance`.
Réintégration prévue v1.1 après approbation.

> **STOP REVIEWER** : ce document est l'audit. Aucun fichier de code n'a été
> modifié. Les 4 commits (A→D) ne seront produits qu'après validation
> explicite par Papy.

---

## 0. Garde-fou critique — préservation des commissions

Le retrait POS **NE DOIT PAS** affecter le calcul des commissions Stripe sur
les flux non-POS. Vérification ligne-à-ligne ci-dessous.

| EF non-POS | Source service_fee | Source commission_rate | Application_fee | Statut |
|---|---|---|---|---|
| `create-payment-intent/index.ts` | `booking.service_fee ?? 2.50` (L113) | `pro.commission_rate ?? 0.18` (L166) | `commission + serviceFee` (L182) | **OK indépendant POS** |
| `stripe-create-intent/index.ts` | `booking.service_fee ?? 2.50` (L124) | `pro.commission_rate ?? 0.18` (L127) | `commission + serviceFee` (L153) | **OK indépendant POS** |
| `stripe-create-ticket-intent/index.ts` | `events.service_fee ?? 2.50` (L107) | `events.commission_rate ?? 0.12` (L105) | `commission` (L156) | **OK indépendant POS** |
| `stripe-create-catering-intent/index.ts` | `submission.service_fee ?? 2.50` (L139) | `pro.commission_rate ?? 0.18` (L142) | `commission + serviceFee` (L165) | **OK indépendant POS** |

**Conclusion** : aucun de ces 4 EF n'importe ni ne consulte `pos_*`,
`stripe-terminal-*` ni quoi que ce soit du dossier `lib/features/pos/`. Les
4 taux (18% RDV, 12% events, 18% catering, 2,50$ service fee client) sont
préservés intégralement.

---

## 1. Périmètre des fichiers à archiver

### 1.1 Edge Functions POS — **4 EF** (non 3 comme initialement prévu)

| EF | Lignes | Rôle | Action |
|---|---|---|---|
| `supabase/functions/create-pos-payment-intent/index.ts` | 424 | Crée le PI Stripe + ligne `pos_transactions` | Déplacer vers `_archive/` |
| `supabase/functions/send-pos-receipt/index.ts` | 265 | Email reçu post-encaissement Tap-to-Pay | Déplacer vers `_archive/` |
| `supabase/functions/refund-pos-transaction/index.ts` | 224 | Refund + reversal POS | Déplacer vers `_archive/` |
| `supabase/functions/stripe-terminal-connection-token/index.ts` | 222 | Token éphémère SDK Terminal | Déplacer vers `_archive/` |

**Note** : `stripe-terminal-connection-token` n'avait pas été listée dans le
brief initial mais est **exclusivement** consommée par
`lib/features/pos/data/mek_pos_terminal.dart` (4 références, aucune autre).
À archiver également pour rester cohérent.

### 1.2 Code Flutter — `lib/features/pos/` (20 fichiers)

```
lib/features/pos/
├── data/
│   ├── mek_pos_terminal.dart      ← consomme stripe-terminal-connection-token
│   ├── pos_notifier.dart
│   ├── pos_repository.dart
│   └── pos_terminal.dart           ← interface
├── domain/
│   └── pos_models.dart             ← PosAmount, PosPaymentResult, etc.
└── presentation/
    ├── money_format.dart
    ├── reader_state_copy.dart
    ├── pages/
    │   ├── pos_amount_page.dart
    │   ├── pos_error_page.dart
    │   ├── pos_history_page.dart
    │   ├── pos_reader_page.dart
    │   ├── pos_success_page.dart
    │   └── pos_transaction_detail_page.dart
    └── widgets/
        ├── amount_badge.dart
        ├── cancel_button.dart
        ├── close_icon_button.dart
        ├── pos_hero_cta.dart        ← consommé par pro_dashboard_screen
        ├── pulse_nfc_indicator.dart
        ├── reader_background.dart
        └── reader_state_indicator.dart
```

**Action** : `git mv lib/features/pos lib/_archive/pos` (préserver historique
git, ne pas `rm`).

### 1.3 Routes GoRouter — 6 routes + 7 imports à supprimer

`lib/router/app_router.dart` :

| Lignes | Contenu | Action |
|---|---|---|
| L93 | `import '../features/pos/domain/pos_models.dart';` | Supprimer |
| L94-L99 | 6 imports `pos_*_page.dart` | Supprimer |
| L368-L457 | 6 routes `/pro/pos/amount`, `/reader`, `/success`, `/error`, `/history`, `/transaction/:id` | Supprimer |

### 1.4 main.dart — feature flag + override Riverpod

`lib/main.dart` :

| Lignes | Contenu | Action |
|---|---|---|
| L14-L15 | `import 'features/pos/data/mek_pos_terminal.dart';` + `pos_terminal.dart` | Supprimer |
| L33-L36 | `kStripeTerminalEnabled` (feature flag `--dart-define`) | Supprimer |
| L152-L154 | `if (kStripeTerminalEnabled) posTerminalDataSourceProvider.overrideWith(...)` dans `ProviderScope` | Supprimer (alléger le bloc `overrides:`) |

### 1.5 Call sites externes — **2 fichiers**

| Fichier | Ligne | Code | Action |
|---|---|---|---|
| `lib/features/booking/presentation/screens/pro_dashboard_screen.dart` | L60 | `const PosHeroCta()` | Supprimer le widget + son import |
| `lib/features/booking/presentation/screens/booking_detail_screen.dart` | L251-L276 | `_collectRemainingPaymentTapToPay()` (helper) | Supprimer |
| `lib/features/booking/presentation/screens/booking_detail_screen.dart` | L385 | callback `onCollectRemainingTapToPay` câblé | Mettre à `null` ou retirer la prop |
| `lib/features/booking/presentation/screens/booking_detail_screen.dart` | L1291-L1301 | bouton `Encaisser solde via Tap to Pay` | Supprimer le bloc complet |

> Le bouton **« Marquer payé manuellement »** (L1302-L1309) **RESTE**. Il
> devient le seul chemin pour confirmer l'encaissement du solde en v1.0.

### 1.6 pubspec + iOS Pods

| Fichier | Action |
|---|---|
| `pubspec.yaml` L71 | Retirer `mek_stripe_terminal: ^4.6.3` |
| `ios/Podfile.lock` | **Régénération automatique** au prochain `pod install` (humain) — ne pas éditer à la main |

---

## 2. Entitlements iOS — alerte dérive working tree

### 2.1 État HEAD vs working tree

| Fichier | HEAD | Working tree |
|---|---|---|
| `ios/Runner/Runner.entitlements` | `proximity-reader.payment.acceptance: true` (avec commentaire XML) + `aps-environment: development` | proximity-reader **retiré** + commentaire **perdu** + `aps-environment: development` (OK) |
| `ios/Runner/RunnerRelease.entitlements` | `proximity-reader.payment.acceptance: true` (avec commentaire XML) + `aps-environment: **production**` | proximity-reader **retiré** + commentaire **perdu** + `aps-environment: **development**` ⚠️ **RÉGRESSION** |

> ⚠️ **Régression critique** : le working tree a fait passer
> `RunnerRelease.entitlements` de `production` à `development`. Si on
> commitait tel quel, **les push notifications de production seraient
> cassées** sur les builds App Store/TestFlight.

### 2.2 État cible Commit A

**`Runner.entitlements`** (Debug) :
```xml
<key>com.apple.developer.applesignin</key>
<array><string>Default</string></array>

<key>aps-environment</key>
<string>development</string>

<key>com.apple.developer.in-app-payments</key>
<array><string>merchant.com.spotbook.app</string></array>

<!-- Tap to Pay on iPhone (Stripe Terminal) — disabled for v1.0.
     Re-enable in v1.1 after Apple approval of the
     proximity-reader.payment.acceptance capability. -->
```

**`RunnerRelease.entitlements`** (Release) — **identique sauf** :
```xml
<key>aps-environment</key>
<string>production</string>
```

(et même commentaire XML expliquant la désactivation).

---

## 3. Wording client — Interac / cash sur les 3 surfaces concernées

Quand `payment_mode == 'deposit'` et qu'un solde reste à payer sur place,
afficher le bloc verbatim :

```
💳 Paiement en ligne
Acompte réglé : {{depositAmount}}
Frais de service : {{serviceFee}}

💰 Solde à régler au pro le jour du RDV
Montant restant : {{remainingAmount}}
Moyens acceptés : virement Interac, cash

Le pro reçoit 100% du solde payé en mains propres.
```

> Emojis 💳💰 **autorisés** ici (illustratifs, non décoratifs). Sentence case
> français, pas de "!".

### Surfaces d'injection

| Fichier | Ligne actuelle | Quand afficher |
|---|---|---|
| `lib/features/booking/presentation/screens/booking_steps/step5_payment.dart` | L423-L429 (« Solde sur place » placeholder) | Pré-paiement : `!isFullPayment && remaining > 0` |
| `lib/features/booking/presentation/screens/booking_steps/step6_confirmation.dart` | actuellement pas de mention solde | Post-paiement : si `payment_mode == 'deposit'` |
| `lib/features/booking/presentation/screens/booking_detail_screen.dart` | L864-L892 (vue Client) | Tant que `remaining_payment_status != 'paid_on_site'` |

---

## 4. Base de données — table `pos_transactions`

| Migration | Action |
|---|---|
| `supabase/migrations/20260420180000_create_pos_transactions.sql` | **CONSERVER** (ne pas dropper) |
| `supabase/migrations/20260423120000_pos_transactions_booking_link.sql` | **CONSERVER** (ne pas dropper) |

**Décision Papy** : la table `pos_transactions` reste en DB. Pas de migration
de drop. Note à ajouter dans `docs/APOLLINAIRE_TODO.md` :

> §14 — POS reactivation v1.1 : la table `pos_transactions` est conservée
> en DB pour ne pas perdre l'historique éventuel et faciliter la
> réactivation v1.1 quand Apple aura approuvé la capability. Les EF POS
> sont dans `supabase/functions/_archive/` — un simple `git mv` les
> remettra en place.

---

## 5. Plan des 4 commits atomiques

> **Aucun** des commits ne touche aux EF non-POS, aux migrations DB, à la
> table `pos_transactions`, ni au code Stripe Connect. `git push` interdit.
> `supabase functions deploy` interdit. `supabase db push` interdit.

### Commit A — `chore(ios): disable Tap-to-Pay entitlement for v1.0`
- Corriger `ios/Runner/Runner.entitlements` (retirer proximity-reader +
  ajouter commentaire XML)
- Corriger `ios/Runner/RunnerRelease.entitlements` (retirer proximity-reader
  + **restaurer `aps-environment: production`** + commentaire XML)
- Aucune autre modif

### Commit B — `chore(pos): archive POS feature folder + remove from app`
- `git mv lib/features/pos lib/_archive/pos`
- `lib/router/app_router.dart` : retirer 7 imports + 6 routes (L368-L457)
- `lib/main.dart` : retirer 2 imports + flag `kStripeTerminalEnabled` +
  override `posTerminalDataSourceProvider`
- `lib/features/booking/presentation/screens/pro_dashboard_screen.dart` :
  retirer `PosHeroCta`
- `lib/features/booking/presentation/screens/booking_detail_screen.dart` :
  retirer `_collectRemainingPaymentTapToPay` + bouton Tap-to-Pay
- `pubspec.yaml` : retirer `mek_stripe_terminal: ^4.6.3`
- `flutter analyze = 0` requis avant commit

### Commit C — `chore(functions): archive POS edge functions`
- `git mv supabase/functions/create-pos-payment-intent supabase/functions/_archive/`
- `git mv supabase/functions/send-pos-receipt supabase/functions/_archive/`
- `git mv supabase/functions/refund-pos-transaction supabase/functions/_archive/`
- `git mv supabase/functions/stripe-terminal-connection-token supabase/functions/_archive/`
- Aucun deploy. EF déjà déployées sur Supabase resteront jusqu'au prochain
  cleanup manuel par Papy (no-op tant qu'aucun client ne les appelle).

### Commit D — `feat(booking): Interac/cash messaging when deposit balance due`
- Injecter le bloc wording verbatim dans `step5_payment.dart` (L423-L429)
- Ajouter le bloc dans `step6_confirmation.dart` (gated `payment_mode == 'deposit'`)
- Remplacer la ligne `balanceToPay` simple dans `booking_detail_screen.dart`
  vue Client (L864-L892) par le bloc complet
- Mise à jour `docs/APOLLINAIRE_TODO.md` §14 (POS v1.1 reactivation note)
- `flutter analyze = 0` requis avant commit

---

## 6. Risques résiduels & mitigations

| Risque | Mitigation |
|---|---|
| Build iOS rejeté par App Store si `proximity-reader` reste dans n'importe quel `.entitlements` | Vérifié sur les **2** fichiers (Debug + Release). Commit A est isolé pour relecture facile. |
| Push prod cassé après merge | Commit A restaure explicitement `aps-environment: production` dans `RunnerRelease.entitlements`. |
| Commission cassée | Audit §0 : 4 EF non-POS ont leur propre logique commission, **0 import** depuis le code POS. |
| Référence orpheline à `lib/features/pos` | Grep exhaustif §1.5 — seulement 2 fichiers externes, tous deux traités en Commit B. |
| EF POS toujours appelables côté Supabase après archivage local | Pas de risque sécurité (RLS + auth identique). Cleanup serveur = tâche humaine post-merge. |
| Reactivation v1.1 douloureuse | `git mv` préserve l'historique. Réactivation = 4 `git mv` inverses + restore entitlements + ré-add pubspec. |

---

## 7. Checklist pré-commits (à valider par Papy)

- [ ] OK pour archiver `stripe-terminal-connection-token` aussi (en plus
      des 3 EF du brief initial) ?
- [ ] OK pour utiliser `git mv` vers `_archive/` (vs `rm` pur) ?
- [ ] OK pour le commit A qui corrige aussi la régression
      `aps-environment: development → production` dans le Release ?
- [ ] OK pour le wording client verbatim §3 sur les 3 surfaces ?
- [ ] OK pour conserver les migrations + table `pos_transactions` en DB ?
- [ ] OK pour la note §14 dans `APOLLINAIRE_TODO.md` ?

**STOP — attente validation avant production des commits A→D.**
