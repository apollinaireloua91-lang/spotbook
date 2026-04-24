import { serve } from "@std/http/server";

/**
 * stripe-return
 *
 * Public HTTPS endpoint that Stripe redirects to after Express onboarding
 * completes (or when the link needs refreshing). We need an HTTPS URL
 * because Stripe AccountLinks refuses custom URL schemes.
 *
 * This function serves a minimal HTML page that:
 *  1. Auto-redirects to the app.spotbook:// deep link
 *  2. Falls back to a "Return to Spotbook" button if the deep link fails
 *
 * Query params:
 *   - status=success  → onboarding completed
 *   - status=refresh  → link expired, need new one
 */
serve((req) => {
  const url = new URL(req.url);
  const status = url.searchParams.get("status") ?? "success";
  const deepLink =
    status === "refresh"
      ? "app.spotbook://stripe-connect-callback?refresh=true"
      : "app.spotbook://stripe-connect-callback?success=true";

  const title =
    status === "refresh"
      ? "Connexion expirée"
      : "Connexion réussie";
  const message =
    status === "refresh"
      ? "Le lien d'onboarding a expiré. Retournez dans l'app Spotbook pour recommencer."
      : "Votre compte Stripe est configuré. Retour à Spotbook...";

  const html = `<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Spotbook — ${title}</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body {
    height: 100%;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: #000;
    color: #fff;
  }
  body {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
    text-align: center;
  }
  .container { max-width: 420px; width: 100%; }
  .logo {
    font-size: 28px;
    font-weight: 700;
    margin-bottom: 32px;
    letter-spacing: -0.5px;
  }
  .card {
    background: #121218;
    border: 1px solid #1E1E2E;
    border-radius: 20px;
    padding: 32px 24px;
  }
  .icon {
    width: 64px; height: 64px;
    border-radius: 50%;
    background: linear-gradient(135deg, #700B97, #8E05C2);
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 20px;
    font-size: 28px;
    box-shadow: 0 0 40px rgba(142, 5, 194, 0.4);
  }
  h1 {
    font-size: 20px;
    font-weight: 600;
    margin-bottom: 12px;
  }
  p {
    font-size: 15px;
    color: #A0A0B8;
    line-height: 1.5;
    margin-bottom: 24px;
  }
  .btn {
    display: inline-block;
    background: linear-gradient(135deg, #700B97, #8E05C2);
    color: #fff;
    padding: 14px 28px;
    border-radius: 14px;
    font-size: 16px;
    font-weight: 600;
    text-decoration: none;
    box-shadow: 0 0 20px rgba(142, 5, 194, 0.35);
    transition: transform 0.1s;
  }
  .btn:active { transform: scale(0.97); }
  .hint {
    font-size: 13px;
    color: #555566;
    margin-top: 20px;
  }
</style>
</head>
<body>
  <div class="container">
    <div class="logo">Spotbook</div>
    <div class="card">
      <div class="icon">${status === "refresh" ? "!" : "OK"}</div>
      <h1>${title}</h1>
      <p>${message}</p>
      <a href="${deepLink}" class="btn">Ouvrir Spotbook</a>
      <p class="hint">Si rien ne se passe, ouvrez manuellement l'app Spotbook.</p>
    </div>
  </div>
  <script>
    // Auto-redirect to deep link
    setTimeout(function() {
      window.location.href = ${JSON.stringify(deepLink)};
    }, 300);
  </script>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
});
