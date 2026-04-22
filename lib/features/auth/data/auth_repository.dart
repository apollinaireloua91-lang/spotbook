import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    supabase: Supabase.instance.client,
    // Keychain iOS : `first_unlock_this_device` — la clé survit aux reboots
    // une fois le device débloqué, mais n'est PAS exportée dans les backups
    // iCloud. Android : ciphers AES Keystore-backed (défaut v10+).
    secureStorage: const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
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
      await _supabase.functions.invoke(
        'rate-limiter',
        body: {'type': 'signup', 'email': email.toLowerCase()},
      );
    } on FunctionException catch (e) {
      if (e.status == 429) {
        throw AuthException('Too many attempts. Try again later.');
      }
      // Non-429 rate-limiter errors are non-critical — proceed with signup
    }

    try {
      final response = await _supabase.auth.signUp(
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
      // Le trigger DB `handle_new_auth_user` hardcode role='client' (voir
      // migration 20260413121204). Pour un Pro, il faut donc réconcilier
      // public.users.role APRÈS le signup. Sans ça :
      //   - RLS policies basées sur public.users.role refusent les mutations
      //     Pro (create event, post video, etc.)
      //   - le router qui lit userMetadata['role'] voit 'pro' mais
      //     realtime_bootstrap lit public.users.role='client' → channels
      //     subscribed pour le mauvais rôle.
      if (role != 'client' && response.user?.id != null) {
        try {
          await _supabase
              .from('users')
              .update({'role': role}).eq('id', response.user!.id);
        } catch (_) {
          // Non-critique — updateUserRole peut être retenté depuis le
          // RoleSelectionScreen / onboarding si ça rate ici.
        }
      }
      return response;
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
      try {
        await _supabase.functions.invoke(
          'rate-limiter',
          body: {'type': 'login', 'email': email.toLowerCase()},
        );
      } on FunctionException catch (e) {
        if (e.status == 429) {
          throw AuthException('Too many attempts. Try again later.');
        }
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final uid = response.user?.id;
      if (uid != null) {
        try {
          await _supabase.from('audit_logs').insert({
            'user_id': uid,
            'action': 'user_login',
            'resource_type': 'auth',
            'metadata': {'provider': 'email'},
          });
        } catch (_) {
          // Audit log is non-critical — don't block login
        }
      }
      return response;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw AuthException('Invalid email or password');
      }
      if (e.message.toLowerCase().contains('token') &&
          e.message.toLowerCase().contains('expired')) {
        await _supabase.auth.refreshSession();
        throw AuthException('Session expired. Please sign in again.');
      }
      rethrow;
    }
  }

  /// Initiates Google OAuth sign-in via browser redirect.
  /// Completes when the deep link callback sets the session.
  Future<void> signInWithGoogle() async {
    final completer = Completer<void>();

    late final StreamSubscription<AuthState> sub;
    sub = _supabase.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn && !completer.isCompleted) {
        sub.cancel();
        completer.complete();
      }
    });

    final launched = await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'app.spotbook://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!launched) {
      sub.cancel();
      throw AuthException('Could not launch Google sign-in.');
    }

    try {
      await completer.future.timeout(const Duration(minutes: 5));
    } on TimeoutException {
      sub.cancel();
      throw AuthException('Google sign-in timed out.');
    }

    final uid = currentUserId;
    if (uid != null) {
      try {
        await _supabase.from('audit_logs').insert({
          'user_id': uid,
          'action': 'user_login',
          'resource_type': 'auth',
          'metadata': {'provider': 'google'},
        });
      } catch (_) {
        // Audit log is non-critical — don't block login
      }
    }
  }

  /// Initiates native Apple Sign In on iOS.
  ///
  /// Uses nonce-based ID token flow: Apple signs the SHA256(nonce), Supabase
  /// verifies the signature against Apple's public keys and that the nonce in
  /// the JWT matches the raw nonce we sent. This bypasses the OAuth web
  /// redirect (no Service ID / Return URL config needed — just the iOS bundle
  /// ID added as "Services ID" in Supabase Dashboard → Auth → Apple).
  ///
  /// Apple returns `givenName` + `familyName` + `email` ONLY on the first
  /// login. We persist `full_name` to user metadata and `users` table on that
  /// first login since it can't be retrieved later.
  ///
  /// Throws `AuthException('cancelled_by_user')` if the user cancels the
  /// Apple dialog — caller should treat this as a silent cancellation (no
  /// error toast needed, just a discreet SnackBar).
  Future<void> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException('cancelled_by_user');
      }
      throw AuthException('Apple sign-in failed: ${e.message}');
    }

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw AuthException('Apple sign-in: no identity token returned.');
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // Persist the full name on FIRST login only (Apple never resends it).
    final fullName = _composeFullName(
      credential.givenName,
      credential.familyName,
    );
    if (fullName != null && fullName.isNotEmpty) {
      try {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'full_name': fullName}),
        );
        final uid = currentUserId;
        if (uid != null) {
          await _supabase
              .from('users')
              .update({'full_name': fullName})
              .eq('id', uid);
        }
      } catch (_) {
        // Non-critical — user can edit name from profile screen later.
      }
    }

    final uid = currentUserId;
    if (uid != null) {
      try {
        await _supabase.from('audit_logs').insert({
          'user_id': uid,
          'action': 'user_login',
          'resource_type': 'auth',
          'metadata': {'provider': 'apple'},
        });
      } catch (_) {
        // Audit log is non-critical — don't block login
      }
    }
  }

  /// Cryptographically secure random nonce for Apple Sign In.
  /// Must be ≥ 32 chars of URL-safe charset (Apple requirement).
  String _generateNonce([int length = 32]) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String? _composeFullName(String? given, String? family) {
    final parts = [given, family]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.functions.invoke(
        'rate-limiter',
        body: {'type': 'otp', 'email': email.toLowerCase()},
      );
    } on FunctionException catch (e) {
      if (e.status == 429) {
        throw AuthException('Too many attempts. Try again later.');
      }
    }
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'app.spotbook://reset-callback',
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
      } catch (_) {
        // Audit log is non-critical — don't block logout
      }

      // Purger le fcm_token côté DB AVANT de perdre le droit d'écriture via
      // RLS. Sans ça, le device continuerait à recevoir les pushes destinées
      // à l'ex-user jusqu'à ce que le prochain user se logge sur CE device.
      try {
        await _supabase
            .from('users')
            .update({'fcm_token': null})
            .eq('id', uid);
      } catch (_) {
        // Non-critique — le token sera rotaté côté device juste après.
      }
    }

    // Rotation du token FCM côté device : le cached token devient invalide
    // sur APNs/FCM. Le prochain login re-généra un token propre.
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Non-critique — continue le logout.
    }

    await _supabase.removeAllChannels();
    // `SignOutScope.global` révoque le refresh token côté Supabase, ce qui
    // invalide les sessions sur les autres devices du même user. Défaut
    // (`local`) ne touche que le client local, les autres devices
    // continuent à pouvoir refresh.
    await _supabase.auth.signOut(scope: SignOutScope.global);
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

  /// Self-heal : garantit qu'une row existe dans `public.users` pour l'user
  /// auth courant. Idempotent.
  ///
  /// POURQUOI — Le trigger DB `on_auth_user_created` (AFTER INSERT ON
  /// auth.users) CRÉE la row public.users au signup. Mais il peut échouer
  /// silencieusement (raw_user_meta_data mal formé, INSERT rompu par un
  /// check constraint, ou user créé AVANT install du trigger). Symptôme
  /// observé en prod sur iPhone physique :
  ///
  ///   PostgrestException: insert or update on table "events" violates
  ///   foreign key constraint "events_pro_id_fkey" — Key is not present
  ///   in table "users"
  ///
  /// → L'user peut se loguer (session JWT valide), mais toute insertion
  /// avec FK vers public.users échoue (events, bookings, videos, etc.).
  ///
  /// FIX — UPSERT avec `ignoreDuplicates: true` : no-op si la row existe
  /// déjà, INSERT minimal sinon. Autorisé par la RLS policy
  /// `users_own_insert` (auth.uid() = id). Best-effort : un échec ne doit
  /// pas bloquer le boot — l'user pourra se réauth.
  Future<void> ensurePublicUserRow() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final metadata = user.userMetadata ?? const <String, dynamic>{};
      await _supabase.from('users').upsert(
        {
          'id': user.id,
          'email': user.email,
          'full_name': (metadata['full_name'] ??
                  metadata['name'] ??
                  '') as String,
          // Défaut 'client' — l'user peut le modifier via RoleSelectionScreen
          // si c'est un nouveau compte sans role défini.
          'role': (metadata['role'] as String?) ?? 'client',
        },
        onConflict: 'id',
        ignoreDuplicates: true,
      );
    } catch (_) {
      // Self-heal best-effort — ne jamais bloquer le boot. Si ça échoue
      // (RLS, réseau), l'user verra les PostgrestException au moment de
      // l'action et pourra re-tenter, mais au moins on ne crash pas.
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

  /// Suppression RGPD : appelle l'Edge Function `delete-account` qui purge /
  /// anonymise toutes les données métier puis supprime l'entrée auth.users.
  ///
  /// Le nom `softDeleteAccount` est conservé pour la rétrocompat — le
  /// comportement réel est désormais une suppression RGPD complète (hard
  /// delete des PII, anonymisation des enregistrements contractuels).
  Future<void> softDeleteAccount() async {
    final uid = currentUserId;
    if (uid == null) throw AuthException('User not authenticated');

    final res = await _supabase.functions.invoke('delete-account');
    if (res.status != 200) {
      final body = res.data;
      final err = (body is Map && body['error'] is String)
          ? body['error'] as String
          : 'delete_failed';
      throw AuthException('Account deletion failed: $err');
    }
    // La session est invalidée côté Supabase (auth.users supprimé). On force
    // un signOut local pour purger les caches Flutter (Hive, secure storage).
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

  Future<void> signInWithMagicLink(String email) async {
    try {
      await _supabase.functions.invoke(
        'rate-limiter',
        body: {'type': 'otp', 'email': email.toLowerCase()},
      );
    } on FunctionException catch (e) {
      if (e.status == 429) {
        throw AuthException('Too many attempts. Try again later.');
      }
    }
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'app.spotbook://login-callback',
      shouldCreateUser: false,
    );
  }

  Future<void> resendConfirmationEmail(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
