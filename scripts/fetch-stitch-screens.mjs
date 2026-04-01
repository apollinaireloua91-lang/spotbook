/**
 * Télécharge le HTML et la capture d’écran pour des écrans Stitch donnés.
 * Prérequis : STITCH_API_KEY OU (STITCH_ACCESS_TOKEN + GOOGLE_CLOUD_PROJECT) dans .env
 * Usage : node scripts/fetch-stitch-screens.mjs
 */
import { stitch } from "@google/stitch-sdk";
import { execFileSync } from "child_process";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");

function loadDotEnv() {
  const p = path.join(root, ".env");
  if (!fs.existsSync(p)) return;
  const text = fs.readFileSync(p, "utf8");
  for (const line of text.split("\n")) {
    const t = line.trim();
    if (!t || t.startsWith("#")) continue;
    const eq = t.indexOf("=");
    if (eq <= 0) continue;
    const key = t.slice(0, eq).trim();
    let val = t.slice(eq + 1).trim();
    if (
      (val.startsWith('"') && val.endsWith('"')) ||
      (val.startsWith("'") && val.endsWith("'"))
    ) {
      val = val.slice(1, -1);
    }
    if (!process.env[key]) process.env[key] = val;
  }
}

loadDotEnv();

const PROJECT_ID = "7200697151876651939";

const SCREENS = [
  // Client core — Onboarding: Discover (IDs Stitch fournis)
  {
    screenId: "79d1be436a8a43ae92f3be982eb981b1",
    dir: "client_home_feed",
    label: "Client Home (Feed)",
  },
  {
    screenId: "ae294a843d0e4e9a86004d2c3eb1de04",
    dir: "client_search",
    label: "Client Search",
  },
  {
    screenId: "695ede578a2c4b32b969bab616d97f17",
    dir: "client_bookings",
    label: "Client Bookings",
  },
  {
    screenId: "1c17621eeb5f468d91671df003e125e2",
    dir: "client_profile_with_settings",
    label: "Profil Client avec Réglages",
  },
  {
    screenId: "07551cd31a594a99af7aff7fb964080a",
    dir: "client_settings_simplified",
    label: "Paramètres Client Simplifiés",
  },
  {
    screenId: "328e83ab30804ea7943d83147973b1b2",
    dir: "booking_etape_1",
  },
  {
    screenId: "6368662e029d4e54ba392ef7310e311a",
    dir: "booking_etape_2_date",
  },
  {
    screenId: "37b724b774aa4f42a6d005b9f5a5b71f",
    dir: "booking_etape_3_horaire",
  },
  {
    screenId: "f871bb6376554f2fad9eb1e2eb4b2331",
    dir: "booking_etape_4_resume",
  },
  {
    screenId: "a6774bdec52149d3afe8c358514931f3",
    dir: "booking_etape_5_paiement",
  },
  {
    screenId: "ab6145bb60454e00aa35ef79c8945bbd",
    dir: "booking_etape_6_confirmation",
  },
  {
    screenId: "a12231493db44956a7d9ada2dcd9a677",
    dir: "event_ticket_purchase",
  },
  {
    screenId: "5f03c82929f24069af42dc92b3df440d",
    dir: "recap_commande_billet",
  },
  {
    screenId: "0319ef50c5034c49bfa2ebc12736300c",
    dir: "billet_numerique_details",
  },
  {
    screenId: "fe263f97ad984d27b9da7ee6827dfff5",
    dir: "mes_favoris_enregistrements",
  },
  {
    screenId: "f8ac582e913b498ba7aa336a29daa2e1",
    dir: "demande_remboursement",
  },
  // Pro — Onboarding: Discover (IDs fournis)
  {
    screenId: "45ea469d79c84ed4a6f8efe501c09050",
    dir: "provider_bookings",
    label: "Provider Bookings",
  },
  {
    screenId: "053ba7c98b3a4edc84cd8a65cba20d59",
    dir: "provider_profile",
    label: "Provider Profile",
  },
  {
    screenId: "7f2d797e7f25415cb0d683f59ec7f416",
    dir: "provider_search",
    label: "Provider Search",
  },
  {
    screenId: "dff0c05e7cee4bc4aa71f07e108fa786",
    dir: "provider_home_feed",
    label: "Provider Home (Feed)",
  },
  {
    screenId: "3604fe0086454293b7df7c30dcf269db",
    dir: "provider_camera",
    label: "Provider Camera",
  },
  {
    screenId: "9140781abf7c467eb068a5686ce27ed3",
    dir: "provider_qr_ticket_scanner",
    label: "Provider QR Ticket Scanner",
  },
  {
    screenId: "57097d77eaf74c86a846d4c9f76029f8",
    dir: "provider_settings_promo_codes",
    label: "Paramètres Prestataire — Codes Promo ajouté",
  },
  // Onboarding: Discover — batch demandé (IDs Stitch)
  {
    screenId: "332fe7fa22b84475a57179b710b71a5c",
    dir: "pro_my_qr_code",
    label: "Mon QR Code Pro",
  },
  {
    screenId: "27dd8285b93d4b6db364672d869773d8",
    dir: "promo_codes_management",
    label: "Gestion des Codes Promo",
  },
  {
    screenId: "eb00702c00d34522999b0c95533da71f",
    dir: "post_booking_review",
    label: "Avis post-RDV",
  },
  {
    screenId: "37bfd4acb4d7492080faa4c31a5d43dc",
    dir: "notifications_history",
    label: "Historique des Notifications",
  },
  {
    screenId: "8476c10d05e04fb79b5411201ab15118",
    dir: "stripe_connect_setup",
    label: "Configuration Stripe Connect",
  },
  {
    screenId: "ceb7e6c7087e420cbda9f3e1afa25a83",
    dir: "generated_screen",
    label: "Generated Screen",
  },
  {
    screenId: "9a1cb8b2e6974ede9611ce620de2e78d",
    dir: "report_selection",
    label: "Sélection du Report",
  },
  {
    screenId: "b4aefbc709af4fb79b0fbc09d07437fe",
    dir: "report_confirmation",
    label: "Confirmation du Report",
  },
  {
    screenId: "20dacb0275fe407f89a417d65d93a80d",
    dir: "pro_booking_report_notification",
    label: "Notification Report de RDV (Pro)",
  },
  {
    screenId: "599ed26f159342daa94b11e0eee064d2",
    dir: "payment_success_receipt_1",
    label: "Payment: Success Receipt",
  },
  {
    screenId: "ccb92a97469f4c04955499f0b1bb274c",
    dir: "payment_success_receipt_2",
    label: "Payment: Success Receipt",
  },
  // Calendrier / dispo pro — Onboarding: Discover
  {
    screenId: "9803b26e42ba4d47b79d10f807016dc2",
    dir: "dashboard_calendrier_pro",
    label: "Dashboard Calendrier Pro",
  },
  {
    screenId: "c6ee8fe3141d443c98469032f500b38c",
    dir: "configuration_horaires",
    label: "Configuration des Horaires",
  },
  {
    screenId: "d3ed59430cd541ea90968bcc84b678f7",
    dir: "gestion_absences_exceptions",
    label: "Gestion des Absences & Exceptions",
  },
];

