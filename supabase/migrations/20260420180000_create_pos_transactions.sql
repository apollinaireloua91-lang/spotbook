-- Point-of-Sale (POS) Tap to Pay — transactions table
--
-- Records every card-present transaction initiated from the Pro's phone
-- (Tap to Pay on iPhone / Android). Each row is created in `pending` state
-- by the `create-pos-payment-intent` Edge Function and transitioned to
-- `succeeded` / `failed` / `canceled` by the Stripe webhook handler, then
-- optionally to `refunded` / `partially_refunded` by `refund-pos-transaction`.
--
-- The table is append-only; no DELETE policy is exposed. Refunds are
-- reflected via status + refunded_amount_cents, never by removing rows.
--
-- Tax columns are stored in cents on the transaction itself so the Pro's
-- tax settings at the time of sale are frozen even if they change them
-- later in their profile.

-- ── Table ────────────────────────────────────────────────────────────────

create table if not exists public.pos_transactions (
  id                          uuid primary key default extensions.gen_random_uuid(),
  pro_id                      uuid not null references public.profiles_pro(id) on delete cascade,

  -- Stripe linkage — one row per PaymentIntent.
  stripe_payment_intent_id    text not null unique,

  -- Money, all in minor units (cents) to avoid float drift.
  amount_subtotal_cents       integer not null check (amount_subtotal_cents >= 0),
  tip_cents                   integer not null default 0 check (tip_cents >= 0),
  tps_cents                   integer not null default 0 check (tps_cents >= 0),
  tvq_cents                   integer not null default 0 check (tvq_cents >= 0),
  amount_total_cents          integer not null check (amount_total_cents > 0),
  application_fee_cents       integer not null check (application_fee_cents >= 0),
  currency                    text    not null default 'cad',

  -- State machine. Immutable history after terminal states.
  status                      text    not null check (
    status in (
      'pending',
      'succeeded',
      'failed',
      'refunded',
      'partially_refunded',
      'canceled'
    )
  ),

  -- Payment method details — only what Stripe returns publicly (brand, last4).
  payment_method_type         text,
  payment_method_brand        text,
  payment_method_last4        text,

  -- Optional digital receipt destination.
  customer_email              text,
  customer_phone              text,
  receipt_sent                boolean not null default false,
  receipt_sent_at             timestamptz,

  -- Refund accounting.
  refunded_amount_cents       integer not null default 0
                              check (refunded_amount_cents >= 0),

  -- Diagnostic (Stripe decline_code / failure_message).
  failure_reason              text,

  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

comment on table public.pos_transactions is
  'In-person (Tap to Pay) card-present transactions initiated from the Pro app.';
comment on column public.pos_transactions.application_fee_cents is
  'Spotbook commission + fixed service fee routed via Stripe application_fee_amount.';
comment on column public.pos_transactions.refunded_amount_cents is
  'Cumulative amount refunded in cents. 0 = none, = amount_total_cents → status refunded, in between → partially_refunded.';

-- ── Indexes ──────────────────────────────────────────────────────────────

create index if not exists pos_transactions_pro_id_idx
  on public.pos_transactions(pro_id);

create index if not exists pos_transactions_status_idx
  on public.pos_transactions(status);

-- History views are always "most recent first" per pro.
create index if not exists pos_transactions_pro_created_idx
  on public.pos_transactions(pro_id, created_at desc);

-- ── updated_at trigger ───────────────────────────────────────────────────

create or replace trigger tr_pos_transactions_updated_at
  before update on public.pos_transactions
  for each row execute function public.update_updated_at();

-- ── Row-level security ───────────────────────────────────────────────────
--
-- A pro can read / insert / update only their own rows. No DELETE policy
-- is created on purpose (transactions are append-only — refunds mutate
-- status, never remove).
-- The Edge Functions use the service_role key and bypass RLS; the policies
-- below govern direct PostgREST access from the Flutter client when the Pro
-- reads their own history.

alter table public.pos_transactions enable row level security;

drop policy if exists pos_transactions_select_own on public.pos_transactions;
create policy pos_transactions_select_own
  on public.pos_transactions
  for select
  to authenticated
  using (auth.uid() = pro_id);

drop policy if exists pos_transactions_insert_own on public.pos_transactions;
create policy pos_transactions_insert_own
  on public.pos_transactions
  for insert
  to authenticated
  with check (auth.uid() = pro_id);

drop policy if exists pos_transactions_update_own on public.pos_transactions;
create policy pos_transactions_update_own
  on public.pos_transactions
  for update
  to authenticated
  using (auth.uid() = pro_id)
  with check (auth.uid() = pro_id);

-- ── Grants ───────────────────────────────────────────────────────────────

grant select, insert, update on table public.pos_transactions to authenticated;
grant all on table public.pos_transactions to service_role;

-- ── profiles_pro: optional tax registration fields (for receipts) ────────
--
-- Quebec/Canada: TPS (GST) number format is 9 digits + RT0001, TVQ (QST)
-- is 10 digits + TQ0001. Pros can leave these NULL if they are below the
-- "small supplier" threshold (< 30 000 CAD/year) and do not collect taxes.

alter table public.profiles_pro
  add column if not exists tax_number_tps text,
  add column if not exists tax_number_tvq text,
  add column if not exists pos_apply_taxes boolean not null default true;

comment on column public.profiles_pro.tax_number_tps is
  'GST/TPS registration number displayed on POS receipts. Nullable for pros under the small-supplier threshold.';
comment on column public.profiles_pro.tax_number_tvq is
  'QST/TVQ registration number displayed on POS receipts. Nullable for pros under the small-supplier threshold.';
comment on column public.profiles_pro.pos_apply_taxes is
  'When false, POS flow skips TPS/TVQ calculation (non-taxable services or under-threshold Pro).';
