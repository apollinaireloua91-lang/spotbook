-- post_saves — "Enregistrer pour plus tard" côté client sur une vidéo.
--
-- Le Flutter (`video_repository.dart` L237-250) fait un upsert sur
-- (user_id, post_id) quand le client tape l'icône bookmark d'un post du feed
-- et un DELETE sur la même clé pour désenregistrer. La colonne s'appelle
-- `post_id` côté client par cohérence sémantique "post" (= publication au
-- sens produit), mais techniquement elle pointe sur `videos.id` aujourd'hui :
-- le modèle produit ne sépare pas encore posts et vidéos. Si une table
-- `posts` distincte apparaît plus tard, il faudra une migration qui
-- transfère le FK en conservant les IDs existants.
--
-- PK composite (user_id, post_id) — un même client ne peut enregistrer le
-- même post qu'une fois ; `upsert onConflict='user_id, post_id'` s'aligne
-- dessus. Pas de colonne `id uuid` séparée : inutile et gaspille un index.

begin;

-- ── Table ────────────────────────────────────────────────────────────────

create table if not exists public.post_saves (
  user_id     uuid not null references auth.users(id)        on delete cascade,
  post_id     uuid not null references public.videos(id)     on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, post_id)
);

comment on table public.post_saves is
  'Bookmarks client sur un post/vidéo du feed. PK composite (user_id, post_id).';
comment on column public.post_saves.post_id is
  'Aujourd''hui FK vers videos.id. Renommer en video_id ou remapper vers posts.id si les deux notions se séparent.';

-- ── Indexes ──────────────────────────────────────────────────────────────
-- La PK (user_id, post_id) couvre déjà les lookups "les saves d'un user".
-- On ajoute un index inverse pour les rares requêtes "qui a save ce post ?"
-- (stats admin, éventuels counters).

create index if not exists post_saves_post_created_idx
  on public.post_saves(post_id, created_at desc);

-- ── RLS ──────────────────────────────────────────────────────────────────
-- Le client n'a accès qu'à ses propres saves, jamais à ceux des autres.
-- Pas de policy UPDATE : un save n'a rien à modifier (unsave = DELETE).

alter table public.post_saves enable row level security;

drop policy if exists post_saves_select_own on public.post_saves;
create policy post_saves_select_own
  on public.post_saves
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists post_saves_insert_own on public.post_saves;
create policy post_saves_insert_own
  on public.post_saves
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists post_saves_delete_own on public.post_saves;
create policy post_saves_delete_own
  on public.post_saves
  for delete
  to authenticated
  using (auth.uid() = user_id);

-- ── Grants ───────────────────────────────────────────────────────────────

grant select, insert, delete on table public.post_saves to authenticated;
grant all on table public.post_saves to service_role;

commit;

-- ── DOWN (manuel, commenté) ──────────────────────────────────────────────
-- begin;
-- drop policy if exists post_saves_delete_own  on public.post_saves;
-- drop policy if exists post_saves_insert_own  on public.post_saves;
-- drop policy if exists post_saves_select_own  on public.post_saves;
-- drop index if exists public.post_saves_post_created_idx;
-- drop table if exists public.post_saves;
-- commit;
