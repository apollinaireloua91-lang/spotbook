import { Text } from "@react-email/components";
import * as React from "react";
import {
  SpotbookLayout,
  CtaButton,
  InfoCard,
  InfoRow,
  fmtMoney,
  heading,
  paragraph,
  colors,
} from "./_components/spotbook-layout";

interface PaymentReceiptProps {
  transactionId?: string;
  date?: string;
  amount?: number;
  serviceName?: string;
  providerName?: string;
  commission?: number;
  isProReceipt?: boolean;
  bookingId?: string;
}

export default function PaymentReceipt({
  transactionId = "pi_3Q1a2b3c4d5e",
  date = "15 avril 2026",
  amount = 7500,
  serviceName = "Coupe + Brushing",
  providerName = "Studio Élégance",
  commission = 900,
  isProReceipt = false,
  bookingId = "abc-123",
}: PaymentReceiptProps) {
  return (
    <SpotbookLayout preview={`Transaction ${transactionId}`}>
      <Text style={heading}>Reçu de paiement</Text>
      <Text style={paragraph}>
        Voici le détail de votre transaction.
      </Text>

      <InfoCard>
        <InfoRow
          label="Transaction"
          value={transactionId}
        />
        <InfoRow label="Date" value={date} />
        <InfoRow label="Montant" value={fmtMoney(amount)} />
        <InfoRow label="Service" value={serviceName} />
        <InfoRow
          label={isProReceipt ? "Client" : "Prestataire"}
          value={providerName}
        />
        {isProReceipt && commission ? (
          <>
            <InfoRow
              label="Commission Spotbook"
              value={fmtMoney(commission)}
            />
            <InfoRow
              label="Votre revenu net"
              value={fmtMoney(amount - commission)}
            />
          </>
        ) : null}
      </InfoCard>

      <CtaButton href={`https://getspotbook.app/receipt/${bookingId}`}>
        Télécharger le reçu
      </CtaButton>
    </SpotbookLayout>
  );
}
