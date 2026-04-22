/**
 * Spotbook — HTML email templates (Deno Edge Functions).
 *
 * Every template returns { subject, html } ready for Resend.
 * All text is in French (app default language).
 */

// ── Helpers ──────────────────────────────────────────────────────────

/** Format cents → "12,50 $" */
function fmtMoney(cents: number): string {
  const val = (cents / 100).toFixed(2).replace(".", ",");
  return `${val} $`;
}

const APP_URL = "https://getspotbook.app";

// ── Shared layout ────────────────────────────────────────────────────

function layout(subject: string, preheader: string, content: string): string {
  return `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <title>${subject}</title>
  <!--[if mso]><noscript><xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml></noscript><![endif]-->
</head>
<body style="margin:0;padding:0;background-color:#0D0D14;font-family:'DM Sans',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased;">
  <!-- Preheader (hidden) -->
  <div style="display:none;max-height:0;overflow:hidden;mso-hide:all;">${preheader}${"&nbsp;&zwnj;".repeat(20)}</div>

  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#0D0D14;">
    <tr>
      <td align="center" style="padding:40px 16px;">

        <!-- Container -->
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background-color:#1E1E2E;border-radius:16px;overflow:hidden;">
          <!-- Logo -->
          <tr>
            <td style="padding:32px 40px 0;text-align:center;">
              <span style="font-size:20px;font-weight:700;color:#FFFFFF;letter-spacing:-0.3px;text-decoration:none;">Spotbook</span>
            </td>
          </tr>
          <!-- Content -->
          <tr>
            <td style="padding:32px 40px 40px;">
              ${content}
            </td>
          </tr>
        </table>

        <!-- Footer -->
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;">
          <tr>
            <td style="padding:24px 40px;text-align:center;color:#9090AA;font-size:12px;line-height:18px;">
              &copy; 2026 Spotbook Inc. Tous droits r&eacute;serv&eacute;s.
              <br />
              <a href="${APP_URL}/support" style="color:#8B63FF;text-decoration:underline;">Aide</a>
              &nbsp;&middot;&nbsp;
              <a href="${APP_URL}/privacy" style="color:#8B63FF;text-decoration:underline;">Confidentialit&eacute;</a>
              &nbsp;&middot;&nbsp;
              <a href="${APP_URL}/unsubscribe" style="color:#8B63FF;text-decoration:underline;">Se d&eacute;sabonner</a>
            </td>
          </tr>
        </table>

      </td>
    </tr>
  </table>
</body>
</html>`;
}

/** Primary CTA button */
function btn(label: string, href: string): string {
  return `<table role="presentation" cellpadding="0" cellspacing="0" style="margin:28px auto 0;">
  <tr>
    <td align="center" style="background-color:#6C3EF4;border-radius:12px;">
      <a href="${href}" target="_blank" style="display:inline-block;padding:14px 32px;color:#FFFFFF;font-size:15px;font-weight:600;text-decoration:none;border-radius:12px;">
        ${label}
      </a>
    </td>
  </tr>
</table>`;
}

/** Info row: label + value */
function infoRow(label: string, value: string): string {
  return `<tr>
  <td style="padding:6px 0;color:#9090AA;font-size:14px;width:140px;vertical-align:top;">${label}</td>
  <td style="padding:6px 0;color:#FFFFFF;font-size:14px;vertical-align:top;">${value}</td>
</tr>`;
}

/** Info card with rows */
function infoCard(rows: string): string {
  return `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#16161F;border-radius:12px;margin-top:20px;">
  <tr><td style="padding:20px;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
      ${rows}
    </table>
  </td></tr>
</table>`;
}

function heading(text: string): string {
  return `<h1 style="margin:0 0 8px;font-size:22px;font-weight:700;color:#FFFFFF;line-height:28px;">${text}</h1>`;
}

function para(text: string): string {
  return `<p style="margin:0 0 16px;font-size:15px;color:#9090AA;line-height:22px;">${text}</p>`;
}

function divider(): string {
  return `<hr style="border:none;border-top:1px solid #2A2A3A;margin:20px 0;" />`;
}

// ── Templates ────────────────────────────────────────────────────────

export interface EmailResult {
  subject: string;
  html: string;
}

