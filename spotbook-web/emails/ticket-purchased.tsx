import { Img, Section, Text } from "@react-email/components";
import * as React from "react";
import {
  SpotbookLayout,
  CtaButton,
  InfoCard,
  InfoRow,
  heading,
  paragraph,
  colors,
} from "./_components/spotbook-layout";

interface TicketPurchasedProps {
  clientName?: string;
  eventName?: string;
  eventDate?: string;
  venue?: string;
  qrCodeUrl?: string;
  ticketId?: string;
}

export default function TicketPurchased({
  clientName = "Marie",
  eventName = "Soirée Jazz & Soul",
  eventDate = "Samedi 19 avril 2026 — 20h00",
  venue = "Le Belmont, 4483 Boul. Saint-Laurent, Montréal",
  qrCodeUrl = "https://placehold.co/180x180/FFFFFF/000000?text=QR",
  ticketId = "tkt-456",
}: TicketPurchasedProps) {
  return (
    <SpotbookLayout preview={`Billet pour ${eventName}`}>
      <Text style={heading}>Votre billet 🎫</Text>
      <Text style={paragraph}>Bonjour {clientName},</Text>
      <Text style={paragraph}>
        Votre billet pour{" "}
        <strong style={{ color: colors.blanc }}>{eventName}</strong> est
        prêt !
      </Text>

      <InfoCard>
        <InfoRow label="Événement" value={eventName} />
        <InfoRow label="Date" value={eventDate} />
        <InfoRow label="Lieu" value={venue} />
      </InfoCard>

      {qrCodeUrl ? (
        <Section
          style={{
            textAlign: "center" as const,
            margin: "24px auto",
          }}
        >
          <div
            style={{
              display: "inline-block",
              backgroundColor: "#FFFFFF",
              borderRadius: "12px",
              padding: "16px",
            }}
          >
            <Img
              src={qrCodeUrl}
              width={180}
              height={180}
              alt="QR Code billet"
            />
          </div>
        </Section>
      ) : null}

      <Text
        style={{
          textAlign: "center" as const,
          fontSize: "12px",
          color: colors.gris,
          margin: "0 0 8px",
        }}
      >
        Présentez ce QR code à l'entrée de l'événement.
      </Text>

      <CtaButton href={`https://getspotbook.app/ticket/${ticketId}`}>
        Ouvrir dans l'app
      </CtaButton>
    </SpotbookLayout>
  );
}
