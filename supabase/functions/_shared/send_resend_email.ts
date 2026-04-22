// ════════════════════════════════════════════════════════════════════════════
// send_resend_email.ts — Unified email dispatcher (Resend template + HTML fallback)
// ────────────────────────────────────────────────────────────────────────────
// Call sites invoke `sendResendEmail({ event, to, variables })`. The wrapper:
//
//   1. Looks up `event` in RESEND_TEMPLATES. If present, POSTs to Resend with
//      `template: { id, variables }` (Resend's canonical shape — accepts id,
//      not alias, for the /emails endpoint).
//   2. If the template call fails (network, 4xx, template missing) → logs a
//      structured warning and falls through to step 3.
//   3. Resolves the event against `buildEmail()` in `email_templates.ts`. If
//      a matching HTML template exists, POSTs the rendered HTML. This is the
//      path for `pos_receipt` (intentionally template-less) and every event
//      whose Resend template isn't published yet.
//   4. If neither path works, returns a structured `{ ok: false }` result.
//      **Never throws** — call sites treat email as fire-and-forget.
//
// Why nest template under `{ id, variables }` instead of a flat payload?
// Resend's API is strict: `template` and `html` are mutually exclusive; the
// template shape expects a nested object. Mixing shapes yields a 422.
//
// ⚠ Deno-only. Never imported from Flutter.
// ════════════════════════════════════════════════════════════════════════════

import { buildEmail, type EmailResult } from "./email_templates.ts";
import {
  type EmailEventKey,
  RESEND_TEMPLATES,
} from "./resend_template_aliases.ts";

/** Verified sender for all Spotbook transactional mail. Domain must stay in
 *  sync with the verified sender in the Resend dashboard — changing it here
 *  without updating the dashboard will produce 403s. */
const FROM = "Spotbook <noreply@getspotbook.app>";

const RESEND_URL = "https://api.resend.com/emails";

export interface SendResendEmailArgs {
  /** Stable Spotbook event key. Drives template lookup + HTML fallback. */
  readonly event: EmailEventKey;
  /** Primary recipient. Must pass a basic `@` check — we don't validate RFC. */
  readonly to: string;
  /** Data passed to the Resend template or `buildEmail()`. The Resend template
   *  reads these as `{{ variable_name }}` in the designer; `buildEmail` maps
   *  to per-event TypeScript interfaces (e.g., `BookingConfirmedData`). */
  readonly variables: Record<string, unknown>;
  /** Escape hatch for call sites that want to force a custom HTML payload
   *  (bypassing both the Resend template and `buildEmail`). Rarely needed. */
  readonly fallbackHtml?: EmailResult;
}

export interface SendResendEmailResult {
  readonly ok: boolean;
  /** `resend` = template API used; `html` = HTML payload used; `noop` = skipped
   *  before reaching the network (e.g., API key missing, no fallback). */
  readonly mode: "resend" | "html" | "noop";
  readonly emailId?: string;
  readonly error?: string;
  /** Present when `mode === 'resend'`. Lets log consumers correlate with the
   *  Resend dashboard without reverse-engineering the event → alias map. */
  readonly alias?: string;
}

/**
 * Posts a transactional email via Resend. Resolves to a structured result —
 * never throws. Emits a `console.error` / `console.warn` on failure so Sentry
 * captures it through the Edge Function runtime's stderr bridge.
 */
export async function sendResendEmail(
  args: SendResendEmailArgs,
): Promise<SendResendEmailResult> {
  const apiKey = Deno.env.get("RESEND_API_KEY");
  if (!apiKey) {
    console.error(
      `[sendResendEmail] RESEND_API_KEY missing — skipping event=${args.event}`,
    );
    return { ok: false, mode: "noop", error: "api_key_missing" };
  }

  if (!args.to || !args.to.includes("@")) {
    console.error(
      `[sendResendEmail] invalid recipient for event=${args.event}`,
    );
    return { ok: false, mode: "noop", error: "invalid_recipient" };
  }

  const template = RESEND_TEMPLATES[args.event];

  // ── Path 1: Resend template ──
  if (template) {
    const res = await postJson(apiKey, {
      from: FROM,
      to: [args.to],
      template: { id: template.id, variables: args.variables },
    });
    if (res.ok) {
      return {
        ok: true,
        mode: "resend",
        emailId: res.id,
        alias: template.alias,
      };
    }
    console.warn(
      `[sendResendEmail] template=${template.alias} failed status=${res.status} for event=${args.event} — falling back to HTML`,
      res.detail,
    );
  }

  // ── Path 2: HTML fallback via buildEmail() (or explicit override) ──
  let fallback: EmailResult;
  if (args.fallbackHtml) {
    fallback = args.fallbackHtml;
  } else {
    try {
      fallback = buildEmail(args.event, args.variables);
    } catch (_e) {
      console.error(
        `[sendResendEmail] no HTML fallback for event=${args.event} and template=${template?.alias ?? "(none)"} unavailable`,
      );
      return { ok: false, mode: "noop", error: "no_fallback" };
    }
  }

  const htmlRes = await postJson(apiKey, {
    from: FROM,
    to: [args.to],
    subject: fallback.subject,
    html: fallback.html,
  });
  if (htmlRes.ok) {
    return { ok: true, mode: "html", emailId: htmlRes.id };
  }
  console.error(
    `[sendResendEmail] html send failed status=${htmlRes.status} for event=${args.event}`,
    htmlRes.detail,
  );
  return {
    ok: false,
    mode: "html",
    error: `html_send_failed_${htmlRes.status}`,
  };
}

// ── Internals ────────────────────────────────────────────────────────────

/** Payload shapes Resend accepts at /emails. `template` and `html` are
 *  mutually exclusive per Resend's API contract. */
type ResendBody =
  | {
      from: string;
      to: string[];
      template: { id: string; variables: Record<string, unknown> };
    }
  | {
      from: string;
      to: string[];
      subject: string;
      html: string;
    };

interface ResendPostResult {
  ok: boolean;
  status: number;
  id?: string;
  detail?: string;
}

async function postJson(
  apiKey: string,
  body: ResendBody,
): Promise<ResendPostResult> {
  try {
    const res = await fetch(RESEND_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const detail = await res.text().catch(() => "");
      return { ok: false, status: res.status, detail };
    }
    const data = (await res.json().catch(() => ({}))) as { id?: string };
    return { ok: true, status: res.status, id: data?.id };
  } catch (err) {
    return { ok: false, status: 0, detail: String(err) };
  }
}
