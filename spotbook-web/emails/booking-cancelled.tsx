import { Hr, Text } from "@react-email/components";
import * as React from "react";
import {
  SpotbookLayout,
  CtaButton,
  InfoCard,
  InfoRow,
  fmtMoney,
  heading,
  paragraph,
  divider,
  colors,
} from "./_components/spotbook-layout";

interface BookingCancelledProps {
  clientName?: string;
  serviceName?: string;
  providerName?: string;
  date?: string;
  refundAmount?: number;
  bookingId?: string;
}

export default function BookingCancelled({
  clientName = "Marie",
  serviceName = "Coupe + Brushing",
  providerName = "Studio Élégance",
  date = "Mardi 15 avril 2026",
  refundAmount = 3750,
  bookingId = "abc-123",
}: BookingCancelledProps) {
  return (
    <SpotbookLayout preview={`Votre RDV ${serviceName} a été annulé`}>
      <Text style={heading}>Réservation annulée</Text>
      <Text style={paragraph}>Bonjour {clientName},</Text>
      <Text style={paragraph}>Votre réservation a été annulée.</Text>

      <InfoCard>
        <InfoRow label="Service" value={serviceName} />
        <InfoRow label="Prestataire" value={providerName} />
        <InfoRow label="Date" value={date} />
      </InfoCard>

      {refundAmount && refundAmount > 0 ? (
        <>
          <Hr style={divider} />
          <Text style={paragraph}>
            Un remboursement de{" "}
            <strong style={{ color: colors.success }}>
              {fmtMoney(refundAmount)}
            </strong>{" "}
            sera crédité sur votre moyen de paiement sous 5 à 10 jours
            ouvrables.
          </Text>
        </>
      ) : null}

      <CtaButton href="https://getspotbook.app/search">
        Re-réserver
      </CtaButton>
    </SpotbookLayout>
  );
}
