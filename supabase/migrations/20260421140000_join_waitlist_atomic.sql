-- join_waitlist_atomic
-- ────────────────────
-- Remplace le pattern TOCTOU actuel dans `event_repository.joinWaitlist` :
--     count = SELECT count(*) FROM waitlist WHERE ticket_type_id = X
--     UPSERT waitlist(..., position = count + 1)
-- Si deux users rejoignent simultanément, les deux SELECTs voient le même
-- count → deux positions identiques → collision silencieuse.
--
-- La RPC prend un verrou consultatif transactionnel sur un hash du
-- ticket_type_id. Les autres transactions sur le même type attendent ;
-- celles sur d'autres types passent librement. Pas de blocage global.
--
-- Retour :
--   - position : rang assigné au user dans la file
--   - already_in : TRUE si le user était déjà présent (upsert = idempotent)

begin;

create or replace function public.join_waitlist_atomic(
  p_ticket_type_id uuid,
  p_user_id        uuid
) returns table(position integer, already_in boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_position       integer;
  v_existing       integer;
begin
  if p_ticket_type_id is null or p_user_id is null then
    raise exception 'p_ticket_type_id et p_user_id requis';
  end if;

  -- Verrou per-ticket_type pour sérialiser les INSERT concurrents.
  -- hashtext() → bigint qui collisionne rarement ; collision bénigne =
  -- deux types différents prennent le même lock = attente inutile mais
  -- pas d'incorrection.
  perform pg_advisory_xact_lock(hashtext(p_ticket_type_id::text));

  select w.position
    into v_existing
    from public.waitlist w
   where w.ticket_type_id = p_ticket_type_id
     and w.user_id = p_user_id
   limit 1;

  if v_existing is not null then
    return query select v_existing, true;
    return;
  end if;

  select coalesce(max(w.position), 0) + 1
    into v_position
    from public.waitlist w
   where w.ticket_type_id = p_ticket_type_id;

  insert into public.waitlist(ticket_type_id, user_id, position)
  values (p_ticket_type_id, p_user_id, v_position);

  return query select v_position, false;
end;
$$;

comment on function public.join_waitlist_atomic(uuid, uuid) is
  'Ajoute un user à la waitlist d''un ticket_type de façon atomique (advisory lock). Idempotent : si déjà présent, renvoie sa position existante avec already_in=TRUE.';

grant execute on function public.join_waitlist_atomic(uuid, uuid)
  to authenticated, service_role;

commit;

-- ── DOWN (manuel, commenté) ──────────────────────────────────────────────
-- begin;
-- drop function if exists public.join_waitlist_atomic(uuid, uuid);
-- commit;
