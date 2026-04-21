-- increment_sold_count_if_available
-- ─────────────────────────────────
-- Version atomique de `increment_sold_count` : réserve `p_quantity` places
-- sur un `ticket_types` uniquement si la capacité totale n'est pas dépassée.
-- Postgres tranche les courses entre acheteurs concurrents via l'UPDATE
-- conditionnel : celui qui écrit le second voit `sold_count + q > quantity`
-- et ne met pas à jour → 0 rangs affectés → la fonction renvoie FALSE.
--
-- Retour booléen (pas d'exception) pour que les Edge Functions décident
-- comment réagir : purchase-tickets-atomic renvoie un 409 `sold_out` et
-- remet un rollback côté Stripe (refund du PI non encore matérialisé en
-- tickets) si besoin.
--
-- Le webhook `stripe-webhook-handler` continuera à utiliser l'ancienne
-- `increment_sold_count` pour préserver la rétro-compatibilité — il ne
-- tombe sur un "sold_out" que dans des cas extrêmes (admin qui réduit
-- `quantity` après l'achat), qu'on traite par audit manuel.

begin;

create or replace function public.increment_sold_count_if_available(
  p_ticket_type_id uuid,
  p_quantity       integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_updated integer;
begin
  if p_quantity is null or p_quantity <= 0 then
    return false;
  end if;

  update public.ticket_types
     set sold_count = coalesce(sold_count, 0) + p_quantity,
         updated_at = now()
   where id = p_ticket_type_id
     and coalesce(sold_count, 0) + p_quantity <= quantity;

  get diagnostics v_updated = row_count;
  return v_updated = 1;
end;
$$;

comment on function public.increment_sold_count_if_available(uuid, integer) is
  'Réserve p_quantity places sur ticket_types de façon atomique. Retourne TRUE si la réservation a réussi, FALSE si capacité insuffisante.';

-- Autoriser authenticated + service_role. L'appel réel passe par le
-- service_role (Edge Function) mais on laisse authenticated en secours
-- pour les tests locaux.
grant execute on function public.increment_sold_count_if_available(uuid, integer)
  to authenticated, service_role;

commit;

-- ── DOWN (manuel, commenté) ──────────────────────────────────────────────
-- begin;
-- drop function if exists public.increment_sold_count_if_available(uuid, integer);
-- commit;
