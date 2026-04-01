import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/agent_debug_log.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    supabase: Supabase.instance.client,
    secureStorage: const FlutterSecureStorage(),
  );
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateStream;
});

class AuthRepository {
  AuthRepository({
    required SupabaseClient supabase,
    required FlutterSecureStorage secureStorage,
  })  : _supabase = supabase,
        _secureStorage = secureStorage;

  final SupabaseClient _supabase;
  final FlutterSecureStorage _secureStorage;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  String? get currentUserId => currentUser?.id;
  String? get currentUserFullName =>
      currentUser?.userMetadata?['full_name'] as String?;
  String? get currentUserRole =>
      currentUser?.userMetadata?['role'] as String?;
  bool get hasActiveSession => currentSession != null;

  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;

  /// 429 → [AuthException] (trop de tentatives). Autres erreurs Edge → on continue
  /// (function indisponible / migration manquante) pour ne pas bloquer l’auth.
  Future<void> _guardRateLimiter(Map<String, dynamic> body) async {
    try {
      await _supabase.functions.invoke('rate-limiter', body: body);
    } on FunctionException catch (e) {
      if (e.status == 429) {
        throw AuthException(_rateLimiterUserMessage(e));
      }
      debugPrint(
        '[auth] rate-limiter ignoré (status=${e.status}): ${e.details}',
      );
    } catch (e) {
      // Réseau, timeout, parse, etc. — ne pas bloquer l’auth.
      debugPrint('[auth] rate-limiter ignoré (autre): $e');
    }
  }

  String _rateLimiterUserMessage(FunctionException e) {
    final d = e.details;
    if (d is Map && d['error'] != null) {
      return d['error'].toString();
    }
    return 'Trop de tentatives. Réessaie plus tard.';
  }

  Future<T> _runWithSessionRecovery<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('jwt') || message.contains('token') || message.contains('expired')) {
        final refreshed = await _supabase.auth.refreshSession();
        if (refreshed.session == null) {
          await signOut();
          throw AuthException('Session expirée. Merci de vous reconnecter.');
        }
        return await action();
      }
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String age,
    required String address,
    required String role,
  }) async {
    // #region agent log
    final parts = email.split('@');
    agentDebugLog(
      hypothesisId: 'H2',
      location: 'auth_repository.dart:signUpWithEmail',
      message: 'Entrée avant Supabase signUp',
      data: {
        'emailLen': email.length,
        'emailEmpty': email.isEmpty,
        'emailHasAt': email.contains('@'),
        'atCount': '@'.allMatches(email).length,
        'localLen': parts.length >= 2 ? parts.first.length : 0,
        'domainLen': parts.length >= 2 ? parts.last.length : 0,
        'hasWhitespace': email.contains(RegExp(r'\s')),
      },
    );
    // #endregion
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          'phone': phone,
          'age': age,
          'address': address,
        },
      );
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw AuthException('This email is already registered');
      }
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H4',
      location: 'auth_repository.dart:signInWithEmail',
      message: 'Tentative connexion (métriques email, sans PII)',
      data: {
        'emailLen': email.length,
        'emailEmpty': email.isEmpty,
        'emailHasAt': email.contains('@'),
        'passwordLen': password.length,
      },
    );
    // #endregion
    try {
      await _guardRateLimiter({'type': 'login'});

      final response = await _runWithSessionRecovery(
        () => _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        ),
      );
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H2_session',
        location: 'auth_repository.dart:signInWithEmail',
        message: 'SESSION après signInWithPassword',
        data: {
          'hasSession': response.session != null,
          'singletonMatchesRepo': identical(
            _supabase,
            Supabase.instance.client,
          ),
        },
      );
      // #endregion
      final uid = response.user?.id;
      if (uid != null) {
        try {
          await _supabase.from('audit_logs').insert({
            'user_id': uid,
            'action': 'user_login',
            'resource_type': 'auth',
            'metadata': {'method': 'password'},
          });
        } catch (e) {
          debugPrint('[auth] audit_logs login insert ignored: $e');
        }
      }
      return response;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw AuthException('Invalid email or password');
      }
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _guardRateLimiter({'type': 'otp', 'email': email});
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Met à jour l’email (flux de confirmation selon config Supabase).
  Future<void> updateEmail(String newEmail) async {
    final trimmed = newEmail.trim();
    if (trimmed.isEmpty) throw AuthException('Email requis');
    await _runWithSessionRecovery(
      () => _supabase.auth.updateUser(UserAttributes(email: trimmed)),
    );
  }

  /// Vérifie l’ancien mot de passe puis applique le nouveau.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = currentUser?.email;
    if (email == null || email.isEmpty) {
      throw AuthException('Aucun email associé au compte');
    }
    await _guardRateLimiter({'type': 'login'});
    await _runWithSessionRecovery(
      () => _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      ),
    );
    await _runWithSessionRecovery(
      () => _supabase.auth.updateUser(UserAttributes(password: newPassword)),
    );
  }

  Future<void> signOut() async {
    final uid = currentUserId;
    if (uid != null) {
      try {
        await _supabase.from('audit_logs').insert({
          'user_id': uid,
          'action': 'user_logout',
          'resource_type': 'auth',
        });
      } catch (e) {
        debugPrint('[auth] audit_logs logout insert ignored: $e');
      }
    }
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('[auth] supabase signOut ignored: $e');
    }
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('[auth] secureStorage deleteAll ignored: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return await _runWithSessionRecovery(
      () => _supabase.from('users').select().eq('id', uid).maybeSingle(),
    );
  }

  Future<void> updateUserRole(String role) async {
    final uid = currentUserId;
    if (uid == null) throw AuthException('User not authenticated');
    await _runWithSessionRecovery(
      () => _supabase.from('users').update({'role': role}).eq('id', uid),
    );
    await _runWithSessionRecovery(
      () => _supabase.auth.updateUser(UserAttributes(data: {'role': role})),
    );
  }

  Future<String> uploadAvatar(Uint8List bytes) async {
    final uid = currentUserId;
    if (uid == null) throw AuthException('User not authenticated');
    final path = '$uid/avatar.jpg';
    await _runWithSessionRecovery(
      () => _supabase.storage
          .from('avatars')
          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true)),
    );
    return _supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw AuthException('User not authenticated');
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (updates.isNotEmpty) {
      await _runWithSessionRecovery(
        () => _supabase.from('users').update(updates).eq('id', uid),
      );
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Retourne [null] si l'utilisateur a annulé le sélecteur Google.
  Future<AuthResponse?> signInWithGoogle() async {
    const webClientId =
        String.fromEnvironment('GOOGLE_CLIENT_ID');
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);
    // Le nonce (SHA-256) est passé à initialize() pour être intégré dans l'id_token.
    // On réinitialise à chaque tentative pour avoir un nonce frais.
    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId,
      nonce: hashedNonce,
    );
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw AuthException("Impossible d'obtenir le token Google.");
      }
      return _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthException(
        'Erreur Google Sign-In (${e.code.name}): ${e.description ?? "inconnue"}',
      );
    }
  }

  Future<void> softDeleteAccount() async {
    final uid = currentUserId;
    if (uid == null) throw AuthException('User not authenticated');
    await _runWithSessionRecovery(
      () => _supabase
          .from('users')
          .update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', uid),
    );
    try {
      await _supabase.from('audit_logs').insert({
        'user_id': uid,
        'action': 'user_deleted',
        'resource_type': 'user',
        'resource_id': uid,
      });
    } catch (e) {
      debugPrint('[auth] audit_logs delete insert ignored: $e');
    }
    await signOut();
  }
}
