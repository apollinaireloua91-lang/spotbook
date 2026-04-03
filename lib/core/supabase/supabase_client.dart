import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès centralisé au client Supabase.
///
/// ```dart
/// final data = await SpotbookSupabase.client.from('users').select();
/// final uid = SpotbookSupabase.currentUserId;
/// ```
abstract final class SpotbookSupabase {
  /// Instance du client Supabase (initialisé dans main.dart).
  static SupabaseClient get client => Supabase.instance.client;

  /// ID de l'utilisateur connecté, ou `null`.
  static String? get currentUserId => client.auth.currentUser?.id;

  /// `true` si un utilisateur est authentifié.
  static bool get isAuthenticated => client.auth.currentUser != null;

  /// Rôle de l'utilisateur (`'client'` ou `'pro'`), ou `null`.
  static String? get userRole =>
      client.auth.currentUser?.userMetadata?['role'] as String?;

  /// Email de l'utilisateur connecté, ou `null`.
  static String? get userEmail => client.auth.currentUser?.email;

  /// Retourne le stream d'événements d'authentification.
  static Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;
}