// 1. Booking confirmed
export interface BookingConfirmedData {
  clientName: string;
  serviceName: string;
  providerName: string;
  date: string;
  time: string;
  address: string;
  amountPaid: number;
  deposit?: number;
  remaining?: number;
  bookingId: string;
  qrCodeUrl?: string;
}

export function bookingConfirmed(d: BookingConfirmedData): EmailResult {
  const rows = [
    infoRow("Service", d.serviceName),
    infoRow("Prestataire", d.providerName),
    infoRow("Date", d.date),
    infoRow("Heure", d.time),
    infoRow("Adresse", d.address),
  ].join("");

  let paymentRows = infoRow("Montant pay&eacute;", fmtMoney(d.amountPaid));
  if (d.deposit) {
    paymentRows += infoRow("Acompte vers&eacute;", fmtMoney(d.deposit));
  }
  if (d.remaining) {
    paymentRows += infoRow("Restant &agrave; payer", fmtMoney(d.remaining));
  }

  let qrBlock = "";
  if (d.qrCodeUrl) {
    qrBlock = `<table role="presentation" cellpadding="0" cellspacing="0" style="margin:24px auto;">
  <tr>
    <td align="center" style="background-color:#FFFFFF;border-radius:12px;padding:16px;">
      <img src="${d.qrCodeUrl}" width="180" height="180" alt="QR Code rendez-vous" style="display:block;border:0;" />
    </td>
  </tr>
  <tr>
    <td align="center" style="padding-top:12px;">
      <p style="margin:0;font-size:12px;color:#9090AA;line-height:18px;">Pr&eacute;sentez ce QR code le jour de votre rendez-vous.</p>
    </td>
  </tr>
</table>`;
  }

  const content = [
    heading("R&eacute;servation confirm&eacute;e &#x2713;"),
    para(`Bonjour ${d.clientName},`),
    para("Votre r&eacute;servation est confirm&eacute;e ! Voici les d&eacute;tails :"),
    infoCard(rows),
    qrBlock,
    divider(),
    `<p style="margin:0 0 4px;font-size:13px;font-weight:600;color:#FFFFFF;">R&eacute;capitulatif du paiement</p>`,
    infoCard(paymentRows),
    btn("Voir ma r&eacute;servation", `${APP_URL}/booking/${d.bookingId}`),
  ].join("\n");

  return {
    subject: "R\u00e9servation confirm\u00e9e",
    html: layout("R\u00e9servation confirm\u00e9e", `Votre RDV ${d.serviceName} est confirm\u00e9`, content),
  };
}

// 2. Booking cancelled
export interface BookingCancelledData {
  clientName: string;
  serviceName: string;
  providerName: string;
  date: string;
  refundAmount?: number;
  bookingId: string;
}

export function bookingCancelled(d: BookingCancelledData): EmailResult {
  const rows = [
    infoRow("Service", d.serviceName),
    infoRow("Prestataire", d.providerName),
    infoRow("Date", d.date),
  ].join("");

  let refundBlock = "";
  if (d.refundAmount && d.refundAmount > 0) {
    refundBlock = [
      divider(),
      para(`Un remboursement de <strong style="color:#22C55E;">${fmtMoney(d.refundAmount)}</strong> sera cr&eacute;dit&eacute; sur votre moyen de paiement sous 5 &agrave; 10 jours ouvrables.`),
    ].join("\n");
  }

  const content = [
    heading("R&eacute;servation annul&eacute;e"),
    para(`Bonjour ${d.clientName},`),
    para("Votre r&eacute;servation a &eacute;t&eacute; annul&eacute;e."),
    infoCard(rows),
    refundBlock,
    btn("Re-r&eacute;server", `${APP_URL}/search`),
  ].join("\n");

  return {
    subject: "R\u00e9servation annul\u00e9e",
    html: layout("R\u00e9servation annul\u00e9e", `Votre RDV ${d.serviceName} a \u00e9t\u00e9 annul\u00e9`, content),
  };
}

// 3. Payment receipt
export interface PaymentReceiptData {
  transactionId: string;
  date: string;
  amount: number;
  serviceName: string;
  providerName: string;
  commission?: number;
  isProReceipt?: boolean;
  bookingId: string;
}

