// Mappe un code pays Stripe Connect (CA/FR/US) vers la devise Stripe correspondante.
// Centralisé ici pour éviter les hardcode "cad" éparpillés dans les functions.
//
// Les 3 pays supportés sont ceux listés dans la contrainte
// `profiles_pro_country_check` (migration 20260417120000).
//
// Fallback : si le pro n'a pas encore de country (compte legacy avant
// la migration multi-devise), on retombe sur CAD — le marché historique.

const COUNTRY_TO_CURRENCY: Record<string, string> = {
  CA: "cad",
  FR: "eur",
  US: "usd",
};

export const DEFAULT_CURRENCY = "cad";

export function currencyForCountry(country: string | null | undefined): string {
  if (!country) return DEFAULT_CURRENCY;
  return COUNTRY_TO_CURRENCY[country.toUpperCase()] ?? DEFAULT_CURRENCY;
}
