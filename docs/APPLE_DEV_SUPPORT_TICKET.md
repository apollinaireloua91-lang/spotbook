# Apple Developer Support — ticket capability `proximity-reader.payment.acceptance`

> **Pour l'utilisateur (Apollinaire)** : ce document contient le texte
> prêt à copier-coller dans le formulaire Apple Developer Support pour
> demander l'activation de la capability **Tap to Pay on iPhone** sur
> l'App ID `com.getspotbook.spotbook`.
>
> Date de rédaction : **2026-04-23** — Statut : **À soumettre**.

---

## Étape 1 — Comment soumettre

1. Aller sur <https://developer.apple.com/contact/topic/select> en étant
   connecté avec le compte Apple Developer **propriétaire de l'équipe
   `QCBH2X6CKT`** (sinon Apple refusera la requête).
2. Choisir le chemin :
   **Membership & Account → Capabilities → Request a special capability**
   (le libellé exact peut bouger ; viser la rubrique « Capabilities » /
   « Tap to Pay on iPhone »).
3. Si Apple propose le formulaire dédié *« Tap to Pay on iPhone Request »*,
   le préférer (réponse plus rapide). Sinon, ouvrir un Code Level Support
   ticket avec le sujet et le corps ci-dessous.
4. Joindre une **screen-recording de 30 s** du POS Spotbook si possible
   (`lib/features/pos/presentation/pages/pos_reader_page.dart`) — montre
   l'UI prête à recevoir Tap-to-Pay. Ce n'est pas obligatoire mais ça
   accélère la review.

---

## Étape 2 — Sujet du ticket (à coller dans le champ « Subject »)

```
Tap to Pay on iPhone capability request — App ID com.getspotbook.spotbook (Team QCBH2X6CKT)
```

---

## Étape 3 — Corps du ticket — VERSION ANGLAISE (recommandée)

> Apple Developer Support traite les tickets plus vite en anglais.
> Coller le bloc ci-dessous dans le champ « Description » / « Issue ».

```text
Hi Apple Developer Support,

I am writing to request activation of the following capability on our App ID:

  Capability key : com.apple.developer.proximity-reader.payment.acceptance
  App ID         : com.getspotbook.spotbook
  Team ID        : QCBH2X6CKT
  App name       : Spotbook
  App category   : Lifestyle / Business (services marketplace)

USE CASE
--------
Spotbook is a marketplace mobile app (iOS + Android) connecting service
professionals (hairstylists, makeup artists, photographers, caterers,
event organisers, etc.) with end customers. Professionals create a
profile, list services with prices and deposits, and customers book
and pay in-app via Stripe Connect.

We need Tap to Pay on iPhone so that professionals can accept in-person
contactless payments at the time of service — for example, a hairstylist
who finishes a cut and needs to charge a tip or an upsell, or a caterer
collecting payment for an on-site add-on. Today they would have to enter
the amount manually in a separate Stripe Dashboard, which breaks the flow.
Tap to Pay on iPhone — integrated through the Stripe Terminal SDK — lets
the same iPhone running Spotbook also act as the payment reader.

INTEGRATION
-----------
We are integrating Stripe Terminal SDK (mek_stripe_terminal Flutter
plugin, which wraps StripeTerminal iOS 4.x). Stripe is on Apple's list
of approved payment service providers for Tap to Pay on iPhone. Our
implementation will use:

  - Terminal.shared.discoverReaders(LocalMobileReader)
  - Terminal.shared.connectLocalMobileReader(...)
  - Terminal.shared.collectPaymentMethod(...)
  - Terminal.shared.processPayment(...)

Our backend (Supabase Edge Functions on Deno) mints connection tokens
through stripe.terminal.connectionTokens.create() — endpoint is already
scaffolded at supabase/functions/stripe-terminal-connection-token/.

Required iOS minimum: 16.7, target devices: iPhone XS and later, NFC + 
Secure Enclave required (handled automatically by the SDK).

LAUNCH MARKETS
--------------
Canada, France, United States, Côte d'Ivoire — all jurisdictions where
Stripe supports Tap to Pay on iPhone (or has it on the roadmap; we will
gate the feature server-side via a feature flag for markets where Stripe
hasn't yet launched).

CURRENT BUILD STATUS
--------------------
The app is currently in development, preparing for first App Store
submission (v1.0). The entitlement is already declared in the
RunnerRelease.entitlements file in our codebase. Without the capability
being added to our App ID on the developer portal, our App Store Connect
upload will fail entitlement validation.

We would greatly appreciate guidance on next steps and any additional
documentation you may need from us (e.g., Stripe partnership confirmation,
demo video, business registration documents).

Thank you,
Apollinaire Loua
Spotbook
apollinaireloua91@gmail.com
```

---

## Étape 4 — Corps du ticket — VERSION FRANÇAISE (fallback)

> À utiliser uniquement si tu préfères communiquer en français avec
> Apple Developer Support (réponse parfois plus lente).

