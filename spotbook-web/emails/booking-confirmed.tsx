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
} from "./_components/spotbook-layout";

interface BookingConfirmedProps {
  clientName?: string;
  serviceName?: string;
  providerName?: string;
  date?: string;
  time?: string;
  address?: string;
  amountPaid?: number;
  deposit?: number;
  remaining?: number;
  bookingId?: string;
}

export default function BookingConfirmed({
  clientName = "Marie",
  serviceName = "Coupe + Brushing",
  providerName = "Studio Élégance",
  date = "Mardi 15 avril 2026",
  time = "14:00",
  address = "123 Rue Sainte-Catherine, Montréal",
  amountPaid = 7500,
  deposit = 3750,
  remaining = 3750,
  bookingId = "abc-123",
}: BookingConfirmedProps) {
  return (
    <SpotbookLayout preview={`Votre RDV ${serviceName} est confirmé`}>
      <Text style={heading}>Réservation confirmée ✓</Text>
      <Text style={paragraph}>Bonjour {clientName},</Text>
      <Text style={paragraph}>
        Votre réservation est confirmée ! Voici les détails :
      </Text>

      <InfoCard>
        <InfoRow label="Service" value={serviceName} />
        <InfoRow label="Prestataire" value={providerName} />
        <InfoRow label="Date" value={date} />
        <InfoRow label="Heure" value={time} />
        <InfoRow label="Adresse" value={address} />
      </InfoCard>

      <Hr style={divider} />

      <Text
        style={{ margin: 0, fontSize: "13px", fontWeight: 600, color: "#FFFFFF" }}
      >
        Récapitulatif du paiement
      </Text>

      <InfoCard>
        <InfoRow label="Montant payé" value={fmtMoney(amountPaid)} />
        {deposit ? (
          <InfoRow label="Acompte versé" value={fmtMoney(deposit)} />
        ) : null}
        {remaining ? (
          <InfoRow label="Restant à payer" value={fmtMoney(remaining)} />
        ) : null}
      </InfoCard>

      <CtaButton href={`https://getspotbook.app/booking/${bookingId}`}>
        Voir ma réservation
      </CtaButton>
    </SpotbookLayout>
  );
}
