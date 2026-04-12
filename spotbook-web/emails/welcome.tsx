import { Hr, Section, Text } from "@react-email/components";
import * as React from "react";
import {
  SpotbookLayout,
  CtaButton,
  heading,
  paragraph,
  divider,
  colors,
} from "./_components/spotbook-layout";

interface WelcomeProps {
  userName?: string;
}

const steps = [
  {
    num: "1",
    icon: "🔍",
    title: "Découvrez",
    desc: "Explorez les prestataires près de chez vous via le feed vidéo.",
  },
  {
    num: "2",
    icon: "📅",
    title: "Réservez",
    desc: "Choisissez un créneau et réservez en quelques taps.",
  },
  {
    num: "3",
    icon: "⭐",
    title: "Évaluez",
    desc: "Laissez un avis après votre rendez-vous.",
  },
];

export default function Welcome({ userName = "Marie" }: WelcomeProps) {
  return (
    <SpotbookLayout preview="Découvrez, réservez et évaluez les meilleurs prestataires">
      <Text style={heading}>Bienvenue sur Spotbook ! 🎉</Text>
      <Text style={paragraph}>Bonjour {userName},</Text>
      <Text style={paragraph}>
        Merci de nous rejoindre ! Voici comment tirer le meilleur de
        Spotbook en 3 étapes :
      </Text>

      <Hr style={divider} />

      {steps.map((step) => (
        <Section key={step.num} style={{ marginBottom: "16px" }}>
          <table
            role="presentation"
            width="100%"
            cellPadding={0}
            cellSpacing={0}
          >
            <tbody>
              <tr>
                <td width={48} style={{ verticalAlign: "top" }}>
                  <div
                    style={{
                      width: "36px",
                      height: "36px",
                      backgroundColor: colors.violet,
                      borderRadius: "50%",
                      textAlign: "center" as const,
                      lineHeight: "36px",
                      fontSize: "15px",
                      fontWeight: 700,
                      color: colors.blanc,
                    }}
                  >
                    {step.num}
                  </div>
                </td>
                <td style={{ verticalAlign: "top", paddingLeft: "12px" }}>
                  <Text
                    style={{
                      margin: 0,
                      fontSize: "15px",
                      fontWeight: 600,
                      color: colors.blanc,
                    }}
                  >
                    {step.icon} {step.title}
                  </Text>
                  <Text
                    style={{
                      margin: "4px 0 0",
                      fontSize: "14px",
                      color: colors.gris,
                      lineHeight: "20px",
                    }}
                  >
                    {step.desc}
                  </Text>
                </td>
              </tr>
            </tbody>
          </table>
        </Section>
      ))}

      <Hr style={divider} />

      <CtaButton href="https://getspotbook.app">
        Explorer l'app
      </CtaButton>
    </SpotbookLayout>
  );
}
