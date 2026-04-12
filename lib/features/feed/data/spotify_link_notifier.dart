import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/spotify_account_info.dart';
import 'spotify_repository.dart';

class SpotifyLinkNotifier extends AsyncNotifier<SpotifyAccountInfo> {
  @override
  Future<SpotifyAccountInfo> build() => _fetch();

  Future<SpotifyAccountInfo> _fetch() =>
      ref.read(spotifyRepositoryProvider).getAccountStatus();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncValue.data(await _fetch());
  }
}

final spotifyLinkProvider =
    AsyncNotifierProvider<SpotifyLinkNotifier, SpotifyAccountInfo>(
  SpotifyLinkNotifier.new,
);
