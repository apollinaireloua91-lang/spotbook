# VIDEO_RECORDING_SCRIPTS — Démos à enregistrer

> Scripts de captures écran / vidéo pour : (a) soumission App Store Review,
> (b) marketing / landing page, (c) onboarding investisseurs.
> Format cible : MP4 H.264, 1080p ou natif device, ≤ 30 s par séquence.

---

## 1. App Store Review — obligatoire

Apple demande systématiquement une vidéo démo dès qu'une capability
sensible est utilisée (paiements, Tap to Pay, NFC).

### 1.1 Tap to Pay — end to end

**Objectif** : prouver que la capability `proximity-reader.payment.acceptance`
sert un use case légitime de paiement en personne.

**Device** : iPhone XS+ physique, iOS 16.7+

**Script** :
1. Login en tant que Pro (utiliser le compte demo `apple-review@spotbook.app`)
2. Ouvrir dashboard → POS → « Accepter un paiement »
3. Saisir montant `25.00 $ CAD`
4. Écran « Tap to Pay » apparaît — présenter une carte contactless test Stripe
5. Animation succès → reçu → retour à l'historique POS
6. Voice-over FR : « Les professionnels Spotbook encaissent directement sur
   iPhone grâce à Stripe Terminal, sans lecteur additionnel. »

**Durée** : 45 s max. Ne pas montrer d'écran de debug.

### 1.2 Réservation + acompte

**Script** :
1. Login Client → feed vidéo
2. Tap sur un post → voir le pro → « Réserver »
3. Sélectionner service, date, créneau
4. Page paiement : acompte **30 %** + frais service 2.50 $
5. 3D Secure test → confirmation
6. Aller dans Mes RDV → voir la réservation

**Points clés à montrer** :
- Transparence du calcul (acompte vs total)
- Politique d'annulation visible (24h / 50 %)
- QR du reçu

### 1.3 Achat de billet événement + QR scan

**Script** :
1. Client achète un billet événement (25 $)
2. Reçoit ticket digital avec QR
3. Bascule vers device Pro → scan QR → validation OK
4. Montrer le ticket passer à `status = used`

---

## 2. Landing page / marketing

### 2.1 Hook 15 s — TikTok-style

**Objectif** : hero video landing page + réseaux.

**Séquence** :
- 0-3 s : zoom sur le feed vidéo (swipe vertical de 3 posts)
- 3-6 s : tap sur un post → sheet réservation apparaît
- 6-10 s : calendrier → slot → CTA Payer
- 10-13 s : Tap to Pay en gros plan (mains)
- 13-15 s : logo + tagline

**Musique** : track libre de droits, tempo 120+ BPM.

### 2.2 Features reel (60 s)

Enchaînement sans voix :
- Feed vidéo
- Recherche par catégorie
- Profil Pro avec bookings count
- Booking flow
- Ticket QR
- Chat in-app
- Notifications push live
- Profil Client

---

## 3. Investisseurs / pitch deck

### 3.1 Demo produit complète (3 min)

**Structure** :
- 0:00 Intro texte « Spotbook — la super-app services + événements »
- 0:15 Onboarding rapide (rôle, prefs)
- 0:45 Feed Découvrir vs Abonnements
- 1:15 Booking complet avec acompte
- 1:45 Création d'événement côté Pro + vente billets
- 2:15 Stats dashboard Pro (revenus, taux remplissage)
- 2:45 Outro avec URL + QR app

### 3.2 Story pro (1 min)

Focus sur la vie d'un Pro : création compte → Stripe Connect → premier
upload vidéo → première réservation → premier encaissement.

---

## Outillage

- Capture iOS : QuickTime → Nouvel enregistrement vidéo → choisir iPhone
- Capture Android : `adb shell screenrecord /sdcard/demo.mp4` puis `adb pull`
- Overlay cursor / tap : **Keynote** (slides export) ou **Screen Studio** (Mac)
- Montage : DaVinci Resolve (gratuit) ou Final Cut

---

## Checklist avant soumission

- [ ] Aucun nom/email/numéro réel visible à l'écran
- [ ] Mode sandbox Stripe affiché discrètement (bandeau optionnel)
- [ ] Sous-titres FR + EN si narration
- [ ] Pas de watermark logiciel (version pro des outils)
- [ ] Export en H.264, max 500 Mo par fichier (limite App Store Connect)
