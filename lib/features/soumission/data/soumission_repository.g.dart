// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soumission_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(soumissionRepository)
final soumissionRepositoryProvider = SoumissionRepositoryProvider._();

final class SoumissionRepositoryProvider extends $FunctionalProvider<
    SoumissionRepository,
    SoumissionRepository,
    SoumissionRepository> with $Provider<SoumissionRepository> {
  SoumissionRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'soumissionRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$soumissionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SoumissionRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SoumissionRepository create(Ref ref) {
    return soumissionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SoumissionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SoumissionRepository>(value),
    );
  }
}

String _$soumissionRepositoryHash() =>
    r'c2263c8ce7ba8ae0a04b87c122c0db244b504d4e';

@ProviderFor(mySoumissions)
final mySoumissionsProvider = MySoumissionsProvider._();

final class MySoumissionsProvider extends $FunctionalProvider<
        AsyncValue<List<Soumission>>,
        List<Soumission>,
        FutureOr<List<Soumission>>>
    with $FutureModifier<List<Soumission>>, $FutureProvider<List<Soumission>> {
  MySoumissionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'mySoumissionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$mySoumissionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Soumission>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Soumission>> create(Ref ref) {
    return mySoumissions(ref);
  }
}

String _$mySoumissionsHash() => r'c3f107b202b4eab85c7ca700b137002775093d2b';