const OUT_BASE = path.join(
  root,
  "design/stitch/stitch_onboarding_discover",
);

/** Téléchargement via curl -L (suivi des redirections, comme demandé). */
function downloadWithCurl(url, dest) {
  execFileSync(
    "curl",
    ["-fsSL", "-L", "-o", dest, url],
    { stdio: ["ignore", "pipe", "inherit"] },
  );
}

async function main() {
  if (
    !process.env.STITCH_API_KEY &&
    !(process.env.STITCH_ACCESS_TOKEN && process.env.GOOGLE_CLOUD_PROJECT)
  ) {
    console.error(
      "Manque STITCH_API_KEY ou (STITCH_ACCESS_TOKEN + GOOGLE_CLOUD_PROJECT). Voir .cursor/MCP_STITCH.md",
    );
    process.exit(1);
  }

  const onlyRaw = process.env.STITCH_FETCH_ONLY?.trim();
  const onlyDirs = onlyRaw
    ? onlyRaw.split(",").map((s) => s.trim()).filter(Boolean)
    : null;
  const screensToFetch =
    onlyDirs?.length > 0
      ? SCREENS.filter((s) => onlyDirs.includes(s.dir))
      : SCREENS;
  if (onlyDirs?.length && screensToFetch.length === 0) {
    console.error(
      "STITCH_FETCH_ONLY ne correspond à aucun dossier connu. Dossiers :",
      SCREENS.map((s) => s.dir).join(", "),
    );
    process.exit(1);
  }

  const project = stitch.project(PROJECT_ID);

  for (const entry of screensToFetch) {
    const { screenId, dir } = entry;
    const label = entry.label ?? dir;
    const outDir = path.join(OUT_BASE, dir);
    fs.mkdirSync(outDir, { recursive: true });
    console.log(`→ ${dir} (${screenId})`);
    const screen = await project.getScreen(screenId);
    const htmlUrl = await screen.getHtml();
    const imageUrl = await screen.getImage();
    if (!htmlUrl) {
      console.error("  Pas d’URL HTML");
      continue;
    }
    downloadWithCurl(htmlUrl, path.join(outDir, "code.html"));
    if (imageUrl) {
      downloadWithCurl(imageUrl, path.join(outDir, "screen.png"));
    }
    fs.writeFileSync(
      path.join(outDir, "stitch_meta.json"),
      JSON.stringify(
        {
          projectId: PROJECT_ID,
          screenId,
          title: "Onboarding: Discover",
          screenLabel: label,
          fetchedAt: new Date().toISOString(),
        },
        null,
        2,
      ),
    );
    console.log("  OK");
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
