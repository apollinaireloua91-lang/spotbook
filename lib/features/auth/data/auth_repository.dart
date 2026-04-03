import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String age,
    required String address,
    required String role,
    String city = '',
    double? latitude,
    double? longitude,
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
          'city': city,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
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
      final limiter = await _supabase.functions.invoke(
        'rate-limiter',
        body: {'scope': 'login', 'identifier': email.toLowerCase()},
      );
      if (limiter.status == 429) {
        final message =
            (limiter.data as Map<String, dynamic>?)?['message'] as String? ??
                'Trop de tentatives. Réessaie plus tard.';
        throw AuthException(message);
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final uid = response.user?.id;
      if (uid != null) {
        await _supabase.from('audit_logs').insert({
          'user_id': uid,
          'action': 'user_login',
          'resource_type': 'auth',
          'metadata': {'provider': 'email'},
        });
      }
      return response;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw AuthException('Invalid email or password');
      }
      if (e.message.toLowerCase().contains('token') &&
          e.message.toLowerCase().contains('expired')) {
        await _supabase.auth.refreshSession();
        throw AuthException('Session expirée. Reconnecte-toi.');
      }
      rethrow;
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    final googleSignIn = GoogleSignIn(
      clientId: iosClientId.isNotEmpty ? iosClientId : null,
      serverClientId: webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Connexion Google annulée.');
    }
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw AuthException('Impossible de récupérer le token Google.');
    }
    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    final uid = response.user?.id;
    if (uid != null) {
      await _supabase.from('audit_logs').insert({
        'user_id': uid,
        'action': 'user_login',
        'resource_type': 'auth',
        'metadata': {'provider': 'google'},
      });
    }
    return response;
  }

  Future<void> resetPassword(String email) async {
    final limiter = await _supabase.functions.invoke(
      'rate-limiter',
      body: {'scope': 'otp', 'identifier': email.toLowerCase()},
    );
    if (limiter.status == 429) {
      final message = (limiter.data as Map<String, dynamic>?)?['message']
              as String? ??
          'Trop de tentatives. Réessaie plus tard.';
      throw AuthException(message);
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
    await _supabase.removeAllChannels();
    await _supabase.auth.signOut();
    await _secureStorage.deleteAll();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      return await _supabase.from('users').select().eq('id', uid).maybeSingle();
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('token') &&
          e.message.toLowerCase().contains('expired')) {
        await refreshSession();
        return await _supabase.from('users').select().eq('id', uid).maybeSingle();
      }
      rethrow;
    }
  }

  Future<void> updateUserRole(String role) async {
    final uid = currentUserId;
    if (uid == null) throw AuthException('User not authenticated');
    await _supabase.from('users').update({'role': role}).eq('id', uid);
    await _supabase.auth.updateUser(UserAttributes(data: {'role': role}));
  }

  Future<String> uploadAvatar(Uint8List bytes) async {
    final uid = currentUserId;
    if (uid == null) throw AuthException('User not authenticated');
    final path = '$uid/avatar.jpg';
    await _supabase.storage
        .from('avatars')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
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
      await _supabase.from('users').update(updates).eq('id', uid);
    }
  }

  Future<void> softDeleteAccount() async {
    final uid = currentUserId;
    if (uid == null) throw AuthException('User not authenticated');
    await _supabase
        .from('users')
        .update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', uid);
    await _supabase.from('audit_logs').insert({
      'user_id': uid,
      'action': 'user_deleted',
      'resource_type': 'users',
      'resource_id': uid,
    });
    await signOut();
  }

  Future<Session?> refreshSession() async {
    try {
      final refreshed = await _supabase.auth.refreshSession();
      return refreshed.session;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('token') &&
          e.message.toLowerCase().contains('expired')) {
        await signOut();
      }
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Re-authenticate with current password first
    final email = currentUser?.email;
    if (email == null) throw AuthException('No email found');
    await _supabase.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateEmail(String newEmail) async {
    await _supabase.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }
}