export function paymentReceipt(d: PaymentReceiptData): EmailResult {
  let rows = [
    infoRow("Transaction", `<code style="color:#8B63FF;font-size:13px;">${d.transactionId}</code>`),
    infoRow("Date", d.date),
    infoRow("Montant", `<strong style="color:#FFFFFF;">${fmtMoney(d.amount)}</strong>`),
    infoRow("Service", d.serviceName),
    infoRow(d.isProReceipt ? "Client" : "Prestataire", d.providerName),
  ].join("");

  if (d.isProReceipt && d.commission) {
    rows += infoRow("Commission Spotbook", fmtMoney(d.commission));
    rows += infoRow("Votre revenu net", `<strong style="color:#22C55E;">${fmtMoney(d.amount - d.commission)}</strong>`);
  }

  const content = [
    heading("Re&ccedil;u de paiement"),
    para(`Voici le d&eacute;tail de votre transaction.`),
    infoCard(rows),
    btn("T&eacute;l&eacute;charger le re&ccedil;u", `${APP_URL}/receipt/${d.bookingId}`),
  ].join("\n");

  return {
    subject: "Re\u00e7u de paiement",
    html: layout("Re\u00e7u de paiement", `Transaction ${d.transactionId}`, content),
  };
}

// 4. Ticket purchased
export interface TicketPurchasedData {
  clientName: string;
  eventName: string;
  eventDate: string;
  venue: string;
  qrCodeUrl?: string;
  ticketId: string;
}

export function ticketPurchased(d: TicketPurchasedData): EmailResult {
  const rows = [
    infoRow("&Eacute;v&eacute;nement", d.eventName),
    infoRow("Date", d.eventDate),
    infoRow("Lieu", d.venue),
  ].join("");

  let qrBlock = "";
  if (d.qrCodeUrl) {
    qrBlock = `<table role="presentation" cellpadding="0" cellspacing="0" style="margin:24px auto;">
  <tr>
    <td align="center" style="background-color:#FFFFFF;border-radius:12px;padding:16px;">
      <img src="${d.qrCodeUrl}" width="180" height="180" alt="QR Code billet" style="display:block;border:0;" />
    </td>
  </tr>
</table>`;
  }

  const content = [
    heading("Votre billet &#x1F3AB;"),
    para(`Bonjour ${d.clientName},`),
    para(`Votre billet pour <strong style="color:#FFFFFF;">${d.eventName}</strong> est pr&ecirc;t !`),
    infoCard(rows),
    qrBlock,
    para(`<span style="font-size:12px;color:#9090AA;">Pr&eacute;sentez ce QR code &agrave; l'entr&eacute;e de l'&eacute;v&eacute;nement.</span>`),
    btn("Ouvrir dans l'app", `${APP_URL}/ticket/${d.ticketId}`),
  ].join("\n");

  return {
    subject: "Votre billet",
    html: layout("Votre billet", `Billet pour ${d.eventName}`, content),
  };
}

// 5. Booking reminder
export interface BookingReminderData {
  clientName: string;
  serviceName: string;
  providerName: string;
  date: string;
  time: string;
  address: string;
  bookingId: string;
}

export function bookingReminder(d: BookingReminderData): EmailResult {
  const rows = [
    infoRow("Service", d.serviceName),
    infoRow("Prestataire", d.providerName),
    infoRow("Date", d.date),
    infoRow("Heure", d.time),
    infoRow("Adresse", d.address),
  ].join("");

  const content = [
    heading("Rappel : RDV demain &#x1F4C5;"),
    para(`Bonjour ${d.clientName},`),
    para("N'oubliez pas votre rendez-vous pr&eacute;vu demain !"),
    infoCard(rows),
    btn("Voir les d&eacute;tails", `${APP_URL}/booking/${d.bookingId}`),
  ].join("\n");

  return {
    subject: "Rappel : RDV demain",
    html: layout("Rappel : RDV demain", `Votre RDV ${d.serviceName} est demain \u00e0 ${d.time}`, content),
  };
}

// 6. Welcome
export interface WelcomeData {
  userName: string;
}

