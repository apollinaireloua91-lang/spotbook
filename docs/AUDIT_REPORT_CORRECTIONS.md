# AUDIT_REPORT_CORRECTIONS.md

Journal des divergences constatées entre `docs/CLIENT_FLOWS_AUDIT.md`
(rapport initial) et l'état réel de la base + du code Flutter, découvertes
pendant l'exécution autonome de Chantier 2 (fondations DB).

**Convention** : chaque entrée documente (a) ce que l'audit prescrivait,
(b) ce que la réalité a révélé, (c) la décision prise.

Date de recensement : 2026-04-21.

---

## 1. Tables fantômes : liste réelle vs liste audit

### Audit prescrivait (implicitement, via Annexe "tables Client nouvelles")
Création de 9 tables :
`post_saves, post_likes, post_comments, comment_likes, client_profiles,
client_favorite_pros, notifications_client, reservations, ticket_purchases`.

### Réalité observée
Recherche exhaustive dans `lib/**/*.dart` :

| Table audit              | Référencée dans Flutter ? | Décision                                      |
|--------------------------|---------------------------|-----------------------------------------------|
| `post_saves`             | ✅ `video_repository.dart` L237-250                | **CRÉER** — FK `post_id` → `videos.id`        |
| `post_likes`             | ❌ — code utilise `video_likes` (existante)        | **NE PAS CRÉER**                              |
| `post_comments`          | ❌ — code utilise `video_comments` (existante)     | **NE PAS CRÉER**                              |
| `comment_likes`          | ❌ — aucune référence Flutter                       | **NE PAS CRÉER** (modèle Dart expose `likeCount` sans écriture serveur) |
| `client_profiles`        | ❌ — `profile_repository.dart` lit depuis `users`  | **NE PAS CRÉER** (alias mental)               |
| `client_favorite_pros`   | ✅ `profile_repository.dart` L192-200              | **CRÉER** — avec note redondance avec `favorites` |
| `notifications_client`   | ❌ — code utilise `notifications` (existante)      | **NE PAS CRÉER**                              |
| `reservations`           | ❌ — alias mental pour `bookings`                  | **NE PAS CRÉER**                              |
| `ticket_purchases`       | ❌ — alias mental pour `tickets`                   | **NE PAS CRÉER**                              |

**Delta net** : 9 tables annoncées → **2 tables réellement à créer**.

### Effet secondaire noté
`supabase/migrations/20260417180000_delete_account_rpc.sql` L60-88 fait un
`DELETE FROM public.post_likes / post_saves / comment_likes / post_comments /
notifications_client / client_favorite_pros` entouré de
`BEGIN ... EXCEPTION WHEN OTHERS THEN NULL`. Ces `DELETE` tombent
silencieusement si la table n'existe pas — c'est pour ça que rien n'a crashé
jusqu'ici. Une fois `post_saves` et `client_favorite_pros` créées, les
`EXCEPTION` deviennent sans effet ; aucun changement requis dans la RPC.

---

## 2. Redondance `client_favorite_pros` ↔ `favorites`

### Découverte
La table `favorites` (existante depuis `20260326121446_remote_schema.sql`
L1326) contient déjà :

```sql
favorites(
  user_id, pro_id, video_id, event_id,
  target_id, target_type  -- CHECK ∈ {'pro','event','video'}
)
```

Elle couvre à 100 % l'usage ciblé par `client_favorite_pros`
(`target_type = 'pro'`).

### Décision
Créer quand même `client_favorite_pros` (nouvelle table spécialisée) parce
que le code Flutter fait un JOIN explicite
`from('client_favorite_pros').select('*, users!pro_id(...)')` qui n'est
pas portable vers `favorites` sans refactor client.

**Dette technique ouverte** : à long terme, migrer vers une seule table
`favorites` + vues spécialisées. Ticket à créer dans
`docs/APOLLINAIRE_TODO.md` (Chantier 10).

---

## 3. Audit prescrivait : "unread_count_* à ajouter"

### Réalité
`20260326121446_remote_schema.sql` L1278-1291 montre que
`conversations.unread_count_client` et `unread_count_pro` **existent déjà**,
et que la RPC `mark_messages_read(p_conversation_id)` (L531 du dump) les
remet à zéro correctement.

