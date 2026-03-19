export const securityHeaders = {
  "Access-Control-Allow-Origin": "https://spotbook.app",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, stripe-signature",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Strict-Transport-Security": "max-age=31536000",
  "Content-Security-Policy": "default-src 'self'",
};

export const jsonHeaders = {
  ...securityHeaders,
  "Content-Type": "application/json",
};

export const uuidRegex = /^[0-9a-f-]{36}$/i;
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function sanitizeText(input: string): string {
  return input.replace(/<[^>]*>/g, "").trim();
}

export function assertUuid(value: string, field: string): void {
  if (!uuidRegex.test(value)) {
    throw new Error(`${field} invalide (UUID attendu)`);
  }
}

export function assertAmount(amount: number, field: string): void {
  if (!Number.isFinite(amount) || amount <= 0 || amount >= 99999) {
    throw new Error(`${field} invalide (doit être > 0 et < 99999)`);
  }
}

export function assertEmail(email: string, field = "email"): void {
  if (!emailRegex.test(email)) {
    throw new Error(`${field} invalide`);
  }
}

export function assertImageMime(mimeType: string, field = "mimeType"): void {
  if (!mimeType.startsWith("image/")) {
    throw new Error(`${field} invalide (image/* attendu)`);
  }
}

export function getClientIp(req: Request): string {
  return (
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
    req.headers.get("cf-connecting-ip") ??
    "unknown"
  );
}