export function welcome(d: WelcomeData): EmailResult {
  const steps = [
    { num: "1", icon: "&#x1F50D;", title: "D&eacute;couvrez", desc: "Explorez les prestataires pr&egrave;s de chez vous via le feed vid&eacute;o." },
    { num: "2", icon: "&#x1F4C5;", title: "R&eacute;servez", desc: "Choisissez un cr&eacute;neau et r&eacute;servez en quelques taps." },
    { num: "3", icon: "&#x2B50;", title: "&Eacute;valuez", desc: "Laissez un avis apr&egrave;s votre rendez-vous." },
  ];

  const stepsHtml = steps
    .map(
      (s) => `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:16px;">
  <tr>
    <td width="48" style="vertical-align:top;">
      <div style="width:36px;height:36px;background-color:#6C3EF4;border-radius:50%;text-align:center;line-height:36px;font-size:15px;font-weight:700;color:#FFFFFF;">${s.num}</div>
    </td>
    <td style="vertical-align:top;padding-left:12px;">
      <p style="margin:0;font-size:15px;font-weight:600;color:#FFFFFF;">${s.icon} ${s.title}</p>
      <p style="margin:4px 0 0;font-size:14px;color:#9090AA;line-height:20px;">${s.desc}</p>
    </td>
  </tr>
</table>`
    )
    .join("\n");

  const content = [
    heading("Bienvenue sur Spotbook ! &#x1F389;"),
    para(`Bonjour ${d.userName},`),
    para("Merci de nous rejoindre ! Voici comment tirer le meilleur de Spotbook en 3 &eacute;tapes :"),
    divider(),
    stepsHtml,
    divider(),
    btn("Explorer l'app", APP_URL),
  ].join("\n");

  return {
    subject: "Bienvenue sur Spotbook !",
    html: layout("Bienvenue sur Spotbook !", "D\u00e9couvrez, r\u00e9servez et \u00e9valuez les meilleurs prestataires", content),
  };
}

// 7. Review request
export interface ReviewRequestData {
  clientName: string;
  providerName: string;
  serviceName: string;
  bookingId: string;
}

export function reviewRequest(d: ReviewRequestData): EmailResult {
  const stars = `<p style="margin:24px 0;text-align:center;font-size:32px;letter-spacing:4px;color:#FFBB33;">&#9733;&#9733;&#9733;&#9733;&#9733;</p>`;

  const content = [
    heading("Comment s'est pass&eacute; votre RDV ?"),
    para(`Bonjour ${d.clientName},`),
    para(`Votre rendez-vous <strong style="color:#FFFFFF;">${d.serviceName}</strong> avec <strong style="color:#FFFFFF;">${d.providerName}</strong> est termin&eacute;. Votre avis compte !`),
    stars,
    para(`<span style="text-align:center;display:block;">Notez votre exp&eacute;rience et aidez la communaut&eacute; Spotbook.</span>`),
    btn("Laisser un avis", `${APP_URL}/review/${d.bookingId}`),
  ].join("\n");

  return {
    subject: "Comment s\u2019est pass\u00e9 votre RDV ?",
    html: layout("Comment s\u2019est pass\u00e9 votre RDV ?", `Donnez votre avis sur ${d.serviceName}`, content),
  };
}

// 8. POS receipt — in-person Tap to Pay transaction
export interface PosReceiptData {
  proName: string;
  date: string;
  subtotalCents: number;
  tipCents: number;
  tpsCents: number;
  tvqCents: number;
  totalCents: number;
  cardBrand?: string; // 'Visa' | 'Mastercard' | 'Interac' | 'Apple Pay' | …
  cardLast4?: string;
  taxNumberTps?: string;
  taxNumberTvq?: string;
  transactionId: string;
}

