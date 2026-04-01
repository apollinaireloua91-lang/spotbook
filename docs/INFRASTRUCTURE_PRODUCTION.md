# SpotBook — Infrastructure production (Supabase, DNS, Cloudflare)

Domaine principal : **getspotbook.app**

## 1. Principe : ne pas mettre Supabase derrière Cloudflare en proxy

- L’URL API, Auth, Realtime, Storage et Edge Functions **restent** celles fournies par Supabase : `https://<project-ref>.supabase.co`.
- Mettre un CNAME du type `api.getspotbook.app` → `xxx.supabase.co` avec **proxy Cloudflare activé (orange cloud)** casse en général les certificats TLS et/ou les WebSockets Realtime.
- Le **custom domain** Supabase (payant / configuration dashboard) est optionnel pour un MVP ; ce n’est **pas** requis pour sécuriser l’app mobile.

## 2. DNS recommandé (Cloudflare)

| Usage | Type | Host | Cible | Proxy | Pourquoi |
|-------|------|------|-------|-------|----------|
| Site marketing / landing | A ou CNAME | `@` | Hébergeur statique (Pages, Vercel, etc.) | **ON** | WAF, cache, HTTPS gérés par Cloudflare |
| Redirection canonique | CNAME | `www` | Même cible que `@` ou redirect rule | **ON** | Cohérence SEO |
| **api / upload vers Supabase** | — | — | *Aucun sous-domaine custom MVP* | — | Utiliser `*.supabase.co` côté app |
| **Auth / Storage / Functions** | — | — | *Idem* | — | Idem |
| Vérification domaine (Google, etc.) | TXT | `@` ou `_google...` | Valeur fournie | DNS only | Selon fournisseur |
| SPF / DKIM email (transactionnel) | TXT | selon SMTP | Fourni par Sendgrid / Resend / etc. | DNS only | Délivrabilité |

**À ne pas créer pour le MVP** : `api.getspotbook.app` pointant vers Supabase en proxy orange.

**Optionnel plus tard** : sous-domaine `app.getspotbook.app` uniquement si vous servez une **PWA / portail web** ; toujours sans mélanger le trafic Realtime Supabase avec un proxy opaque.

## 3. Flutter — variables d’environnement

- `SUPABASE_URL` = `https://<project-ref>.supabase.co`
- `SUPABASE_ANON_KEY` = clé **anon** (publique dans l’app — c’est normal ; la sécurité vient des **RLS** et des **Edge Functions**).
- Jamais de `service_role` ni de secrets Stripe dans le binaire Flutter ; utiliser `--dart-define-from-file` ou `.env` non versionné.

## 4. Edge Functions — secrets Supabase (Dashboard → Edge Functions → Secrets)

| Secret | Rôle |
|--------|------|
| `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` | Paiements |
| `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN` | Direct upload Stream |
| `QR_SIGNING_SECRET` | **Obligatoire** (≥ 16 caractères) — signature QR billets |
| `FCM_PROJECT_ID`, `FCM_SERVER_KEY` | Push (si utilisé) |
| `EDGE_CORS_ORIGIN` | Origine CORS par défaut si pas d’`Origin` (ex. `https://getspotbook.app`) |
| `EDGE_ALLOWED_ORIGINS` | Liste séparée par virgules pour refléter `Origin` (web) |
| `SPOTBOOK_WEB_BASE_URL` | Base des URLs return Stripe Connect (défaut `https://getspotbook.app`) |
| `CLOUDFLARE_STREAM_REQUIRE_SIGNED_URLS` | `true` seulement après implémentation des **tokens de lecture** côté app |

`SUPABASE_SERVICE_ROLE_KEY` est injecté automatiquement par l’hébergeur ; ne pas le dupliquer dans le client.

## 5. Stripe webhooks

- URL : `https://<project-ref>.supabase.co/functions/v1/stripe-webhook-handler`
- Ne pas faire transiter le webhook par Cloudflare Worker sauf besoin avancé (signature Stripe suffit si endpoint direct Supabase).
- Dans `supabase/config.toml`, `verify_jwt = false` pour cette fonction (déjà configuré dans le dépôt).

## 6. Cloudflare — réglages conseillés

**Maintenant (gratuit / standard)**  
- SSL/TLS : **Full (strict)** si origine a un certificat valide.  
- **Always Use HTTPS** : activé.  
- **HSTS** : activé sur le zone apex (après validation).  
- **Bot Fight Mode** : utile sur la landing uniquement.  
- Règles Page : redirection `http` → `https`, éventuellement `www` → apex.

**Attention**  
- Ne pas appliquer de WAF agressive sur des hôtes qui ne sont **pas** sous votre contrôle (ex. ne pas proxyfier `*.supabase.co`).

**Plus tard (payant)**  
- WAF managed rules, Rate Limiting avancé sur la landing, Turnstile sur formulaires web.

## 7. Migrations SQL ajoutées dans ce dépôt

- `20260326210000_security_rate_limit_upload.sql` — scope `upload` pour le rate limiting.
- `20260326210001_storage_event_media_pro_only.sql` — bucket `event-media` : insert uniquement dans `{uid}/...`.

Appliquer avec : `supabase db push` ou pipeline CI vers la base distante.

## 8. Cron / tâches planifiées

Les fonctions `schedule-reminders` et `trigger-review-request` exigent l’en-tête  
`Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>`.

Configurer pg_cron / appel HTTP externe en conséquence (Dashboard Supabase ou orchestrateur).
