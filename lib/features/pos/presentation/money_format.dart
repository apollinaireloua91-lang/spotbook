/// CAD money formatting helpers used across the POS UI.
///
/// Input values are minor units (cents) matching the server / Stripe format.
/// Output format: `12,34 $` (French-Canadian, nbsp between number and `$`).
library;

/// Non-breaking space between the number and the currency mark.
const String _nbsp = '\u00A0';

/// Formats an integer cents amount into `"45,67 $"`.
String formatCentsToCad(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final dollars = abs ~/ 100;
  final remainder = abs % 100;
  final cents2 = remainder.toString().padLeft(2, '0');
  return '$sign${_groupThousands(dollars)},$cents2$_nbsp\$';
}

/// Formats a dollars amount (double) into `"45,67 $"`. Rounds to the nearest
/// cent first to avoid binary-float artifacts.
String formatDollarsToCad(double dollars) {
  final cents = (dollars * 100).round();
  return formatCentsToCad(cents);
}

String _groupThousands(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final buf = StringBuffer();
  final len = s.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(_nbsp);
    buf.write(s[i]);
  }
  return buf.toString();
}
