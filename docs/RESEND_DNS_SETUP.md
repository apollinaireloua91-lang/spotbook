# Resend — DNS Setup for getspotbook.app

Resend requires domain verification via DNS records before sending emails
from `noreply@getspotbook.app`. Since DNS is managed by Cloudflare, add
these records in the Cloudflare dashboard.

## 1. Verify domain in Resend

1. Go to [Resend Dashboard → Domains](https://resend.com/domains)
2. Click **Add Domain** → enter `getspotbook.app`
3. Resend will display the DNS records below — copy exact values from there

## 2. Add DNS records in Cloudflare

> Cloudflare Dashboard → DNS → Records → Add Record
> **Proxy status**: All records below must be **DNS only** (grey cloud)

### SPF (Sender Policy Framework)

| Type | Name              | Content                                          | TTL  |
|------|-------------------|--------------------------------------------------|------|
| TXT  | `getspotbook.app` | `v=spf1 include:send.resend.com ~all`            | Auto |

> If an SPF record already exists, **append** `include:send.resend.com`
> before `~all` rather than creating a second TXT record. Only one SPF
> record per domain is allowed.

### DKIM (DomainKeys Identified Mail)

Resend provides 3 CNAME records for DKIM signing. The exact values are
shown in the Resend domain verification screen.

| Type  | Name                                 | Target                          | TTL  |
|-------|--------------------------------------|---------------------------------|------|
| CNAME | `resend._domainkey.getspotbook.app`  | *(value from Resend dashboard)* | Auto |
| CNAME | `resend2._domainkey.getspotbook.app` | *(value from Resend dashboard)* | Auto |
| CNAME | `resend3._domainkey.getspotbook.app` | *(value from Resend dashboard)* | Auto |

### DMARC (Domain-based Message Authentication)

| Type | Name                         | Content                                               | TTL  |
|------|------------------------------|-------------------------------------------------------|------|
| TXT  | `_dmarc.getspotbook.app`     | `v=DMARC1; p=quarantine; rua=mailto:dmarc@getspotbook.app` | Auto |

> Start with `p=quarantine`. Once deliverability is confirmed (check
> Resend analytics for 1-2 weeks), upgrade to `p=reject` for maximum
> protection against spoofing.

### Return-Path (optional, improves deliverability)

| Type  | Name                           | Target                          | TTL  |
|-------|--------------------------------|---------------------------------|------|
| CNAME | `bounces.getspotbook.app`      | *(value from Resend dashboard)* | Auto |

## 3. Verify in Resend

After adding all records, return to Resend Dashboard → Domains and click
**Verify**. DNS propagation typically takes 5-30 minutes via Cloudflare.

## 4. Add secret to Supabase

```bash
# Supabase Dashboard → Project Settings → Edge Functions → Secrets
# Or via CLI:
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxx
```

## 5. Test

```bash
# Quick test via curl (replace with your Resend API key)
curl -X POST https://api.resend.com/emails \
  -H "Authorization: Bearer re_xxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "Spotbook <noreply@getspotbook.app>",
    "to": ["test@example.com"],
    "subject": "Test Spotbook",
    "html": "<p>Email test OK</p>"
  }'
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| SPF fail | Ensure no duplicate SPF TXT records; merge into one |
| DKIM fail | CNAME records must be **DNS only** (grey cloud in Cloudflare) |
| Emails go to spam | Wait for DMARC warm-up; check Resend analytics |
| 403 from Resend | Verify `RESEND_API_KEY` is set in Supabase secrets |
