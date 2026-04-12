import { Text } from "@react-email/components";
import * as React from "react";
import {
  SpotbookLayout,
  CtaButton,
  heading,
  paragraph,
  colors,
} from "./_components/spotbook-layout";

interface ReviewRequestProps {
  clientName?: string;
  providerName?: string;
  serviceName?: string;
  bookingId?: string;
}

export default function ReviewRequest({
  clientName = "Marie",
  providerName = "Studio Élégance",
  serviceName = "Coupe + Brushing",
  bookingId = "abc-123",
}: ReviewRequestProps) {
  return (
    <SpotbookLayout preview={`Donnez votre avis sur ${serviceName}`}>
      <Text style={heading}>Comment s'est passé votre RDV ?</Text>
      <Text style={paragraph}>Bonjour {clientName},</Text>
      <Text style={paragraph}>
        Votre rendez-vous{" "}
        <strong style={{ color: colors.blanc }}>{serviceName}</strong> avec{" "}
        <strong style={{ color: colors.blanc }}>{providerName}</strong> est
        terminé. Votre avis compte !
      </Text>

      <Text
        style={{
          margin: "24px 0",
          textAlign: "center" as const,
          fontSize: "32px",
          letterSpacing: "4px",
          color: colors.warning,
        }}
      >
        ★★★★★
      </Text>

      <Text
        style={{
          ...paragraph,
          textAlign: "center" as const,
        }}
      >
        Notez votre expérience et aidez la communauté Spotbook.
      </Text>

      <CtaButton href={`https://getspotbook.app/review/${bookingId}`}>
        Laisser un avis
      </CtaButton>
    </SpotbookLayout>
  );
}