export function posReceipt(d: PosReceiptData): EmailResult {
  const rows: string[] = [
    infoRow("Date", d.date),
    infoRow("Sous-total", fmtMoney(d.subtotalCents)),
  ];
  if (d.tipCents > 0) {
    rows.push(infoRow("Pourboire", fmtMoney(d.tipCents)));
  }
  if (d.tpsCents > 0) {
    const tpsLabel = d.taxNumberTps
      ? `TPS <span style="font-size:11px;color:#9090AA;">(${d.taxNumberTps})</span>`
      : "TPS";
    rows.push(infoRow(tpsLabel, fmtMoney(d.tpsCents)));
  }
  if (d.tvqCents > 0) {
    const tvqLabel = d.taxNumberTvq
      ? `TVQ <span style="font-size:11px;color:#9090AA;">(${d.taxNumberTvq})</span>`
      : "TVQ";
    rows.push(infoRow(tvqLabel, fmtMoney(d.tvqCents)));
  }
  rows.push(
    infoRow(
      "<strong>Total</strong>",
      `<strong style="color:#FFFFFF;font-size:16px;">${fmtMoney(d.totalCents)}</strong>`,
    ),
  );

  if (d.cardBrand && d.cardLast4) {
    rows.push(
      infoRow(
        "Paiement",
        `${d.cardBrand} &bull;&bull;&bull;&bull; ${d.cardLast4}`,
      ),
    );
  } else if (d.cardBrand) {
    rows.push(infoRow("Paiement", d.cardBrand));
  }
  rows.push(
    infoRow(
      "Transaction",
      `<code style="color:#8B63FF;font-size:12px;">${d.transactionId}</code>`,
    ),
  );

  const content = [
    heading("Re&ccedil;u de paiement"),
    para(
      `Merci pour votre achat aupr&egrave;s de <strong style="color:#FFFFFF;">${d.proName}</strong>.`,
    ),
    infoCard(rows.join("")),
    divider(),
    `<p style="margin:0;font-size:12px;color:#9090AA;line-height:18px;">Conservez ce re&ccedil;u pour vos dossiers. Aucune donn&eacute;e de carte compl&egrave;te n'est stock&eacute;e par Spotbook.</p>`,
  ].join("\n");

  return {
    subject: `Re\u00e7u — ${d.proName}`,
    html: layout(
      `Re\u00e7u — ${d.proName}`,
      `Paiement de ${fmtMoney(d.totalCents)} chez ${d.proName}`,
      content,
    ),
  };
}

// ── Dispatcher ───────────────────────────────────────────────────────

// Les clés suivantes sont à la fois :
//   (a) les anciens noms historiques (`payment_receipt`, `booking_reminder`)
//       encore référencés par d'anciens call sites pas migrés et par les
//       tests manuels ;
//   (b) les nouveaux `EmailEventKey` introduits dans
//       `resend_template_aliases.ts` (décisions 4.1 / 4.2 / 4.3 — split
//       receipt par mode, split cancellation vs refund, rename J-1).
// Tous pointent vers les MÊMES builders HTML existants : le split métier
// se fait côté Resend (templates différents) tandis que le fallback HTML
// reste générique. Pas de nouvelle template HTML à écrire pour Commit 2.
const builders: Record<string, (data: Record<string, unknown>) => EmailResult> = {
  // Historiques
  booking_confirmed: (d) => bookingConfirmed(d as unknown as BookingConfirmedData),
  booking_cancelled: (d) => bookingCancelled(d as unknown as BookingCancelledData),
  payment_receipt: (d) => paymentReceipt(d as unknown as PaymentReceiptData),
  ticket_purchased: (d) => ticketPurchased(d as unknown as TicketPurchasedData),
  booking_reminder: (d) => bookingReminder(d as unknown as BookingReminderData),
  welcome: (d) => welcome(d as unknown as WelcomeData),
  review_request: (d) => reviewRequest(d as unknown as ReviewRequestData),
  pos_receipt: (d) => posReceipt(d as unknown as PosReceiptData),
  // Aliases — nouveaux EmailEventKey → builders existants (fallback HTML).
  payment_receipt_full: (d) => paymentReceipt(d as unknown as PaymentReceiptData),
  payment_receipt_deposit: (d) => paymentReceipt(d as unknown as PaymentReceiptData),
  refund_completed: (d) => bookingCancelled(d as unknown as BookingCancelledData),
  booking_reminder_j1: (d) => bookingReminder(d as unknown as BookingReminderData),
};

export function buildEmail(
  type: string,
  data: Record<string, unknown>,
): EmailResult {
  const builder = builders[type];
  if (!builder) {
    throw new Error(`Unknown email type: ${type}`);
  }
  return builder(data);
}