### Décision
Pas de migration. **Correctif côté Flutter** seulement : dans
`chat_repository.markRead(...)`, appeler la RPC au lieu d'un UPDATE direct
(à traiter dans Chantier 5 🟠).

---

## 4. Audit prescrivait : "services.deposit_* CHECK manquants"

### Réalité
Les contraintes existent :
- `20260408000000_deposit_settings_cap30.sql` : `services_deposit_value_cap` (10–30 %).
- `20260417170000_services_deposit_check.sql` : validation `deposit_type` + clamp.

### Décision
Pas de migration nouvelle. À surveiller côté Flutter : 4 endroits en
dur sur 30 % doivent lire `services.deposit_value` (Chantier 4 🔴).

---

## 5. Tickets INSERT RLS — réel fraud vector

### Audit
Mentionne `createTickets` client-side comme vecteur de fraude 🔴.

### Réalité
`20260411100000_security_rls_hardening.sql` (non lu dans le dump ci-dessus,
mais référencé dans le récap) définit :

```sql
tickets_buyer_insert
  WITH CHECK (auth.uid() = user_id)
```

→ N'importe quel client peut INSERT son propre ticket depuis Flutter sans
payer. Il faut fermer cette policy au `service_role` uniquement. Seule
l'Edge Function `purchase-tickets-atomic` (Chantier 3) doit pouvoir
insérer.

### Décision
Migration dédiée dans Chantier 2 :
`20260421120000_harden_tickets_insert_rls.sql`.

---

## 6. Policy `flexible` (rappel)

### État
Supprimée par `20260420170000_remove_flexible_cancellation.sql` (valeur
migrée vers `moderate`, CHECK resserré). **CLAUDE.md encore à jour à
corriger** (Chantier 9).

---

## 7. Seuil 48h (UI) vs 24h (backend) — pas une bug backend

### Audit
Présente la divergence comme "risque juridique : UI annonce 48h, backend
rembourse au-delà de 24h".

### Réalité
Le backend est **conforme à CLAUDE.md** :
- `moderate` : >24h full refund, ≤24h 50 % refund (déjà appliqué en
  `cancel-booking/index.ts` — corrigé cosmétiquement en Chantier 3 pour
  expliciter la policy via la constante `POLICY`).
- `strict` : 0 % refund (déjà correct).

**Le 48h est une confusion de CLAUDE.md lui-même** entre deux notions :
- le seuil de payout Stripe (après ~48h les fonds sont transférés, un
  refund nécessite un `transfers.createReversal`) ;
- le seuil cancellation policy visible au client (24h pour moderate).

L'UI `refund_request_screen.dart` affiche les deux indifféremment à 48h
avec "no refund below" — ce qui est donc un **bug Flutter**, pas un bug
backend.

### Décision
- Backend `cancel-booking` renvoie dorénavant `policy`, `hoursThreshold`,
  `refundFraction`, `refundAmount` pour que l'UI affiche la vraie valeur.
- Nouveau endpoint GET `cancellation-policy` : l'UI peut pré-afficher
  le bon seuil **avant** de déclencher l'annulation.
- Chantier 4 listera le fix Flutter (remplacer les 48h hardcodés par
  l'appel au endpoint).
- CLAUDE.md sera reformulé en Chantier 9 pour dissocier les deux seuils.

---

## 8. À VALIDER PAR HUMAIN (liste courte)

Avant toute utilisation en prod :

1. **`post_saves.post_id` → FK `videos.id`** ou `posts.id` ? → Choisi
   `videos.id` car le code Flutter pousse systématiquement un `videoId`.
   Si une table `posts` distincte apparaît plus tard, faire une migration
   de renommage + FK.
2. **`client_favorite_pros` vs `favorites`** — création acceptée comme
   dette technique. OK pour beta ; consolidation v1.1.
3. **`tickets_buyer_insert` fermé au service_role** — impose que toute
   création de ticket passe par `purchase-tickets-atomic` (Chantier 3).
   Pas de régression si l'Edge Function est déployée avant que le
   client Flutter ne soit mis à jour.

