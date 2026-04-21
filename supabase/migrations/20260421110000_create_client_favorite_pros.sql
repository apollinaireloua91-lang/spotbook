-- client_favorite_pros — liste des pros mis en favoris par un client.
--
-- Le Flutter (`profile_repository.dart` L192-200) requête :
--   from('client_favorite_pros')
--     .select('*, users!pro_id(id, full_name, display_name, avatar_url,
--                              profiles_pro(...))')
--     .eq('client_id', uid)
-- Le JOIN explicite `users!pro_id` requiert que la colonne `pro_id` soit
-- une FK vers `public.users(id)` (PostgREST embedding).
--
-- Note de dette technique : la table `favorites` (`target_type='pro'`)
-- couvre déjà ce besoin fonctionnellement. On crée `client_favorite_pros`
-- comme table spécialisée parce que (a) le code client s'y attend déjà,
-- (b) le JOIN PostgREST est plus simple et plus rapide que sur une table
-- polymorphe. Consolidation éventuelle en v1.1 — à lister dans
-- docs/APOLLINAIRE_TODO.md.
--
-- Voir docs/AUDIT_REPORT_CORRECTIONS.md §2.

begin;

-- ── Table ────────────────────────────────────────────────────────────────

create table if not exists public.client_favorite_pros (
  client_id   uuid not null references public.users(id) on delete cascade,
  pro_id      uuid not null references public.users(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (client_id, pro_id),
  constraint client_favorite_pros_not_self check (client_id <> pro_id)
);

comment on table public.client_favorite_pros is
  'Pros marqués en favori par un client. Redondante avec favorites(target_type=''pro'') — consolidation prévue v1.1.';
comment on constraint client_favorite_pros_not_self on public.client_favorite_pros is
  'Un user ne peut pas se mettre lui-même en favori (cas absurde qui polluerait les suggestions).';

-- ── Indexes ──────────────────────────────────────────────────────────────
-- PK (client_id, pro_id) couvre "les favoris de ce client" + l'unicité.
-- On indexe aussi par pro_id pour "combien de clients ont ce pro en favori",
-- utile pour ranking futur.

create index if not exists client_favorite_pros_pro_idx
  on public.client_favorite_pros(pro_id);

-- ── RLS ──────────────────────────────────────────────────────────────────
-- Seul le client peut voir/écrire ses propres favoris. Un pro ne peut pas
-- lister qui l'a ajouté en favori (vie privée du client). Les stats
-- agrégées (count par pro) passeront par une RPC dédiée au service_role.

alter table public.client_favorite_pros enable row level security;

drop policy if exists client_favorite_pros_select_own on public.client_favorite_pros;
create policy client_favorite_pros_select_own
  on public.client_favorite_pros
  for select
  to authenticated
  using (auth.uid() = client_id);

drop policy if exists client_favorite_pros_insert_own on public.client_favorite_pros;
create policy client_favorite_pros_insert_own
  on public.client_favorite_pros
  for insert
  to authenticated
  with check (auth.uid() = client_id);

drop policy if exists client_favorite_pros_delete_own on public.client_favorite_pros;
create policy client_favorite_pros_delete_own
  on public.client_favorite_pros
  for delete
  to authenticated
  using (auth.uid() = client_id);

-- ── Grants ───────────────────────────────────────────────────────────────

grant select, insert, delete on table public.client_favorite_pros to authenticated;
grant all on table public.client_favorite_pros to service_role;

commit;

-- ── DOWN (manuel, commenté) ──────────────────────────────────────────────
-- begin;
-- drop policy if exists client_favorite_pros_delete_own on public.client_favorite_pros;
-- drop policy if exists client_favorite_pros_insert_own on public.client_favorite_pros;
-- drop policy if exists client_favorite_pros_select_own on public.client_favorite_pros;
-- drop index if exists public.client_favorite_pros_pro_idx;
-- drop table if exists public.client_favorite_pros;
-- commit;
