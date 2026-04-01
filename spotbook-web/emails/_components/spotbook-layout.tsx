import {
  Body,
  Container,
  Head,
  Hr,
  Html,
  Link,
  Preview,
  Section,
  Text,
} from "@react-email/components";
import * as React from "react";

/** Spotbook brand colors */
export const colors = {
  fond: "#0D0D14",
  surface: "#1E1E2E",
  surfaceAlt: "#16161F",
  border: "#2A2A3A",
  blanc: "#FFFFFF",
  gris: "#9090AA",
  violet: "#6C3EF4",
  violetClair: "#8B63FF",
  rose: "#F43E8F",
  roseClair: "#FF6BAA",
  success: "#22C55E",
  error: "#FF4444",
  warning: "#FFBB33",
};

interface SpotbookLayoutProps {
  preview: string;
  children: React.ReactNode;
}

export function SpotbookLayout({ preview, children }: SpotbookLayoutProps) {
  return (
    <Html lang="fr">
      <Head />
      <Preview>{preview}</Preview>
      <Body style={body}>
        <Container style={container}>
          {/* Logo */}
          <Section style={logoSection}>
            <Text style={logo}>Spotbook</Text>
          </Section>

          {/* Content card */}
          <Section style={card}>{children}</Section>

          {/* Footer */}
          <Section style={footer}>
            <Text style={footerText}>
              &copy; 2026 Spotbook Inc. Tous droits r&eacute;serv&eacute;s.
            </Text>
            <Text style={footerLinks}>
              <Link href="https://getspotbook.app/support" style={footerLink}>
                Aide
              </Link>
              {" · "}
              <Link href="https://getspotbook.app/privacy" style={footerLink}>
                Confidentialit&eacute;
              </Link>
              {" · "}
              <Link
                href="https://getspotbook.app/unsubscribe"
                style={footerLink}
              >
                Se d&eacute;sabonner
              </Link>
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  );
}

/** Primary CTA button */
export function CtaButton({
  href,
  children,
}: {
  href: string;
  children: React.ReactNode;
}) {
  return (
    <Section style={{ textAlign: "center" as const, marginTop: "28px" }}>
      <Link href={href} style={ctaStyle}>
        {children}
      </Link>
    </Section>
  );
}

/** Info row (label: value) */
export function InfoRow({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <tr>
      <td style={infoLabel}>{label}</td>
      <td style={infoValue}>{value}</td>
    </tr>
  );
}

/** Card-style info table */
export function InfoCard({ children }: { children: React.ReactNode }) {
  return (
    <Section style={infoCardStyle}>
      <table
        role="presentation"
        width="100%"
        cellPadding={0}
        cellSpacing={0}
      >
        <tbody>{children}</tbody>
      </table>
    </Section>
  );
}

/** Format cents → "12,50 $" */
export function fmtMoney(cents: number): string {
  return `${(cents / 100).toFixed(2).replace(".", ",")} $`;
}

// ── Styles ───────────────────────────────────────────────────────────

const body: React.CSSProperties = {
  backgroundColor: colors.fond,
  fontFamily:
    "'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  margin: 0,
  padding: 0,
};

const container: React.CSSProperties = {
  maxWidth: "600px",
  margin: "0 auto",
  padding: "40px 16px",
};

const logoSection: React.CSSProperties = {
  textAlign: "center" as const,
  paddingBottom: "8px",
};

const logo: React.CSSProperties = {
  fontSize: "20px",
  fontWeight: 700,
  color: colors.blanc,
  letterSpacing: "-0.3px",
  margin: 0,
};

const card: React.CSSProperties = {
  backgroundColor: colors.surface,
  borderRadius: "16px",
  padding: "32px 40px 40px",
};

const footer: React.CSSProperties = {
  textAlign: "center" as const,
  padding: "24px 40px",
};

const footerText: React.CSSProperties = {
  fontSize: "12px",
  color: colors.gris,
  margin: "0 0 4px",
  lineHeight: "18px",
};

const footerLinks: React.CSSProperties = {
  fontSize: "12px",
  color: colors.gris,
  margin: 0,
  lineHeight: "18px",
};

const footerLink: React.CSSProperties = {
  color: colors.violetClair,
  textDecoration: "underline",
};

const ctaStyle: React.CSSProperties = {
  display: "inline-block",
  backgroundColor: colors.violet,
  color: colors.blanc,
  fontSize: "15px",
  fontWeight: 600,
  padding: "14px 32px",
  borderRadius: "12px",
  textDecoration: "none",
};

const infoCardStyle: React.CSSProperties = {
  backgroundColor: colors.surfaceAlt,
  borderRadius: "12px",
  padding: "20px",
  marginTop: "20px",
};

const infoLabel: React.CSSProperties = {
  padding: "6px 0",
  color: colors.gris,
  fontSize: "14px",
  width: "140px",
  verticalAlign: "top",
};

const infoValue: React.CSSProperties = {
  padding: "6px 0",
  color: colors.blanc,
  fontSize: "14px",
  verticalAlign: "top",
};

export const heading: React.CSSProperties = {
  margin: "0 0 8px",
  fontSize: "22px",
  fontWeight: 700,
  color: colors.blanc,
  lineHeight: "28px",
};

export const paragraph: React.CSSProperties = {
  margin: "0 0 16px",
  fontSize: "15px",
  color: colors.gris,
  lineHeight: "22px",
};

export const divider: React.CSSProperties = {
  borderTop: `1px solid ${colors.border}`,
  margin: "20px 0",
};
