# Spotbook POS — Tap to Pay

Branch `agent/refonte-totale-premium` — implementation status as of 2026-04-20.

This doc covers the Point-of-Sale (POS) feature that lets a Pro accept
in-person card payments using Tap to Pay on their own phone, with no
external card reader.

---

## 1. Status snapshot

| Layer | Status |
|-------|--------|
| SQL migration `20260420180000_create_pos_transactions.sql` | ✅ Written, not yet pushed |
| Edge Function `create-pos-payment-intent` | ✅ Written, not deployed |
| Edge Function `send-pos-receipt` | ✅ Written, not deployed |
| Edge Function `refund-pos-transaction` | ✅ Written, not deployed |
| Resend email template `pos_receipt` | ✅ Added to `_shared/email_templates.ts` |
| Flutter models + repository + notifier skeleton | ✅ `lib/features/pos/` — `flutter analyze = 0` |
| Stripe Terminal SDK integration | ⬜ **Stubbed** — see §7 |
| POS UI screens | ⬜ Not in scope for this session (blocked by iOS crash) |
| Pro dashboard POS widget + revenue integration | ⬜ Not in scope for this session |
| Profil Pro tax settings UI | ⬜ Not in scope for this session |

---

## 2. Architecture

```
┌──────────── Pro's iPhone (Tap to Pay) ─────────────┐
│                                                    │
│   PosAmountPage  →  PosReaderPage  →  PosSuccessPage│
│        │                 │                         │
│        │                 ▼                         │
│        │       [mek_stripe_terminal]               │
│        │       Local reader + NFC tap              │
│        │                 │                         │
│        ▼                 ▼                         │
│   PosRepository   PosTerminalDataSource            │
│        │                                           │
└────────┼───────────────────────────────────────────┘
         │ HTTPS, JWT auth
         ▼
┌───────── Supabase Edge Functions ─────────────────┐
│                                                   │
│   create-pos-payment-intent ──▶ Stripe (PI)       │
│   send-pos-receipt          ──▶ Resend (email)    │
│   refund-pos-transaction    ──▶ Stripe (refund)   │
│                                                   │
└───────────┬───────────────────────────────────────┘
            │
            ▼
     pos_transactions
     (row per PI, RLS: pro_id = auth.uid())
```

**Money flow** — destination-charge model with `transfer_data.destination`
set to the Pro's `stripe_account_id`. Stripe takes its cut, sends
`application_fee_amount` (commission + service fee) to Spotbook's platform
account, and credits the rest to the Pro's Connect account.

`application_fee_amount = round(amount_total * commission_rate) + 50 ¢`
where `commission_rate` defaults to `profiles_pro.commission_rate` (0.18)
and the fixed 50 ¢ service fee mirrors what booking transactions charge.

---

## 3. Database

Migration: `supabase/migrations/20260420180000_create_pos_transactions.sql`.

### `pos_transactions`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | `gen_random_uuid()` |
| `pro_id` | uuid FK → `profiles_pro(id)` | `on delete cascade` |
| `stripe_payment_intent_id` | text UNIQUE | `pi_xxx` |
| `amount_subtotal_cents` | int | ≥ 0 |
| `tip_cents` | int | default 0 |
| `tps_cents` | int | 5 % of subtotal (computed client-side) |
| `tvq_cents` | int | 9.975 % of subtotal |
| `amount_total_cents` | int | > 0 |
| `application_fee_cents` | int | ≥ 0 |
| `currency` | text | default `'cad'` |
| `status` | text CHECK | `pending` → `succeeded` / `failed` / `refunded` / `partially_refunded` / `canceled` |
| `payment_method_type / brand / last4` | text | filled by Stripe webhook |
| `customer_email / phone` | text | for digital receipts |
| `receipt_sent / receipt_sent_at` | bool + ts | set by `send-pos-receipt` |
| `refunded_amount_cents` | int | cumulative; drives `status` transition |
| `failure_reason` | text | Stripe `decline_code` / `failure_message` |
| `created_at / updated_at` | timestamptz | `updated_at` auto-refreshed |

Indexes: `pro_id`, `status`, `(pro_id, created_at desc)`.

Trigger: `tr_pos_transactions_updated_at` — reuses the existing
`public.update_updated_at()` function.

### RLS

| Policy | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `pos_transactions_*_own` | `auth.uid() = pro_id` | `auth.uid() = pro_id` | `auth.uid() = pro_id` | — (no policy, append-only) |

