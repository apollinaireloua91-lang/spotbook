import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Commission rates and fees fetched from the `app_config` Supabase table.
///
/// Kept alive so a single fetch serves the entire session.
/// Screens should use `ref.watch(appConfigProvider).valueOrNull` with
/// the hardcoded fallback so the UI never blocks on config loading.
class AppConfig {
  const AppConfig({
    required this.commissionBookings,
    required this.commissionEvents,
    required this.commissionCatering,
    required this.serviceFeeClient,
  });

  final double commissionBookings;
  final double commissionEvents;
  final double commissionCatering;
  final double serviceFeeClient;

  /// Hardcoded fallbacks — must match the values in Supabase.
  static const fallback = AppConfig(
    commissionBookings: 0.18,
    commissionEvents: 0.12,
    commissionCatering: 0.18,
    serviceFeeClient: 2.50,
  );
}

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  ref.keepAlive();

  final rows = await Supabase.instance.client
      .from('app_config')
      .select('key, value');

  final map = <String, String>{};
  for (final row in rows as List) {
    final r = row as Map<String, dynamic>;
    map[r['key'] as String] = r['value']?.toString() ?? '';
  }

  return AppConfig(
    commissionBookings:
        double.tryParse(map['commission_bookings'] ?? '') ?? 0.18,
    commissionEvents:
        double.tryParse(map['commission_events'] ?? '') ?? 0.12,
    commissionCatering:
        double.tryParse(map['commission_catering'] ?? '') ?? 0.18,
    serviceFeeClient:
        double.tryParse(map['service_fee_client'] ?? '') ?? 2.50,
  );
});
