import '../../../../shared/utils/failure.dart';
import '../entities/provider_profile_data.dart';
import '../repositories/provider_profile_repository.dart';

class GetProviderProfile {
  const GetProviderProfile(this._repository);

  final ProviderProfileRepository _repository;

  Future<Result<ProviderProfileData>> call(
    String providerId, {
    bool isOwnerView = false,
  }) =>
      _repository.getProviderProfile(
        providerId,
        isOwnerView: isOwnerView,
      );
}
