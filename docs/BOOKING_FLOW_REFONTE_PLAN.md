# BOOKING FLOW — REFONTE PREMIUM CLIENT ↔ PRO

Version : 2026-04-22
Branche : `agent/refonte-totale-premium`
Scope : 5 commits atomiques, zéro git push, zéro deploy prod (edge functions incluses).

---

## 1. État actuel — les 6 problèmes identifiés

### P1 — CTA "Message" affiché même si le paiement est en attente
`lib/features/booking/presentation/widgets/reservation_card.dart:162-166` affiche
inconditionnellement `_PrimaryButton(label: 'Message')` dès que `isUpcoming == true`,
y compris lorsque `booking.status == 'pending_payment'`. Le client devrait voir
"Payer maintenant" pour finaliser, pas un bouton message qui l'envoie dans une
conversation inutile.

### P2 — Le Pro voit les RDV non payés
`booking_repository.dart:549` (`getUpcomingProBookings`) : inclut
`['confirmed', 'pending_payment']`. `booking_repository.dart:517`
(`getProDashboardStats`) : compte `pending_payment` comme "upcoming".
Conséquence : un client qui abandonne le paiement crée un RDV fantôme chez le Pro.

### P3 — Incohérence badge top vs card paiement
Sur `booking_detail_screen.dart:579-610` le badge top utilise
`AppColors.success` (vert) pour `confirmed`. Viole la DS (success est réservé
aux états système) et crée le double affichage "Paiement en attente" + "Confirmé"
visible sur le screenshot utilisateur.

La card paiement (L837-841, L864-866) affiche aussi un `_Badge` "Confirmé" vert
à côté de chaque ligne, répétant l'info et dupliquant le signal.

### P4 — Date/heure en lignes séparées peu lisibles
`booking_detail_screen.dart:800-808` produit deux rows distinctes "Date" et
"Heure" — lourd à scanner. Le mockup demande un bloc unique
"Jeudi 23 avril · 15h30 — 16h30".

### P5 — Avatar sans glow, bordures non uniformes
`_PersonCard` (L651-745) : avatar fallback sans glow violet. Les cards ont des
radius mixtes (18, 16, 14) et border width `0.5` — le spec demande radius 16
uniforme + border `0.8`.

### P6 — Code réservation n'a pas son dashed violet prononcé
`_BookingCodeTicket` (L1084) a bien un CustomPaint dashed mais avec
`AppColors.violet.withAlpha(70)` — trop discret sur fond sombre.

---

## 2. Décisions validées par l'humain

**Mapping `status` → UI** (source unique de vérité) :

| status                     | badge label (tout écran)   | tint                            | CTA primaire Client        |
|---------------------------- |----------------------------|---------------------------------|----------------------------|
| `pending_payment`          | Paiement en attente        | `AppColors.warning` atténué    | Payer maintenant (violet)  |
| `confirmed`                | Confirmé                   | `AppColors.violet`              | Message (outline violet)   |
| `completed`                | Terminé                    | `AppColors.violet` atténué     | — (Laisser un avis + Rebook)|
| `cancelled_full_refund`    | Annulé                     | `AppColors.error` avec alpha 200| — (Voir détails outline)   |
| `cancelled_no_refund`      | Annulé                     | `AppColors.error` avec alpha 200| — (Voir détails outline)   |
| `payment_failed`           | Paiement échoué            | `AppColors.error` avec alpha 200| Payer maintenant (retry)   |

**Plus jamais de double badge** : la card paiement n'affichera plus "Confirmé" en vert.
À la place, juste les montants bruts avec labels sémantiques :
- `Payé en ligne : <montant>` (si status `confirmed`/`completed`)
- `À régler : <montant>` (pour le solde à payer sur place)
- Optionnel : un petit point coloré discret à côté du label si vraiment
  nécessaire — pas de badge/pill.

**Uniformisation cards** : radius 16, border `AppColors.border` width 0.8.

**Avatar** : glow violet `BoxShadow(spread 0, blur 12, color violet.withAlpha(60))`
quand fallback initiale.

**Date** : format groupé "Jeudi 23 avril · 15h30 — 16h30" (un seul row).

---

## 3. Plan commit par commit

### COMMIT 1 — `fix(booking): CTA Payer maintenant si paiement pending, Message sinon`

**Fichiers touchés** :
- `lib/features/booking/presentation/widgets/reservation_card.dart`
  - Import du mapping depuis un helper neuf `booking_status_presenter.dart`
  - Remplacer le bloc `if (widget.isUpcoming)` par un switch sur `b.status` :
    - `pending_payment` → ghost "Annuler" + primary "Payer maintenant" → route `/client/booking-flow/pay/${b.id}` ou existante
    - `confirmed` → ghost "Annuler" + primary "Message" (inchangé)
    - `cancelled_*` → pas d'action row, juste "Voir détails" outline pleine largeur
  - Status tokens : mettre à jour `_statusTokens` selon tableau section 2
- `lib/features/booking/presentation/screens/booking_status_presenter.dart` (NOUVEAU)
  - Helper `BookingStatusPresenter.from(status)` qui retourne `(label, tint, primaryCta, secondaryCta)`
  - Source unique de vérité, réutilisé par la card + detail screen

**Route existe-t-elle ?** Vérifier `lib/router` pour voir la route de paiement
reprise. Si aucune route dédiée, ré-exécuter le booking flow depuis le paiement.
Fallback : `context.push('/booking/${b.id}')` ouvre le détail où le CTA
"Payer maintenant" vit aussi.

**Impact DB / RLS / backend** : aucun.