Edge Functions use the service-role key and bypass RLS for the
`pending → succeeded` transition written by `stripe-webhook-handler`.

### `profiles_pro` additions

Three new optional columns feed the POS receipt header and the Pro's
tax-calculation preference:

| Column | Type | Default | Purpose |
|---|---|---|---|
| `tax_number_tps` | text | NULL | GST/TPS registration number, printed on receipts |
| `tax_number_tvq` | text | NULL | QST/TVQ registration number, printed on receipts |
| `pos_apply_taxes` | boolean | `true` | UI toggle — when `false`, tps_cents/tvq_cents are zero |

---

## 4. Edge Functions

All three live under `supabase/functions/`. They use the existing
`_shared/security.ts` helpers (`jsonResponse`, `securityHeadersFor`,
`isValidUuid`) and the `_shared/email_templates.ts` dispatcher for emails.

### 4.1 `create-pos-payment-intent`

**Input**
```json
{
  "amount_subtotal_cents": 2500,
  "tip_cents": 300,
  "tps_cents": 125,
  "tvq_cents": 249,
  "currency": "cad",
  "customer_email": "client@example.com",
  "customer_phone": null,
  "client_request_id": "e7a0b1d2-1234-4cde-89ab-1234567890ab"
}
```

**Flow**
1. Validate JWT, parse body.
2. Fetch `profiles_pro.stripe_account_id / commission_rate`; reject 409 if
   the Pro has no Connect account.
3. Compute `application_fee_cents = round(total * rate) + 50 ¢`. Reject 400
   if `application_fee_cents >= amount_total` or total < 50 ¢.
4. Create `PaymentIntent` with
   `payment_method_types=['card_present']`, `capture_method='automatic'`,
   `transfer_data.destination`, `application_fee_amount`.
5. Insert `pos_transactions` row (`status='pending'`). On insert failure,
   cancel the PI so no charge is ever captured on an orphan row.

**Output**
```json
{
  "client_secret": "pi_xxx_secret_xxx",
  "transaction_id": "ff1e…",
  "payment_intent_id": "pi_xxx"
}
```

### 4.2 `send-pos-receipt`

**Input** `{ transaction_id, email, phone }`.

**Flow** — authenticate Pro, confirm transaction ownership + `succeeded` or
`partially_refunded` status, fetch the Pro's business name + tax numbers,
render `pos_receipt` via `buildEmail`, ship to Resend, flip
`receipt_sent=true`.

SMS is *not* wired (no SMS provider configured in the project). If only a
phone is provided, the function acknowledges with
`{ success: true, email_sent: false, sms_sent: false, note: "sms_channel_not_configured" }`.

### 4.3 `refund-pos-transaction`

**Input** `{ transaction_id, amount_cents: number | null, reason }`.

**Flow** — authenticate Pro, confirm ownership + refundable status, compute
remaining refundable amount, call `stripe.refunds.create({
refund_application_fee: true, reverse_transfer: true, ... })` with an
idempotency key of `refund-${tx.id}-${cumulativeRefunded}`. Update the
row's `refunded_amount_cents` and flip `status` to `refunded` or
`partially_refunded`.

---

## 5. Flutter layer (skeleton)

