import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Spotbook'**
  String get appName;

  /// No description provided for @feed.
  ///
  /// In fr, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @discover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get discover;

  /// No description provided for @myBookings.
  ///
  /// In fr, this message translates to:
  /// **'Mes RDV'**
  String get myBookings;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get search;

  /// No description provided for @camera.
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
  String get camera;

  /// No description provided for @appointments.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous'**
  String get appointments;

  /// No description provided for @events.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get events;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get register;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @orSeparator.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get orSeparator;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte ? S\'inscrire'**
  String get noAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Se connecter'**
  String get alreadyAccount;

  /// No description provided for @chooseRole.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre rôle'**
  String get chooseRole;

  /// No description provided for @client.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @pro.
  ///
  /// In fr, this message translates to:
  /// **'Professionnel'**
  String get pro;

  /// No description provided for @book.
  ///
  /// In fr, this message translates to:
  /// **'Réserver'**
  String get book;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @offline.
  ///
  /// In fr, this message translates to:
  /// **'Hors connexion'**
  String get offline;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @myTickets.
  ///
  /// In fr, this message translates to:
  /// **'Mes Billets'**
  String get myTickets;

  /// No description provided for @consentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Nous utilisons des cookies analytiques pour améliorer votre expérience.'**
  String get consentMessage;

  /// No description provided for @accept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get decline;

  /// No description provided for @scanQr.
  ///
  /// In fr, this message translates to:
  /// **'Scanner QR'**
  String get scanQr;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @proSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get proSettingsTitle;

  /// No description provided for @proSettingsSavedToast.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get proSettingsSavedToast;

  /// No description provided for @proSettingsSectionAccount.
  ///
  /// In fr, this message translates to:
  /// **'COMPTE'**
  String get proSettingsSectionAccount;

  /// No description provided for @proSettingsSectionBusiness.
  ///
  /// In fr, this message translates to:
  /// **'ACTIVITÉ'**
  String get proSettingsSectionBusiness;

  /// No description provided for @proSettingsSectionBookings.
  ///
  /// In fr, this message translates to:
  /// **'RÉSERVATIONS'**
  String get proSettingsSectionBookings;

  /// No description provided for @proSettingsSectionPayments.
  ///
  /// In fr, this message translates to:
  /// **'PAIEMENTS'**
  String get proSettingsSectionPayments;

  /// No description provided for @proSettingsSectionSpotify.
  ///
  /// In fr, this message translates to:
  /// **'SPOTIFY'**
  String get proSettingsSectionSpotify;

  /// No description provided for @proSettingsSectionNotifications.
  ///
  /// In fr, this message translates to:
  /// **'NOTIFICATIONS'**
  String get proSettingsSectionNotifications;

  /// No description provided for @proSettingsSectionPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'CONFIDENTIALITÉ'**
  String get proSettingsSectionPrivacy;

  /// No description provided for @proSettingsSectionLanguage.
  ///
  /// In fr, this message translates to:
  /// **'LANGUE'**
  String get proSettingsSectionLanguage;

  /// No description provided for @proSettingsSectionHelp.
  ///
  /// In fr, this message translates to:
  /// **'AIDE'**
  String get proSettingsSectionHelp;

  /// No description provided for @proSettingsPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get proSettingsPhone;

  /// No description provided for @proSettingsChangePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get proSettingsChangePassword;

  /// No description provided for @proSettingsBusinessProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil professionnel'**
  String get proSettingsBusinessProfile;

  /// No description provided for @proSettingsWorkAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de travail'**
  String get proSettingsWorkAddress;

  /// No description provided for @proSettingsCancellationPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique d\'annulation'**
  String get proSettingsCancellationPolicy;

  /// No description provided for @proSettingsPolicyFlexible.
  ///
  /// In fr, this message translates to:
  /// **'Flexible'**
  String get proSettingsPolicyFlexible;

  /// No description provided for @proSettingsPolicyModerate.
  ///
  /// In fr, this message translates to:
  /// **'Modérée'**
  String get proSettingsPolicyModerate;

  /// No description provided for @proSettingsPolicyStrict.
  ///
  /// In fr, this message translates to:
  /// **'Stricte'**
  String get proSettingsPolicyStrict;

  /// No description provided for @proSettingsMinAdvance.
  ///
  /// In fr, this message translates to:
  /// **'Réservation min. à l\'avance'**
  String get proSettingsMinAdvance;

  /// No description provided for @proSettingsHoursShort.
  ///
  /// In fr, this message translates to:
  /// **'h'**
  String get proSettingsHoursShort;

  /// No description provided for @proSettingsMinGap.
  ///
  /// In fr, this message translates to:
  /// **'Intervalle min. entre RDV'**
  String get proSettingsMinGap;

  /// No description provided for @proSettingsMinutesShort.
  ///
  /// In fr, this message translates to:
  /// **'min'**
  String get proSettingsMinutesShort;

  /// No description provided for @proSettingsMaxPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Max RDV / jour'**
  String get proSettingsMaxPerDay;

  /// No description provided for @proSettingsPayoutHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des virements'**
  String get proSettingsPayoutHistory;

  /// No description provided for @proSettingsPaymentsInfo.
  ///
  /// In fr, this message translates to:
  /// **'Les paiements sont gérés via Stripe Connect. Les virements sont effectués automatiquement.'**
  String get proSettingsPaymentsInfo;

  /// No description provided for @proSettingsStripeActive.
  ///
  /// In fr, this message translates to:
  /// **'Stripe actif'**
  String get proSettingsStripeActive;

  /// No description provided for @proSettingsBankEnding.
  ///
  /// In fr, this message translates to:
  /// **'Compte finissant par'**
  String get proSettingsBankEnding;

  /// No description provided for @proSettingsStripeVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification Stripe en cours...'**
  String get proSettingsStripeVerifying;

  /// No description provided for @proSettingsStripeNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Stripe non configuré'**
  String get proSettingsStripeNotConfigured;

  /// No description provided for @proSettingsStripeConfigure.
  ///
  /// In fr, this message translates to:
  /// **'Configurer Stripe'**
  String get proSettingsStripeConfigure;

  /// No description provided for @proSettingsSpotifyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Spotify'**
  String get proSettingsSpotifyTitle;

  /// No description provided for @proSettingsSpotifyHint.
  ///
  /// In fr, this message translates to:
  /// **'Connecte ton compte Spotify pour ajouter tes morceaux favoris à tes vidéos.'**
  String get proSettingsSpotifyHint;

  /// No description provided for @proSettingsSpotifyLinked.
  ///
  /// In fr, this message translates to:
  /// **'Compte Spotify connecté'**
  String get proSettingsSpotifyLinked;

  /// No description provided for @proSettingsSpotifyConnect.
  ///
  /// In fr, this message translates to:
  /// **'Connecter Spotify'**
  String get proSettingsSpotifyConnect;

  /// No description provided for @proSettingsSpotifyDisconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter Spotify'**
  String get proSettingsSpotifyDisconnect;

  /// No description provided for @proSettingsSpotifyMissingClientId.
  ///
  /// In fr, this message translates to:
  /// **'Configuration Spotify manquante'**
  String get proSettingsSpotifyMissingClientId;

  /// No description provided for @proSettingsNotifSettings.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les notifications'**
  String get proSettingsNotifSettings;

  /// No description provided for @proSettingsProfilePublic.
  ///
  /// In fr, this message translates to:
  /// **'Profil public'**
  String get proSettingsProfilePublic;

  /// No description provided for @proSettingsSearchVisible.
  ///
  /// In fr, this message translates to:
  /// **'Visible dans la recherche'**
  String get proSettingsSearchVisible;

  /// No description provided for @proSettingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get proSettingsLanguage;

  /// No description provided for @proSettingsLangFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get proSettingsLangFrench;

  /// No description provided for @proSettingsLangEnglish.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get proSettingsLangEnglish;

  /// No description provided for @proSettingsFaq.
  ///
  /// In fr, this message translates to:
  /// **'FAQ'**
  String get proSettingsFaq;

  /// No description provided for @proSettingsContactSupport.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get proSettingsContactSupport;

  /// No description provided for @proSettingsDangerZone.
  ///
  /// In fr, this message translates to:
  /// **'ZONE DANGER'**
  String get proSettingsDangerZone;

  /// No description provided for @proSettingsSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get proSettingsSignOut;

  /// No description provided for @proSettingsSignOutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get proSettingsSignOutTitle;

  /// No description provided for @proSettingsSignOutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get proSettingsSignOutConfirm;

  /// No description provided for @proSettingsDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get proSettingsDeleteAccount;

  /// No description provided for @proSettingsModifyEmailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'email'**
  String get proSettingsModifyEmailTitle;

  /// No description provided for @proSettingsModifyPhoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le téléphone'**
  String get proSettingsModifyPhoneTitle;

  /// No description provided for @proChangePasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get proChangePasswordTitle;

  /// No description provided for @proCurrentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get proCurrentPassword;

  /// No description provided for @proNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get proNewPassword;

  /// No description provided for @proConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get proConfirmPassword;

  /// No description provided for @settingsLanguageScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguageScreenTitle;

  /// No description provided for @settingsLanguageScreenSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la langue de l\'application'**
  String get settingsLanguageScreenSubtitle;

  /// No description provided for @settingsLanguageSavedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Langue enregistrée'**
  String get settingsLanguageSavedSnack;

  /// No description provided for @spotifySheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un morceau'**
  String get spotifySheetTitle;

  /// No description provided for @spotifySheetSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un morceau...'**
  String get spotifySheetSearchHint;

  /// No description provided for @spotifySheetTopTracksHeader.
  ///
  /// In fr, this message translates to:
  /// **'Tes morceaux populaires'**
  String get spotifySheetTopTracksHeader;

  /// No description provided for @spotifySheetLinkedHint.
  ///
  /// In fr, this message translates to:
  /// **'Compte Spotify connecté'**
  String get spotifySheetLinkedHint;

  /// No description provided for @spotifySheetNotLinkedHint.
  ///
  /// In fr, this message translates to:
  /// **'Connecte Spotify dans les paramètres'**
  String get spotifySheetNotLinkedHint;

  /// No description provided for @spotifySheetNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get spotifySheetNoResults;

  /// No description provided for @spotifySheetEmptyTop.
  ///
  /// In fr, this message translates to:
  /// **'Aucun morceau populaire'**
  String get spotifySheetEmptyTop;

  /// No description provided for @spotifySheetEmptyNeedLink.
  ///
  /// In fr, this message translates to:
  /// **'Connecte ton compte Spotify'**
  String get spotifySheetEmptyNeedLink;

  /// No description provided for @spotifySheetOpenSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les paramètres'**
  String get spotifySheetOpenSettings;

  /// No description provided for @spotifySheetTrackAdded.
  ///
  /// In fr, this message translates to:
  /// **'Morceau ajouté : {track}'**
  String spotifySheetTrackAdded(String track);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
