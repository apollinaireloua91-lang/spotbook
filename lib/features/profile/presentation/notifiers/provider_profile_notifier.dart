import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/utils/failure.dart';
import '../../data/datasources/provider_profile_remote_datasource.dart';
import '../../data/repositories/provider_profile_repository_impl.dart';
import '../../domain/entities/provider_profile_data.dart';
import '../../domain/usecases/get_provider_profile.dart';

// ─── DI (Riverpod providers — remplace get_it/injectable) ─────────────────────

final _datasourceProvider = Provider<ProviderProfileRemoteDatasource>(
  (ref) => ProviderProfileRemoteDatasource(Supabase.instance.client),
);

final _repositoryProvider = Provider<ProviderProfileRepositoryImpl>(
  (ref) => ProviderProfileRepositoryImpl(ref.read(_datasourceProvider)),
);

final _useCaseProvider = Provider<GetProviderProfile>(
  (ref) => GetProviderProfile(ref.read(_repositoryProvider)),
);

/// Provider public.
/// Usage dans un écran :
/// ```dart
/// ref.read(providerProfileNotifierProvider.notifier).load(proId);
/// final s = ref.watch(providerProfileNotifierProvider);
/// ```
final providerProfileNotifierProvider =
    NotifierProvider<ProviderProfileNotifier, ProviderProfileState>(
  ProviderProfileNotifier.new,
);

// ─── State (scellée — équivalent des BlocState) ────────────────────────────────

sealed class ProviderProfileState {
  const ProviderProfileState();
}

final class ProviderProfileInitial extends ProviderProfileState {
  const ProviderProfileInitial();
}

final class ProviderProfileLoading extends ProviderProfileState {
  const ProviderProfileLoading();
}

final class ProviderProfileLoaded extends ProviderProfileState {
  const ProviderProfileLoaded(this.data);
  final ProviderProfileData data;
}

final class ProviderProfileError extends ProviderProfileState {
  const ProviderProfileError(this.failure);
  final Failure failure;
}

// ─── Notifier (équivalent Bloc) ───────────────────────────────────────────────

class ProviderProfileNotifier extends Notifier<ProviderProfileState> {
  @override
  ProviderProfileState build() => const ProviderProfileInitial();

  /// Équivalent de `bloc.add(LoadProviderProfile(id))`.
  Future<void> load(String providerId, {bool isOwnerView = false}) async {
    state = const ProviderProfileLoading();

    final result =
        await ref.read(_useCaseProvider)(providerId, isOwnerView: isOwnerView);

    state = switch (result) {
      Ok(:final value) => ProviderProfileLoaded(value),
      Err(:final failure) => ProviderProfileError(failure),
    };
  }

  /// Optimistic update — rollback si la persistance échoue.
  Future<void> updateProfile(ProviderEntity updated) async {
    final prev = state;
    if (prev is! ProviderProfileLoaded) return;

    state = ProviderProfileLoaded(prev.data.copyWith(provider: updated));

    final result =
        await ref.read(_repositoryProvider).updateProviderProfile(updated);

    if (result is Err) state = prev;
  }

  /// Persiste un lien social et met à jour l'état local.
  Future<void> saveSocialLink({
    required String platform,
    required String url,
  }) async {
    final prev = state;
    if (prev is! ProviderProfileLoaded) return;

    final proId = prev.data.provider.id;

    // Optimistic : marquer comme lié dans l'état local.
    final updatedLinks = prev.data.provider.socialLinks.map((link) {
      if (link.platform == platform) {
        return ProviderSocialLink(
          platform: platform,
          handle: link.handle,
          url: url,
          isLinked: true,
        );
      }
      return link;
    }).toList();

    // Si la plateforme n'existait pas encore dans les liens, l'ajouter.
    if (!updatedLinks.any((l) => l.platform == platform)) {
      updatedLinks.add(ProviderSocialLink(
        platform: platform,
        handle: platform,
        url: url,
        isLinked: true,
      ));
    }

    state = ProviderProfileLoaded(
      prev.data.copyWith(
        provider: prev.data.provider.copyWith(socialLinks: updatedLinks),
      ),
    );

    final result = await ref.read(_repositoryProvider).upsertSocialLink(
          proId: proId,
          platform: platform,
          url: url,
        );

    if (result is Err) state = prev;
  }
}