The project's established pattern (`feature/data/*_repository.dart +
*_notifier.dart`, `feature/domain/*_models.dart`) is used, not the full
hexagonal split. See `CLAUDE.md` and prior features (`booking`, `chat`).

```
lib/features/pos/
├── domain/
│   └── pos_models.dart           # PosAmount, PosTransaction, PosPaymentResult, PosRefundResult, enums
└── data/
    ├── pos_repository.dart       # invoke() the 3 Edge Functions + RLS reads on pos_transactions
    ├── pos_terminal.dart         # PosTerminalDataSource abstraction + StubPosTerminalDataSource
    └── pos_notifier.dart         # Riverpod providers (amount input, terminal init, payment lifecycle, history)
```

The Terminal datasource is **stubbed** — every method throws
`UnimplementedError` with a `// TODO(post-crash):` marker so once the iOS
black-screen crash is resolved, `grep -r "TODO(post-crash)"` enumerates
exactly what needs the real SDK bound.

---

## 6. Permissions & platform setup (not yet applied)

### 6.1 iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Spotbook utilise votre position uniquement lors de l'encaissement sans contact pour lutter contre la fraude, conformément aux règles Stripe pour Tap to Pay.</string>

<key>NFCReaderUsageDescription</key>
<string>Spotbook lit les cartes sans contact de vos clients pour traiter leurs paiements.</string>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>Spotbook utilise le Bluetooth pour communiquer avec les lecteurs de carte Stripe.</string>
```

### 6.2 iOS entitlement (`ios/Runner/Runner.entitlements`)

```xml
<key>com.apple.developer.proximity-reader.payment.acceptance</key>
<true/>
```

**Apple capability request** — this entitlement is gated behind a Tap to Pay
approval:
1. Sign in to the Apple Developer Portal with Team ID **QCBH2X6CKT**.
2. Certificates, Identifiers & Profiles → App ID `com.spotbook.app` →
   Capabilities → enable **Tap to Pay on iPhone**.
3. Submit the Tap to Pay on iPhone request form (legal name, business
   description, countries of operation CA + US + FR + CI).
4. Wait 1–4 weeks for Apple review.
5. Regenerate the provisioning profile and rebuild once approved.

### 6.3 Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.NFC"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.INTERNET"/>

<uses-feature android:name="android.hardware.nfc" android:required="true"/>
```

Tap to Pay on Android requires Android 11+ with NFC. The Stripe Terminal
SDK enforces this on `initialize()`.

### 6.4 Stripe Connect — `card_present_payments` capability

- New Pros onboarding via `stripe-connect-onboarding` need
  `capabilities: { card_present_payments: { requested: true } }` appended
  to the account creation call (TODO — not done in this session).
- **Existing Pros** must be updated manually via the Stripe Dashboard or
  an admin script:
  ```bash
  stripe accounts update acct_XXXX \
    --capabilities.card_present_payments.requested=true
  ```
  Each account will stay in `pending` until Stripe finishes its underwriting
  review (typically same-day for CA accounts).

---

## 7. SDK choice — `mek_stripe_terminal`

| Candidate | Version | Last published | Tap to Pay | Decision |
|---|---|---|---|---|
| [`mek_stripe_terminal`](https://pub.dev/packages/mek_stripe_terminal) | 4.6.3 | 4 months ago | ✅ iOS + Android | **Chosen** |
| [`stripe_terminal`](https://pub.dev/packages/stripe_terminal) | 1.5.0 | 23 months ago | ❌ | Deprecated by its maintainer; does not cover payment creation/capture |
| `flutter_stripe` terminal support | — | — | ❌ | Not yet shipped; tracked upstream |
| Platform channels wrapping the native iOS/Android Stripe Terminal SDKs | — | — | ✅ | Fallback if `mek_stripe_terminal` stalls; ~2× effort |

**Integration plan** for `mek_stripe_terminal`:

1. Add `mek_stripe_terminal: ^4.6.3` to `pubspec.yaml`.
2. Implement `MekStripeTerminalDataSource implements PosTerminalDataSource`
   in `lib/features/pos/data/pos_terminal.dart` (or a new file) and wire
   it up as the override for `posTerminalDataSourceProvider`.
3. Create a new Edge Function `create-pos-connection-token` that calls
   `stripe.terminal.connectionTokens.create()` with the authenticated Pro's
   scope — the SDK fetches a fresh token on every init.
4. Call `Terminal.initTerminal(fetchToken: ...)`, then
   `Terminal.connectLocalMobileReader(...)` with the POS location id.
5. `Terminal.collectPaymentMethod(clientSecret)` →
   `Terminal.processPayment(pi)` → result surfaces through
   `PosPaymentResult`.

Keep the `PosTerminalDataSource` abstraction — it lets the widget tests
mock the reader without a physical device.

---

## 8. Backend validation — curl commands

Replace `<JWT>` with a Pro session access-token (pull it from the
Flutter app via `Supabase.instance.client.auth.currentSession!.accessToken`
or via an `auth.signInWithPassword` call in curl).

```bash
BASE="https://api.getspotbook.app/functions/v1"
JWT="<paste-pro-jwt-here>"
CLIENT_REQ_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

# 1. Create PaymentIntent (expect 200 + client_secret)
curl -sS -X POST "$BASE/create-pos-payment-intent" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d "{
    \"amount_subtotal_cents\": 2500,
    \"tip_cents\": 300,
    \"tps_cents\": 125,
    \"tvq_cents\": 249,
    \"client_request_id\": \"$CLIENT_REQ_ID\",
    \"customer_email\": \"test@example.com\"
  }" | jq .

# 2. Send receipt (expect email_sent: true once the PI status → succeeded)
TX_ID="<paste-transaction_id-from-previous-step>"
curl -sS -X POST "$BASE/send-pos-receipt" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d "{\"transaction_id\":\"$TX_ID\",\"email\":\"test@example.com\"}" | jq .

# 3. Refund (full refund of the remaining amount)
curl -sS -X POST "$BASE/refund-pos-transaction" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d "{\"transaction_id\":\"$TX_ID\",\"amount_cents\":null,\"reason\":\"requested_by_customer\"}" | jq .
```

**Error matrix** (sanity spot checks):

| curl tweak | Expected response |
|---|---|
| Drop the `Authorization` header | `401 unauthorized` |
| Set `amount_subtotal_cents: 10` (below 50 ¢) | `400 amount_total_cents must be >= 50` |
| Pass a `transaction_id` owned by another Pro | `403 forbidden` |
| Pass a non-UUID `client_request_id` | `400 client_request_id must be a valid UUID v4` |
| Call `refund-pos-transaction` on a `pending` row | `409 transaction_not_refundable` |

---

## 9. Manual test plan (device)

Tap to Pay **does not** work in the iOS simulator — only a limited
simulated mode is available and it does not exercise the NFC path. Use a
physical device:

| Requirement | Minimum |
|---|---|
| iPhone | XS / SE 2nd gen or newer |
| iOS | 16.4+ |
| Android | 11+ with NFC hardware |
| Apple Developer account | Tap to Pay capability approved |
| Stripe Connect account | `card_present_payments` = `active` |

**Stripe test cards** for sandbox mode — use physical test cards mailed by
Stripe or the simulated PIN pad:

| Card | Expected outcome |
|---|---|
| `4242 4242 4242 4242` (Visa) | Approved |
| `4000 0000 0000 0002` | Declined — `card_declined` |
| `4000 0027 6000 3184` (Authentication required) | Terminal SDK bypasses 3DS for card-present → succeeds |
| `4000 0033 1000 0002` (Interac — Canada only) | Approved if account is CA |

**Step-by-step on-device**:

1. Launch the Pro build in debug, sign in as a Pro with the POS
   capabilities active.
2. Dashboard → "Encaisser un client" (once the UI ships).
3. Enter 25,00 $ subtotal, skip tip, leave taxes applied.
4. Tap "Encaisser" — screen transitions to the Reader page with
   "Approchez la carte".
5. Tap a test card on the back of the iPhone (near the camera bump).
6. Screen transitions to "Traitement..." then Success with the last-4 and
   brand.
7. Tap "Envoyer un reçu" → enter email → confirm Resend delivered.
8. In the Stripe Dashboard, find the transaction, confirm
   `application_fee_amount` landed in the platform account and the
   balance transfer to the Connect account for the net amount.
9. Issue a partial refund via `PosHistoryPage` → verify
   `partially_refunded` status and the Stripe-side fee reversal.

---

## 10. Checklist for Apollinaire (out-of-Claude actions)

- [ ] Fix the iOS crash (black screen at launch) — unrelated to POS, but
      blocks testing any new Flutter code on device.
- [ ] Apply the `20260420180000_create_pos_transactions.sql` migration to
      production:
      ```bash
      supabase db push --linked --include-all
      ```
      Verify with:
      ```bash
      supabase migration list --linked | grep pos_transactions
      ```
- [ ] Deploy the three new Edge Functions:
      ```bash
      supabase functions deploy create-pos-payment-intent
      supabase functions deploy send-pos-receipt
      supabase functions deploy refund-pos-transaction
      ```
      Secrets required: `STRIPE_SECRET_KEY`, `RESEND_API_KEY`,
      `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
      — already present per `project_no_config_push.md` memory.
- [ ] Submit the Tap to Pay on iPhone request to Apple (Team ID
      `QCBH2X6CKT`) — see §6.2. Wait for approval.
- [ ] For each existing Stripe Connect Pro, enable
      `card_present_payments` (Stripe Dashboard or CLI — see §6.4).
- [ ] Once the crash is fixed, extend `stripe-connect-onboarding` to
      request `card_present_payments` at account creation time (new Pros).
- [ ] Sanity-test the `pos_receipt` email layout by triggering a test send
      via the curl snippet in §8; open the email on mobile + desktop and
      verify the tax-number footnote renders correctly.

---

*Generated 2026-04-20 — see `git log -- supabase/migrations/20260420180000_create_pos_transactions.sql` for the exact commit.*