```text
Bonjour Apple Developer Support,

Je sollicite l'activation de la capability suivante sur notre App ID :

  Clé de capability : com.apple.developer.proximity-reader.payment.acceptance
  App ID            : com.getspotbook.spotbook
  Team ID           : QCBH2X6CKT
  Nom de l'app      : Spotbook
  Catégorie         : Lifestyle / Business (marketplace de services)

CAS D'USAGE
-----------
Spotbook est une application mobile marketplace (iOS + Android) qui
connecte des professionnels du service (coiffeurs, maquilleurs,
photographes, traiteurs, organisateurs d'événements, etc.) avec des
clients finaux. Les professionnels créent un profil, listent leurs
services avec prix et acomptes, et les clients réservent et paient
dans l'app via Stripe Connect.

Nous avons besoin de Tap to Pay on iPhone pour que les professionnels
puissent accepter des paiements sans contact en présentiel au moment
de la prestation — par exemple, un coiffeur qui finit une coupe et
doit encaisser un pourboire ou un upsell, ou un traiteur qui collecte
le paiement d'un complément on-site. Aujourd'hui ils doivent saisir
manuellement le montant dans un Dashboard Stripe séparé, ce qui casse
le flux. Tap to Pay on iPhone — intégré via le SDK Stripe Terminal —
permet au même iPhone qui exécute Spotbook de servir aussi de lecteur
de paiement.

INTÉGRATION
-----------
Nous intégrons le SDK Stripe Terminal (plugin Flutter mek_stripe_terminal,
qui wrappe StripeTerminal iOS 4.x). Stripe figure sur la liste Apple des
prestataires de services de paiement approuvés pour Tap to Pay on iPhone.
Notre implémentation utilisera :

  - Terminal.shared.discoverReaders(LocalMobileReader)
  - Terminal.shared.connectLocalMobileReader(...)
  - Terminal.shared.collectPaymentMethod(...)
  - Terminal.shared.processPayment(...)

Notre backend (Supabase Edge Functions sur Deno) génère les connection
tokens via stripe.terminal.connectionTokens.create() — l'endpoint est
déjà scaffoldé dans supabase/functions/stripe-terminal-connection-token/.

iOS minimum requis : 16.7, devices ciblés : iPhone XS et ultérieurs,
NFC + Secure Enclave requis (géré automatiquement par le SDK).

MARCHÉS DE LANCEMENT
--------------------
Canada, France, États-Unis, Côte d'Ivoire — toutes les juridictions où
Stripe supporte Tap to Pay on iPhone (ou l'a sur sa roadmap ; nous
gérons la disponibilité côté serveur via un feature flag pour les
marchés où Stripe ne l'a pas encore lancé).

STATUT BUILD ACTUEL
-------------------
L'app est actuellement en développement, en préparation de la première
soumission App Store (v1.0). L'entitlement est déjà déclaré dans le
fichier RunnerRelease.entitlements de notre codebase. Sans l'ajout de
la capability sur notre App ID dans le developer portal, notre upload
App Store Connect échouera à la validation des entitlements.

Nous apprécierions vos conseils sur les prochaines étapes et toute
documentation additionnelle dont vous pourriez avoir besoin (ex :
confirmation du partenariat Stripe, vidéo de démo, documents
d'enregistrement de l'entreprise).

Cordialement,
Apollinaire Loua
Spotbook
apollinaireloua91@gmail.com
```

---

## Étape 5 — Pièces jointes recommandées (optionnel)

Si Apple propose un champ « Attachments », joindre :

1. **Screen-recording 30s** du POS Spotbook
   (lib/features/pos/presentation/pages/pos_reader_page.dart →
   pos_amount_page.dart → pos_success_page.dart). Capturable avec
   QuickTime (Mac) ou xrecord. Format `.mov` ou `.mp4` ≤ 25 MB.

2. **Capture du Stripe Dashboard** montrant que le compte Stripe
   Connect plateforme est actif et que Stripe Terminal est ou sera
   activé pour Spotbook. Cf. APOLLINAIRE_TODO §2.

3. **Lien App Store Connect** vers la fiche app si elle est déjà créée
   (App Information → Apple ID numérique).

---

## Étape 6 — Suivi après soumission

- [ ] Noter le **case number** retourné par Apple dans la réponse
      automatique (format `CR####-#######`).
- [ ] Logguer la date d'ouverture du ticket dans
      `docs/APOLLINAIRE_TODO.md` §1.
- [ ] **Délai typique** : 5–15 jours ouvrés. Apple peut demander plus
      d'infos au bout de 2–3 jours — répondre dans les 48h pour ne pas
      voir le ticket fermé pour inactivité.
- [ ] Quand approuvé : Apple ajoute la capability au menu
      « Capabilities » du portal pour notre App ID. Ouvrir
      `developer.apple.com/account/resources/identifiers` →
      `com.getspotbook.spotbook` → cocher « Tap to Pay on iPhone » →
      régénérer le **provisioning profile** (App Store distribution) →
      télécharger et l'installer dans Xcode.
- [ ] Tester la build IPA : `flutter build ipa --release
      --dart-define-from-file=.env.json` doit maintenant passer
      l'entitlement validation à l'upload Transporter.

---

## Référence interne

- Entitlement actif : `ios/Runner/RunnerRelease.entitlements` ligne 19-20
  (commit `7dcd942` — Tap-to-Pay re-enabled).
- TODO humain associé : `docs/APOLLINAIRE_TODO.md` §1.
- Edge Function `connection-token` :
  `supabase/functions/stripe-terminal-connection-token/index.ts`.
- Doc Apple officielle :
  <https://developer.apple.com/tap-to-pay-on-iphone/>
- Doc Stripe officielle :
  <https://stripe.com/docs/terminal/payments/setup-integration?reader=tap-to-pay>
