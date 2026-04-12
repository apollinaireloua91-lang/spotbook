import { Text } from "@react-email/components";
import * as React from "react";
import {
  SpotbookLayout,
  CtaButton,
  InfoCard,
  InfoRow,
  heading,
  paragraph,
} from "./_components/spotbook-layout";

interface BookingReminderProps {
  clientName?: string;
  serviceName?: string;
  providerName?: string;
  date?: string;
  time?: string;
  address?: string;
  bookingId?: string;
}

export default function BookingReminder({
  clientName = "Marie",
  serviceName = "Coupe + Brushing",
  providerName = "Studio Élégance",
  date = "Mercredi 16 avril 2026",
  time = "14:00",
  address = "123 Rue Sainte-Catherine, Montréal",
  bookingId = "abc-123",
}: BookingReminderProps) {
  return (
    <SpotbookLayout
      preview={`Votre RDV ${serviceName} est demain à ${time}`}
    >
      <Text style={heading}>Rappel : RDV demain 📅</Text>
      <Text style={paragraph}>Bonjour {clientName},</Text>
      <Text style={paragraph}>
        N'oubliez pas votre rendez-vous prévu demain !
      </Text>

      <InfoCard>
        <InfoRow label="Service" value={serviceName} />
        <InfoRow label="Prestataire" value={providerName} />
        <InfoRow label="Date" value={date} />
        <InfoRow label="Heure" value={time} />
        <InfoRow label="Adresse" value={address} />
      </InfoCard>

      <CtaButton href={`https://getspotbook.app/booking/${bookingId}`}>
        Voir les détails
      </CtaButton>
    </SpotbookLayout>
  );
}
