import '../../../../shared/utils/failure.dart';
import '../entities/provider_profile_data.dart';

abstract interface class ProviderProfileRepository {
  /// Charge le profil complet d'un pro (provider + services + vidéos + events).
  /// [isOwnerView] : toutes les vidéos du compte (brouillon / modération / publiées) ;
  /// sinon uniquement les vidéos approuvées (vue client).
  Future<Result<ProviderProfileData>> getProviderProfile(
    String providerId, {
    bool isOwnerView = false,
  });

  /// Met à jour les champs éditables du pro.
  Future<Result<void>> updateProviderProfile(ProviderEntity provider);
}
