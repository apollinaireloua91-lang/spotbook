import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../shared/utils/failure.dart';
import '../../domain/entities/provider_profile_data.dart';
import '../../domain/repositories/provider_profile_repository.dart';
import '../datasources/provider_profile_remote_datasource.dart';

class ProviderProfileRepositoryImpl implements ProviderProfileRepository {
  ProviderProfileRepositoryImpl(this._remote);

  final ProviderProfileRemoteDatasource _remote;

  static const String _boxName = 'provider_profiles';

  // ─── getProviderProfile ────────────────────────────────────────────────────

  String _profileCacheKey(String providerId, bool isOwnerView) =>
      '${providerId}_${isOwnerView ? 'owner' : 'pub'}';

  @override
  Future<Result<ProviderProfileData>> getProviderProfile(
    String providerId, {
    bool isOwnerView = false,
  }) async {
    final cacheKey = _profileCacheKey(providerId, isOwnerView);
    try {
      final data = await _remote.getProviderProfile(
        providerId,
        isOwnerView: isOwnerView,
      );
      await _cacheProfile(cacheKey, data);
      return Ok(data);
    } catch (e) {
      final cached = await _getCachedProfile(cacheKey);
      if (cached != null) return Ok(cached);

      return Err(ServerFailure(e.toString()));
    }
  }

  // ─── updateProviderProfile ─────────────────────────────────────────────────

  @override
  Future<Result<void>> updateProviderProfile(ProviderEntity provider) async {
    try {
      await _remote.updateProviderProfile(provider);
      await _invalidateCache(provider.id);
      return const Ok(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  // ─── upsertSocialLink ────────────────────────────────────────────────────

  Future<Result<void>> upsertSocialLink({
    required String proId,
    required String platform,
    required String url,
  }) async {
    try {
      await _remote.upsertSocialLink(
        proId: proId,
        platform: platform,
        url: url,
      );
      await _invalidateCache(proId);
      return const Ok(null);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  // ─── Cache Hive ────────────────────────────────────────────────────────────

  Future<void> _cacheProfile(
      String providerId, ProviderProfileData data) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(providerId, jsonEncode(data.toJson()));
    } catch (_) {
      // Cache non critique — on ignore les erreurs
    }
  }

  Future<ProviderProfileData?> _getCachedProfile(String providerId) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final raw = box.get(providerId);
      if (raw == null) return null;
      return ProviderProfileData.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _invalidateCache(String providerId) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.delete(_profileCacheKey(providerId, true));
      await box.delete(_profileCacheKey(providerId, false));
      await box.delete(providerId);
    } catch (_) {}
  }
}
