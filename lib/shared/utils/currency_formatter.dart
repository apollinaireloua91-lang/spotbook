import 'package:intl/intl.dart';

/// Centralized currency formatting for Spotbook.
///
/// Spotbook pros operate in multiple currencies (CAD/USD/EUR) because Stripe
/// Connect locks payout currency to the pro's country at onboarding.
///
/// Format rule: symbol + disambiguating code when the symbol is shared across
/// currencies we support (CAD and USD both use `$`). EUR uses `€` which is
/// unambiguous.
///
/// Examples:
///   formatAmount(45, 'CAD') -> "45.00 CA$"
///   formatAmount(45, 'USD') -> "45.00 US$"
///   formatAmount(45, 'EUR') -> "45.00 €"
///   formatAmount(45, null)  -> "45.00 CA$"   (fallback to Spotbook default)
class CurrencyFormatter {
  CurrencyFormatter._();

  static const String _defaultCurrency = 'CAD';

  /// Normalizes a currency code to upper-case 3-letter form. Returns the
  /// Spotbook default if the input is null/empty/unrecognized.
  static String normalize(String? currency) {
    if (currency == null || currency.isEmpty) return _defaultCurrency;
    final upper = currency.toUpperCase();
    switch (upper) {
      case 'CAD':
      case 'USD':
      case 'EUR':
        return upper;
      default:
        return _defaultCurrency;
    }
  }

  /// Currency symbol including disambiguating prefix when needed.
  static String symbol(String? currency) {
    switch (normalize(currency)) {
      case 'USD':
        return r'US$';
      case 'EUR':
        return '€';
      case 'CAD':
      default:
        return r'CA$';
    }
  }

  /// Formats [amount] with 2 decimals and the appropriate currency token.
  ///
  /// [locale] controls the decimal/thousand separators only (e.g. `1,234.00`
  /// in en_CA vs `1 234,00` in fr_CA). The symbol/code choice comes from
  /// [currency] and is independent of locale.
  static String formatAmount(
    num amount, {
    String? currency,
    String locale = 'en_CA',
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: decimalDigits,
    );
    return '${formatter.format(amount)} ${symbol(currency)}';
  }

  /// Short form: just the symbol next to an integer count, e.g. "CA$ 45".
  /// Use when layout demands a compact label (chips, cards).
  static String formatCompact(num amount, {String? currency}) {
    return '${symbol(currency)} ${amount.toStringAsFixed(0)}';
  }

  /// Format « québécois » strict : virgule décimale, espace insécable avant
  /// le symbole, `$` seul (pas de préfixe `CA`). Exemple : `150,00 $`.
  ///
  /// À utiliser UNIQUEMENT dans les écrans destinés au marché QC/CA-FR
  /// où le contexte lève l'ambiguïté USD/CAD (ex: scanner Pro qui n'opère
  /// que dans le pays du Pro connecté). Pour les écrans multi-devises
  /// (e-receipts, rapports), garder [formatAmount] qui désambiguïse avec
  /// `CA$` / `US$`.
  ///
  /// L'espace utilisé est un NBSP ( , narrow no-break space) — c'est
  /// la norme typographique officielle du Bureau de la traduction du
  /// Canada. Un espace ordinaire casserait à la fin de ligne et isolerait
  /// le `$` sur la ligne suivante.
  static String formatCadFr(num amount, {int decimalDigits = 2}) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'fr_CA',
      decimalDigits: decimalDigits,
    );
    return '${formatter.format(amount)} \$';
  }
}