**Strings ARB nouvelles** :
- FR: `payNow: "Payer maintenant"`, `paymentPending: déjà présent`, `viewDetails: "Voir détails"`
- EN: `payNow: "Pay now"`, `viewDetails: "View details"`

---

### COMMIT 2 — `fix(notifications): filtrer RDV pending côté Pro + webhook ne crée pas de notif avant confirmation`

**Côté Flutter** :
- `lib/features/booking/data/booking_repository.dart:549` — `getUpcomingProBookings` :
  retirer `pending_payment` → `inFilter('status', ['confirmed'])`
- `lib/features/booking/data/booking_repository.dart:517` — `getProDashboardStats` :
  ne compter comme "upcoming" que `confirmed`
- Vérifier les autres repositories Pro qui listent les bookings

**Côté backend (code source uniquement, pas de deploy)** :
- `supabase/functions/stripe-webhook-handler/index.ts` — déjà correct :
  - `new_booking` notif pro créée uniquement sur `payment_intent.succeeded` ligne 385-392
  - Le guard `.eq('status', 'pending_payment')` ligne 303 empêche les doubles updates
- **Rien à modifier** dans le webhook → pas besoin de redéploiement de cette fonction
  spécifique pour ce commit

**Note APOLLINAIRE_TODO.md** : pas de nouveau déploiement backend requis pour ce commit.

**Impact DB / RLS / backend** : aucun changement de schéma.

---

### COMMIT 3 — `feat(booking): refonte design booking_detail_screen premium`

**Fichiers touchés** :
- `lib/features/booking/presentation/screens/booking_detail_screen.dart`
  - `_StatusBanner` (L572-649) : utiliser `BookingStatusPresenter`,
    mapping violet pour `confirmed` (pas success/vert)
  - `_PersonCard` (L651-745) : radius 16, border 0.8, glow violet fallback avatar
  - `_InfoSection` (L747) : fusionner Date+Heure en une ligne
    "Jeudi 23 avril · 15h30 — 16h30", refonte breakdown paiement sans badges vert
  - `_StatementCard` (L936) : radius 16, border 0.8
  - `_Badge` (L1044) : SUPPRIMÉ des lignes paiement — ne reste que pour timeline
  - `_BookingCodeTicket` (L1084) : dashed violet plus prononcé
    (`AppColors.violet.withAlpha(140)`, dashLength 5, gapLength 3)
  - `_StatusTimeline` (L1388) : utiliser les couleurs du presenter, jamais
    `AppColors.success`

**Strings ARB** : nouvelles clés pour `paidOnline`, `balanceToPay`, `completed`, `cancelled`.

**Impact DB / RLS / backend** : aucun.

**Divergence mockup ASCII** :
- L'écran actuel a déjà une timeline 4 étapes (pas besoin d'en créer une)
- Pas de CTA sticky bottom prévu dans le code actuel → **je NE le rajoute pas**
  dans ce commit pour rester dans le scope "refonte visuelle" ; les boutons
  restent inline dans le scroll comme aujourd'hui (change mineur, conforme DS).
  Si tu veux sticky bottom → scope additionnel, commit séparé.

---

### COMMIT 4 — `fix(realtime): cohérence temps réel bookings client↔pro`

**Périmètre à vérifier** :
- `lib/features/booking/presentation/screens/booking_detail_screen.dart:51-73`
  canal déjà abonné filtré par `id=${bookingId}` — OK
- Liste client : vérifier que `clientBookingsProvider` est invalidé sur update
- Liste pro : idem `proBookingsProvider`
- Abonnements dispose correct

**Modifs probables** : ajouter un canal global sur `bookings` filtrés par
`client_id = uid` ou `pro_id = uid` dans le realtime manager, pas un canal
par booking.

**Impact DB / RLS / backend** : aucun changement schéma. Vérifier que RLS
autorise le subscribe realtime (généralement oui via policies existantes).

---

### COMMIT 5 — `fix(messages): bidirectionnalité + unread counts temps réel`

**À investiguer** :
- `lib/features/chat/data/chat_repository.dart` + `chat_notifier.dart`
- `conversations` table a-t-elle `unread_count_client` / `unread_count_pro` ?
- Mark-as-read trigger DB ou client ?

**Modifs probables** :
- Realtime sur `messages` pour les deux côtés
- `unread_count` bien décrémenté à l'ouverture du chat
- Badge numérique dans l'inbox qui se met à jour live

**Impact DB / RLS / backend** : à déterminer au moment de l'impl.

---

## 4. Questions bloquantes restantes (non-bloquantes pour commits 1-3)

1. **Route de paiement retour** — si un booking est créé avec `pending_payment` mais
   que le client sort de l'app, par quelle route revient-il au PaymentSheet Stripe ?
   Fallback retenu : ouvrir `/booking/:id` (détail) avec CTA "Payer maintenant"
   qui relance le PaymentSheet via `stripe-create-intent` et retry PaymentSheet.
   → À confirmer pendant le commit 1.

2. **Scope commits 4-5** — si la recon révèle un périmètre > 2h de code pour
   un commit, je stoppe et redécoupe.

---

## 5. Contraintes respectées à chaque commit

- `flutter analyze` = 0 warnings / errors avant `git commit`
- Zéro `git push`
- Zéro `supabase functions deploy` / `supabase db push`
- Toutes strings UI FR sentence case sans emoji sans "!"
- Pas de `BackdropFilter`
- Pas de couleur hex en dur — tout via `AppColors.xxx`
- Pas de `Colors.red` / `Colors.green` pur
- Glow seulement dark mode (déjà géré par AppColors)
- Cards radius 16, border 0.8
