// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Spotbook';

  @override
  String get feed => 'Feed';

  @override
  String get discover => 'Découvrir';

  @override
  String get myBookings => 'Mes RDV';

  @override
  String get profile => 'Profil';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get search => 'Recherche';

  @override
  String get camera => 'Caméra';

  @override
  String get appointments => 'Rendez-vous';

  @override
  String get events => 'Événements';

  @override
  String get settings => 'Paramètres';

  @override
  String get notifications => 'Notifications';

  @override
  String get login => 'Se connecter';

  @override
  String get register => 'S\'inscrire';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get orSeparator => 'ou';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get noAccount => 'Pas de compte ? S\'inscrire';

  @override
  String get alreadyAccount => 'Déjà un compte ? Se connecter';

  @override
  String get chooseRole => 'Choisissez votre rôle';

  @override
  String get client => 'Client';

  @override
  String get pro => 'Professionnel';

  @override
  String get book => 'Réserver';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get offline => 'Hors connexion';

  @override
  String get favorites => 'Favoris';

  @override
  String get history => 'Historique';

  @override
  String get myTickets => 'Mes Billets';

  @override
  String get consentMessage =>
      'Nous utilisons des cookies analytiques pour améliorer votre expérience.';

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get scanQr => 'Scanner QR';

  @override
  String get share => 'Partager';

  @override
  String clientProfileReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '$count avis',
    );
    return '$_temp0';
  }

  @override
  String clientProfileMemberSince(String date) {
    return 'Membre depuis $date';
  }

  @override
  String get clientProfileConnectedSocials => 'RÉSEAUX LIÉS';

  @override
  String get clientProfileCollaborationTitle => 'Contact collaboration';

  @override
  String get clientProfileCollaborationBody =>
      'Vous êtes prestataire ? Envoyez une demande pour discuter d’un partenariat ou d’une collaboration.';

  @override
  String get clientProfileSendCollaborationRequest => 'Envoyer une demande';

  @override
  String get clientProfileCollaborationOpened => 'Conversation ouverte';

  @override
  String get clientProfileTakePhoto => 'Prendre une photo';

  @override
  String get clientProfileFromGallery => 'Galerie';

  @override
  String get clientProfileEditProfile => 'Modifier le profil';

  @override
  String get clientProfilePrivateTabs =>
      'Seul vous voyez ce contenu sur votre profil.';

  @override
  String get clientProfileRemovedFavorite => 'Retiré des favoris';

  @override
  String get clientProfileBookNow => 'Réserver';

  @override
  String get clientProfileTicketValid => 'Valide';

  @override
  String get clientProfileTicketUsed => 'Utilisé';

  @override
  String get clientProfileNoFavorites => 'Aucun favori pour l’instant';

  @override
  String get clientProfileNoHistory => 'Aucun rendez-vous passé';

  @override
  String get clientProfileNoTickets => 'Aucun billet';

  @override
  String get clientProfileNotSignedIn => 'Non connecté';

  @override
  String get clientProfileCollaborationError =>
      'Impossible d’ouvrir la conversation';

  @override
  String get proSettingsTitle => 'Paramètres pro';

  @override
  String get proSettingsSavedToast => 'Enregistré';

  @override
  String get proSettingsSectionAccount => 'COMPTE';

  @override
  String get proSettingsPhone => 'Téléphone';

  @override
  String get proSettingsChangePassword => 'Changer le mot de passe';

  @override
  String get proSettingsSectionBusiness => 'ENTREPRISE';

  @override
  String get proSettingsBusinessProfile => 'Profil entreprise';

  @override
  String get proSettingsWorkAddress => 'Adresse d’activité';

  @override
  String get proSettingsSectionBookings => 'RÉSERVATIONS';

  @override
  String get proSettingsCancellationPolicy => 'Politique d’annulation';

  @override
  String get proSettingsPolicyModerate => 'Modérée';

  @override
  String get proSettingsPolicyStrict => 'Stricte';

  @override
  String get proSettingsPolicyFlexible => 'Flexible';

  @override
  String get proSettingsMinAdvance => 'Délai minimum avant réservation';

  @override
  String get proSettingsHoursShort => 'h';

  @override
  String get proSettingsMinGap => 'Intervalle minimum entre RDV';

  @override
  String get proSettingsMinutesShort => 'min';

  @override
  String get proSettingsMaxPerDay => 'RDV max par jour';

  @override
  String get proSettingsSectionPayments => 'PAIEMENTS';

  @override
  String get proSettingsPayoutHistory => 'Historique des virements';

  @override
  String get proSettingsPaymentsInfo =>
      'Connectez Stripe pour recevoir les paiements des clients.';

  @override
  String get proSettingsSectionNotifications => 'NOTIFICATIONS';

  @override
  String get proSettingsNotifSettings => 'Paramètres des notifications';

  @override
  String get proSettingsSectionPrivacy => 'CONFIDENTIALITÉ';

  @override
  String get proSettingsProfilePublic => 'Profil public';

  @override
  String get proSettingsSearchVisible => 'Visible dans la recherche';

  @override
  String get proSettingsSectionLanguage => 'LANGUE';

  @override
  String get proSettingsLanguage => 'Langue de l’app';

  @override
  String get proSettingsLangEnglish => 'Anglais';

  @override
  String get proSettingsLangFrench => 'Français';

  @override
  String get proSettingsSectionHelp => 'AIDE';

  @override
  String get proSettingsFaq => 'FAQ';

  @override
  String get proSettingsContactSupport => 'Contacter le support';

  @override
  String get proSettingsDangerZone => 'ZONE DANGEREUSE';

  @override
  String get proSettingsSignOut => 'Se déconnecter';

  @override
  String get proSettingsDeleteAccount => 'Supprimer mon compte';

  @override
  String get proSettingsModifyEmailTitle => 'Modifier l’email';

  @override
  String get proSettingsModifyPhoneTitle => 'Modifier le téléphone';

  @override
  String get proSettingsSignOutTitle => 'Se déconnecter ?';

  @override
  String get proSettingsSignOutConfirm => 'Se déconnecter';

  @override
  String get proSettingsStripeActive => 'Stripe actif';

  @override
  String get proSettingsBankEnding => 'Compte';

  @override
  String get proSettingsStripeVerifying => 'Vérification en cours';

  @override
  String get proSettingsStripeNotConfigured => 'Stripe non configuré';

  @override
  String get proSettingsStripeConfigure => 'Configurer Stripe Connect';

  @override
  String get proChangePasswordTitle => 'Changer le mot de passe';

  @override
  String get proCurrentPassword => 'Mot de passe actuel';

  @override
  String get proNewPassword => 'Nouveau mot de passe';

  @override
  String get proConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get proSettingsSectionSpotify => 'MUSIQUE (FEED)';

  @override
  String get proSettingsSpotifyTitle => 'Spotify';

  @override
  String get proSettingsSpotifyLinked => 'Compte Spotify connecté';

  @override
  String get proSettingsSpotifyConnect => 'Connecter Spotify';

  @override
  String get proSettingsSpotifyDisconnect => 'Déconnecter Spotify';

  @override
  String get proSettingsSpotifyHint =>
      'Lie ton compte pour voir tes titres les plus joués dans la feuille musique du feed pro.';

  @override
  String get proSettingsSpotifyMissingClientId =>
      'SPOTIFY_CLIENT_ID manquant dans .env';

  @override
  String get spotifySheetTitle => 'Ajouter de la musique';

  @override
  String get spotifySheetLinkedHint =>
      'Compte Spotify lié — top titres et recherche enrichie.';

  @override
  String get spotifySheetNotLinkedHint =>
      'Sans liaison : recherche seulement. Connecte Spotify dans Paramètres pro.';

  @override
  String get spotifySheetOpenSettings => 'Paramètres';

  @override
  String get spotifySheetSearchHint => 'Rechercher un titre ou artiste…';

  @override
  String get spotifySheetTopTracksHeader => 'Tes titres récents (Spotify)';

  @override
  String get spotifySheetNoResults => 'Aucun résultat';

  @override
  String get spotifySheetEmptyTop =>
      'Aucun top titre pour l’instant. Écoute de la musique sur Spotify puis réessaie.';

  @override
  String get spotifySheetEmptyNeedLink =>
      'Connecte Spotify dans Paramètres pro pour afficher tes top titres ici.';

  @override
  String spotifySheetTrackAdded(String name) {
    return '$name — ajouté au post';
  }

  @override
  String get settingsLanguageScreenTitle => 'Langue';

  @override
  String get settingsLanguageScreenSubtitle =>
      'Choisis la langue d’affichage de Spotbook. La préférence est enregistrée sur cet appareil (Hive).';

  @override
  String get settingsLanguageSavedSnack => 'Langue enregistrée';

  @override
  String get settingsLanguageMenuLabel => 'Langue';
}
