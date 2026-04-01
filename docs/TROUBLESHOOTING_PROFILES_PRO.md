# Dépannage — `profiles_pro` / profil Pro (Supabase + Flutter)

## Erreurs fréquentes

### `PGRST204` — colonne introuvable dans le cache schéma

- Le client envoie un nom de colonne qui **n’existe pas** sur la table distante (ex. `user_id` au lieu de `id`, ou `tel` / `latitude` non créés).
- **Côté app (Spotbook)** : `profiles_pro` utilise **`id`** (UUID = `auth.users.id`), **`description`** (texte métier), **`tel`** (KYC), filtres **`.eq('id', uid)`**.

### RLS — insert / update refusé

- Avant la migration **011**, seul un **SELECT** public existait sur `profiles_pro` : le **premier enregistrement** (INSERT) pouvait être bloqué.

## Action obligatoire sur le projet Supabase

Exécuter **une fois** le script agrégé :

- Fichier : **`docs/supabase_fix_profiles_pro_remote.sql`**

Il ajoute notamment :

- `profiles_pro.tel`, `profiles_pro.updated_at`
- policy **`profiles_pro_own_insert`**
- `users.latitude`, `users.longitude`
- `NOTIFY pgrst, 'reload schema'` (recharge du cache PostgREST)

Vérifier que l’URL / clé anon dans **`.env.json`** / `--dart-define-from-file` pointent vers **ce même projet**.

## Après modification SQL

- Redémarrer l’app (**pas** seulement hot reload si le crash est au démarrage).
- En cas de doute sur le cache : Dashboard Supabase → **API** → recharger / attendre quelques minutes après `NOTIFY`.

## Référence code

- Repository : `lib/features/auth/data/profile_repository.dart`
- Migrations : `supabase/migrations/010_*`, `011_*`, `012_*`
