import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    try {
      final rateLimit = await _supabase.functions.invoke(
        'rate-limiter',
        body: {'type': 'login'},
      );
      if (rateLimit.status == 429) {
        final err = rateLimit.data is Map<String, dynamic>
            ? rateLimit.data['error']
            : 'Trop de tentatives. Réessaie plus tard.';
        throw AuthException(err as String);
      }

      final response = await _runWithSessionRecovery(
        () => _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        ),
      );
      final uid = response.user?.id;
      if (uid != null) {
        await _supabase.from('audit_logs').insert({
          'user_id': uid,
          'action': 'user_login',
          'resource_type': 'auth',
          'metadata': {'method': 'password'},
        });
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
    final rateLimit = await _supabase.functions.invoke(
      'rate-limiter',
      body: {'type': 'otp', 'email': email},
    );
    if (rateLimit.status == 429) {
      final err = rateLimit.data is Map<String, dynamic>
          ? rateLimit.data['error']
          : 'Trop de tentatives. Réessaie plus tard.';
      throw AuthException(err as String);
    }
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    final uid = currentUserId;
    if (uid != null) {
      await _supabase.from('audit_logs').insert({
        'user_id': uid,
        'action': 'user_logout',
        'resource_type': 'auth',
      });
    }
    await _supabase.auth.signOut();
    await _secureStorage.deleteAll();
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

  Future<bool> signInWithGoogle() async {
    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.spotbook://login-callback',
    );
  }

  Future<void> softDeleteAccount() async {
    final uid = currentUserId;
    if (uid == null) throw AuthException('User not authenticated');
    await _runWithSessionRecovery(
      () => _supabase
          .from('users')
          .update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', uid),
    );
    await _supabase.from('audit_logs').insert({
      'user_id': uid,
      'action': 'user_deleted',
      'resource_type': 'user',
      'resource_id': uid,
    });
    await signOut();
  }
}
