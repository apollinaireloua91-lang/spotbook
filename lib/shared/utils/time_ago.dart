/// Formats a [DateTime] as a relative French time string.
///
/// Examples: "à l'instant", "Il y a 5min", "Il y a 2h", "Il y a 3j",
///           "Il y a 1sem", "Il y a 2 mois", "Il y a 1 an(s)"
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
  if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
  if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()}sem';
  if (diff.inDays < 365) return 'Il y a ${diff.inDays ~/ 30} mois';
  return 'Il y a ${diff.inDays ~/ 365} an(s)';
}
