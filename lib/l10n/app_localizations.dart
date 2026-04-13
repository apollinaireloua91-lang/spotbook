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
  /// In en, this message translates to:
  /// **'Spotbook'**
  String get appName;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get register;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orSeparator;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get noAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyAccount;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get chooseRole;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get pro;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTickets;

  /// No description provided for @consentMessage.
  ///
  /// In en, this message translates to:
  /// **'We use analytics cookies to improve your experience.'**
  String get consentMessage;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @proSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get proSettingsTitle;

  /// No description provided for @proSettingsSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get proSettingsSavedToast;

  /// No description provided for @proSettingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get proSettingsSectionAccount;

  /// No description provided for @proSettingsSectionBusiness.
  ///
  /// In en, this message translates to:
  /// **'BUSINESS'**
  String get proSettingsSectionBusiness;

  /// No description provided for @proSettingsSectionBookings.
  ///
  /// In en, this message translates to:
  /// **'BOOKINGS'**
  String get proSettingsSectionBookings;

  /// No description provided for @proSettingsSectionPayments.
  ///
  /// In en, this message translates to:
  /// **'PAYMENTS'**
  String get proSettingsSectionPayments;

  /// No description provided for @proSettingsSectionSpotify.
  ///
  /// In en, this message translates to:
  /// **'SPOTIFY'**
  String get proSettingsSectionSpotify;

  /// No description provided for @proSettingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get proSettingsSectionNotifications;

  /// No description provided for @proSettingsSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get proSettingsSectionPrivacy;

  /// No description provided for @proSettingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get proSettingsSectionLanguage;

  /// No description provided for @proSettingsSectionHelp.
  ///
  /// In en, this message translates to:
  /// **'HELP'**
  String get proSettingsSectionHelp;

  /// No description provided for @proSettingsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get proSettingsPhone;

  /// No description provided for @proSettingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get proSettingsChangePassword;

  /// No description provided for @proSettingsBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business profile'**
  String get proSettingsBusinessProfile;

  /// No description provided for @proSettingsWorkAddress.
  ///
  /// In en, this message translates to:
  /// **'Work address'**
  String get proSettingsWorkAddress;

  /// No description provided for @proSettingsCancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get proSettingsCancellationPolicy;

  /// No description provided for @proSettingsPolicyFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get proSettingsPolicyFlexible;

  /// No description provided for @proSettingsPolicyModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get proSettingsPolicyModerate;

  /// No description provided for @proSettingsPolicyStrict.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get proSettingsPolicyStrict;

  /// No description provided for @proSettingsMinAdvance.
  ///
  /// In en, this message translates to:
  /// **'Min. advance booking'**
  String get proSettingsMinAdvance;

  /// No description provided for @proSettingsHoursShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get proSettingsHoursShort;

  /// No description provided for @proSettingsMinGap.
  ///
  /// In en, this message translates to:
  /// **'Min. gap between bookings'**
  String get proSettingsMinGap;

  /// No description provided for @proSettingsMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get proSettingsMinutesShort;

  /// No description provided for @proSettingsMaxPerDay.
  ///
  /// In en, this message translates to:
  /// **'Max bookings / day'**
  String get proSettingsMaxPerDay;

  /// No description provided for @proSettingsPayoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Payout history'**
  String get proSettingsPayoutHistory;

  /// No description provided for @proSettingsPaymentsInfo.
  ///
  /// In en, this message translates to:
  /// **'Payments are managed via Stripe Connect. Payouts are made automatically.'**
  String get proSettingsPaymentsInfo;

  /// No description provided for @proSettingsStripeActive.
  ///
  /// In en, this message translates to:
  /// **'Stripe active'**
  String get proSettingsStripeActive;

  /// No description provided for @proSettingsBankEnding.
  ///
  /// In en, this message translates to:
  /// **'Account ending in'**
  String get proSettingsBankEnding;

  /// No description provided for @proSettingsStripeVerifying.
  ///
  /// In en, this message translates to:
  /// **'Stripe verification in progress...'**
  String get proSettingsStripeVerifying;

  /// No description provided for @proSettingsStripeNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Stripe not configured'**
  String get proSettingsStripeNotConfigured;

  /// No description provided for @proSettingsStripeConfigure.
  ///
  /// In en, this message translates to:
  /// **'Configure Stripe'**
  String get proSettingsStripeConfigure;

  /// No description provided for @proSettingsSpotifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Spotify'**
  String get proSettingsSpotifyTitle;

  /// No description provided for @proSettingsSpotifyHint.
  ///
  /// In en, this message translates to:
  /// **'Connect your Spotify account to add your favorite tracks to your videos.'**
  String get proSettingsSpotifyHint;

  /// No description provided for @proSettingsSpotifyLinked.
  ///
  /// In en, this message translates to:
  /// **'Spotify account connected'**
  String get proSettingsSpotifyLinked;

  /// No description provided for @proSettingsSpotifyConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Spotify'**
  String get proSettingsSpotifyConnect;

  /// No description provided for @proSettingsSpotifyDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Spotify'**
  String get proSettingsSpotifyDisconnect;

  /// No description provided for @proSettingsSpotifyMissingClientId.
  ///
  /// In en, this message translates to:
  /// **'Spotify configuration missing'**
  String get proSettingsSpotifyMissingClientId;

  /// No description provided for @proSettingsNotifSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage notifications'**
  String get proSettingsNotifSettings;

  /// No description provided for @proSettingsProfilePublic.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get proSettingsProfilePublic;

  /// No description provided for @proSettingsSearchVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible in search'**
  String get proSettingsSearchVisible;

  /// No description provided for @proSettingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get proSettingsLanguage;

  /// No description provided for @proSettingsLangFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get proSettingsLangFrench;

  /// No description provided for @proSettingsLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get proSettingsLangEnglish;

  /// No description provided for @proSettingsFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get proSettingsFaq;

  /// No description provided for @proSettingsContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get proSettingsContactSupport;

  /// No description provided for @proSettingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get proSettingsDangerZone;

  /// No description provided for @proSettingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get proSettingsSignOut;

  /// No description provided for @proSettingsSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get proSettingsSignOutTitle;

  /// No description provided for @proSettingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get proSettingsSignOutConfirm;

  /// No description provided for @proSettingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get proSettingsDeleteAccount;

  /// No description provided for @proSettingsModifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get proSettingsModifyEmailTitle;

  /// No description provided for @proSettingsModifyPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Change phone'**
  String get proSettingsModifyPhoneTitle;

  /// No description provided for @proChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get proChangePasswordTitle;

  /// No description provided for @proCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get proCurrentPassword;

  /// No description provided for @proNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get proNewPassword;

  /// No description provided for @proConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get proConfirmPassword;

  /// No description provided for @settingsLanguageScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageScreenTitle;

  /// No description provided for @settingsLanguageScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get settingsLanguageScreenSubtitle;

  /// No description provided for @settingsLanguageSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Language saved'**
  String get settingsLanguageSavedSnack;

  /// No description provided for @spotifySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a track'**
  String get spotifySheetTitle;

  /// No description provided for @spotifySheetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a track...'**
  String get spotifySheetSearchHint;

  /// No description provided for @spotifySheetTopTracksHeader.
  ///
  /// In en, this message translates to:
  /// **'Your top tracks'**
  String get spotifySheetTopTracksHeader;

  /// No description provided for @spotifySheetLinkedHint.
  ///
  /// In en, this message translates to:
  /// **'Spotify account linked'**
  String get spotifySheetLinkedHint;

  /// No description provided for @spotifySheetNotLinkedHint.
  ///
  /// In en, this message translates to:
  /// **'Connect Spotify in settings'**
  String get spotifySheetNotLinkedHint;

  /// No description provided for @spotifySheetNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get spotifySheetNoResults;

  /// No description provided for @spotifySheetEmptyTop.
  ///
  /// In en, this message translates to:
  /// **'No top tracks'**
  String get spotifySheetEmptyTop;

  /// No description provided for @spotifySheetEmptyNeedLink.
  ///
  /// In en, this message translates to:
  /// **'Connect your Spotify account'**
  String get spotifySheetEmptyNeedLink;

  /// No description provided for @spotifySheetOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get spotifySheetOpenSettings;

  /// No description provided for @spotifySheetTrackAdded.
  ///
  /// In en, this message translates to:
  /// **'Track added: {track}'**
  String spotifySheetTrackAdded(String track);

  /// No description provided for @a11yBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get a11yBack;

  /// No description provided for @buttonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get buttonContinue;

  /// No description provided for @buttonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get buttonNext;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @fieldFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fieldFullNameHint;

  /// No description provided for @fieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get fieldUsername;

  /// No description provided for @fieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get fieldAddress;

  /// No description provided for @fieldAddressHint.
  ///
  /// In en, this message translates to:
  /// **'123 Main St, City'**
  String get fieldAddressHint;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get fieldConfirmPassword;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Spotbook'**
  String get authWelcomeTitle;

  /// No description provided for @authSelectAccountType.
  ///
  /// In en, this message translates to:
  /// **'Select your account type'**
  String get authSelectAccountType;

  /// No description provided for @authRoleClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get authRoleClient;

  /// No description provided for @authRoleClientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find & book services'**
  String get authRoleClientSubtitle;

  /// No description provided for @authRoleClientDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover professionals, book appointments, and attend events near you.'**
  String get authRoleClientDescription;

  /// No description provided for @authRolePro.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get authRolePro;

  /// No description provided for @authRoleProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grow your business'**
  String get authRoleProSubtitle;

  /// No description provided for @authRoleProDescription.
  ///
  /// In en, this message translates to:
  /// **'Showcase your work, manage bookings, and reach new clients.'**
  String get authRoleProDescription;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get authEmailHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueApple;

  /// No description provided for @authAppleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign In coming soon'**
  String get authAppleComingSoon;

  /// No description provided for @authNoAccountPrefix.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get authNoAccountPrefix;

  /// No description provided for @authErrorEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get authErrorEmptyFields;

  /// No description provided for @authErrorEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authErrorEnterEmail;

  /// No description provided for @authMagicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Magic link sent! Check your email.'**
  String get authMagicLinkSent;

  /// No description provided for @authMagicLinkSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get authMagicLinkSending;

  /// No description provided for @authMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Send magic link'**
  String get authMagicLink;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPassword;

  /// No description provided for @authRememberPassword.
  ///
  /// In en, this message translates to:
  /// **'Remember your password? Log in'**
  String get authRememberPassword;

  /// No description provided for @authResetLinkResent.
  ///
  /// In en, this message translates to:
  /// **'Reset link resent'**
  String get authResetLinkResent;

  /// No description provided for @authEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Email sent!'**
  String get authEmailSent;

  /// No description provided for @authCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox for the reset link.'**
  String get authCheckInbox;

  /// No description provided for @authCheckSpam.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to check your spam folder.'**
  String get authCheckSpam;

  /// No description provided for @authResending.
  ///
  /// In en, this message translates to:
  /// **'Resending...'**
  String get authResending;

  /// No description provided for @authResendLink.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get authResendLink;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get authBackToLogin;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get authPasswordUpdated;

  /// No description provided for @authNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordTitle;

  /// No description provided for @authNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password below.'**
  String get authNewPasswordSubtitle;

  /// No description provided for @authNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordHint;

  /// No description provided for @authMinPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authMinPassword;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authUpdatePassword;

  /// No description provided for @authPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get authPasswordsDontMatch;

  /// No description provided for @authMinSixChars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get authMinSixChars;

  /// No description provided for @authSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authSignInWithGoogle;

  /// No description provided for @authCreateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccountTitle;

  /// No description provided for @authJoinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the Spotbook community'**
  String get authJoinCommunity;

  /// No description provided for @authCreateMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get authCreateMyAccount;

  /// No description provided for @authYourInfo.
  ///
  /// In en, this message translates to:
  /// **'Your information'**
  String get authYourInfo;

  /// No description provided for @authHowKnown.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself'**
  String get authHowKnown;

  /// No description provided for @authYourProProfile.
  ///
  /// In en, this message translates to:
  /// **'Your professional profile'**
  String get authYourProProfile;

  /// No description provided for @authPresentYourself.
  ///
  /// In en, this message translates to:
  /// **'Present yourself to your future clients'**
  String get authPresentYourself;

  /// No description provided for @authWhatInterests.
  ///
  /// In en, this message translates to:
  /// **'What interests you?'**
  String get authWhatInterests;

  /// No description provided for @authSelectCategoriesForFeed.
  ///
  /// In en, this message translates to:
  /// **'Select categories to personalize your feed'**
  String get authSelectCategoriesForFeed;

  /// No description provided for @authWhatServicesOffer.
  ///
  /// In en, this message translates to:
  /// **'What services do you offer?'**
  String get authWhatServicesOffer;

  /// No description provided for @authSelectServiceCategories.
  ///
  /// In en, this message translates to:
  /// **'Select your service categories'**
  String get authSelectServiceCategories;

  /// No description provided for @authStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String authStepLabel(int current, int total);

  /// No description provided for @categoriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get categoriesLoadFailed;

  /// No description provided for @goalDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover services'**
  String get goalDiscoverTitle;

  /// No description provided for @goalDiscoverDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the best professionals near you'**
  String get goalDiscoverDesc;

  /// No description provided for @goalBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book appointments'**
  String get goalBookTitle;

  /// No description provided for @goalBookDesc.
  ///
  /// In en, this message translates to:
  /// **'Schedule services quickly and easily'**
  String get goalBookDesc;

  /// No description provided for @goalEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attend events'**
  String get goalEventsTitle;

  /// No description provided for @goalEventsDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover and buy tickets for local events'**
  String get goalEventsDesc;

  /// No description provided for @goalPricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare prices'**
  String get goalPricesTitle;

  /// No description provided for @goalPricesDesc.
  ///
  /// In en, this message translates to:
  /// **'Find the best deals for the services you need'**
  String get goalPricesDesc;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What are your goals?'**
  String get goalsTitle;

  /// No description provided for @goalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us personalize your experience'**
  String get goalsSubtitle;

  /// No description provided for @completeProfileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get completeProfileUploadFailed;

  /// No description provided for @completeProfileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get completeProfileSaveFailed;

  /// No description provided for @completeProfileAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created!'**
  String get completeProfileAccountCreated;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a photo and your name to get started.'**
  String get completeProfileSubtitle;

  /// No description provided for @completeProfileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get completeProfileBioHint;

  /// No description provided for @locationPermTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get locationPermTitle;

  /// No description provided for @locationPermSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find professionals and events near you.'**
  String get locationPermSubtitle;

  /// No description provided for @locationPermAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow location access'**
  String get locationPermAllow;

  /// No description provided for @locationPermPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your location is never shared publicly.'**
  String get locationPermPrivacy;

  /// No description provided for @proExpertiseTitle.
  ///
  /// In en, this message translates to:
  /// **'Your expertise'**
  String get proExpertiseTitle;

  /// No description provided for @proExpertiseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the categories that match your services'**
  String get proExpertiseSubtitle;

  /// No description provided for @becomeProNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get becomeProNameRequired;

  /// No description provided for @becomeProCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get becomeProCategoryRequired;

  /// No description provided for @becomeProAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get becomeProAddressRequired;

  /// No description provided for @becomeProTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a Pro'**
  String get becomeProTitle;

  /// No description provided for @becomeProStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Your business'**
  String get becomeProStep1Title;

  /// No description provided for @becomeProStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your activity'**
  String get becomeProStep1Subtitle;

  /// No description provided for @becomeProBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get becomeProBusinessName;

  /// No description provided for @becomeProBusinessHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. John\'s Barbershop'**
  String get becomeProBusinessHint;

  /// No description provided for @becomeProCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get becomeProCategoryHint;

  /// No description provided for @becomeProCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get becomeProCategoryLabel;

  /// No description provided for @becomeProPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get becomeProPhoneLabel;

  /// No description provided for @becomeProPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+1 555 000 0000'**
  String get becomeProPhoneHint;

  /// No description provided for @becomeProStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get becomeProStep2Title;

  /// No description provided for @becomeProStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you based?'**
  String get becomeProStep2Subtitle;

  /// No description provided for @becomeProAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Business address'**
  String get becomeProAddressLabel;

  /// No description provided for @becomeProAddressHint.
  ///
  /// In en, this message translates to:
  /// **'123 Main St, City'**
  String get becomeProAddressHint;

  /// No description provided for @becomeProStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get becomeProStep3Title;

  /// No description provided for @becomeProStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how your profile will look'**
  String get becomeProStep3Subtitle;

  /// No description provided for @becomeProYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get becomeProYourProfile;

  /// No description provided for @becomeProInfoBox.
  ///
  /// In en, this message translates to:
  /// **'You can edit this information anytime from your settings.'**
  String get becomeProInfoBox;

  /// No description provided for @becomeProActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate my Pro account'**
  String get becomeProActivate;

  /// No description provided for @bizConfigInProgress.
  ///
  /// In en, this message translates to:
  /// **'Setup in progress'**
  String get bizConfigInProgress;

  /// No description provided for @bizYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Your business'**
  String get bizYourBusiness;

  /// No description provided for @bizSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your professional profile'**
  String get bizSubtitle;

  /// No description provided for @bizBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get bizBusinessName;

  /// No description provided for @bizBusinessHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Studio Glow'**
  String get bizBusinessHint;

  /// No description provided for @bizCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get bizCategoryHint;

  /// No description provided for @bizCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get bizCategoryLabel;

  /// No description provided for @bizAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bizAddressLabel;

  /// No description provided for @bizAddressHint.
  ///
  /// In en, this message translates to:
  /// **'123 Main St, City'**
  String get bizAddressHint;

  /// No description provided for @stripePaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get stripePaymentsTitle;

  /// No description provided for @stripeOpenDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open Stripe Dashboard'**
  String get stripeOpenDashboard;

  /// No description provided for @stripeFinishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get stripeFinishSetup;

  /// No description provided for @stripeConnectBank.
  ///
  /// In en, this message translates to:
  /// **'Connect your bank'**
  String get stripeConnectBank;

  /// No description provided for @stripeHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get stripeHowItWorks;

  /// No description provided for @stripeStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Connect your bank'**
  String get stripeStep1Title;

  /// No description provided for @stripeStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Link your bank account securely via Stripe.'**
  String get stripeStep1Desc;

  /// No description provided for @stripeStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Receive bookings'**
  String get stripeStep2Title;

  /// No description provided for @stripeStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Clients pay when they book. Funds are held securely.'**
  String get stripeStep2Desc;

  /// No description provided for @stripeStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Get paid'**
  String get stripeStep3Title;

  /// No description provided for @stripeStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Payouts are sent automatically to your bank account.'**
  String get stripeStep3Desc;

  /// No description provided for @stripeFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get stripeFeesTitle;

  /// No description provided for @stripeFeeBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking commission'**
  String get stripeFeeBooking;

  /// No description provided for @stripeFeeBookingSub.
  ///
  /// In en, this message translates to:
  /// **'18% per booking'**
  String get stripeFeeBookingSub;

  /// No description provided for @stripeFeeEvent.
  ///
  /// In en, this message translates to:
  /// **'Event commission'**
  String get stripeFeeEvent;

  /// No description provided for @stripeFeeEventSub.
  ///
  /// In en, this message translates to:
  /// **'12% per ticket sold'**
  String get stripeFeeEventSub;

  /// No description provided for @stripeFeeService.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get stripeFeeService;

  /// No description provided for @stripeFeeServiceSub.
  ///
  /// In en, this message translates to:
  /// **'\$2.50 per booking (charged to client)'**
  String get stripeFeeServiceSub;

  /// No description provided for @stripeNoMonthlyFees.
  ///
  /// In en, this message translates to:
  /// **'No monthly fees — you only pay when you earn.'**
  String get stripeNoMonthlyFees;

  /// No description provided for @stripeSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security & Trust'**
  String get stripeSecurityTitle;

  /// No description provided for @stripeTrustSsl.
  ///
  /// In en, this message translates to:
  /// **'SSL encryption'**
  String get stripeTrustSsl;

  /// No description provided for @stripeTrustSslSub.
  ///
  /// In en, this message translates to:
  /// **'All data is encrypted end-to-end.'**
  String get stripeTrustSslSub;

  /// No description provided for @stripeTrustPowered.
  ///
  /// In en, this message translates to:
  /// **'Powered by Stripe'**
  String get stripeTrustPowered;

  /// No description provided for @stripeTrustPoweredSub.
  ///
  /// In en, this message translates to:
  /// **'Trusted by millions of businesses worldwide.'**
  String get stripeTrustPoweredSub;

  /// No description provided for @stripeTrustFast.
  ///
  /// In en, this message translates to:
  /// **'Fast payouts'**
  String get stripeTrustFast;

  /// No description provided for @stripeTrustFastSub.
  ///
  /// In en, this message translates to:
  /// **'Receive your earnings within 2–7 business days.'**
  String get stripeTrustFastSub;

  /// No description provided for @stripeFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get stripeFaqTitle;

  /// No description provided for @stripeFaqWhenPaid.
  ///
  /// In en, this message translates to:
  /// **'When do I get paid?'**
  String get stripeFaqWhenPaid;

  /// No description provided for @stripeFaqWhenPaidAnswer.
  ///
  /// In en, this message translates to:
  /// **'Payouts are processed automatically 2–7 days after the service is completed.'**
  String get stripeFaqWhenPaidAnswer;

  /// No description provided for @stripeFaqCancel.
  ///
  /// In en, this message translates to:
  /// **'What if a client cancels?'**
  String get stripeFaqCancel;

  /// No description provided for @stripeFaqCancelAnswer.
  ///
  /// In en, this message translates to:
  /// **'Refund policies depend on your cancellation settings (flexible, moderate, or strict).'**
  String get stripeFaqCancelAnswer;

  /// No description provided for @stripeFaqDeposit.
  ///
  /// In en, this message translates to:
  /// **'How do deposits work?'**
  String get stripeFaqDeposit;

  /// No description provided for @stripeFaqDepositAnswer.
  ///
  /// In en, this message translates to:
  /// **'You can require a deposit (10–30%) when clients book. The rest is collected later.'**
  String get stripeFaqDepositAnswer;

  /// No description provided for @stripeNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help? Contact support'**
  String get stripeNeedHelp;

  /// No description provided for @stripeHeroActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments active'**
  String get stripeHeroActiveTitle;

  /// No description provided for @stripeHeroActiveSub.
  ///
  /// In en, this message translates to:
  /// **'Your account is fully set up and ready to receive payments.'**
  String get stripeHeroActiveSub;

  /// No description provided for @stripeHeroPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get stripeHeroPendingTitle;

  /// No description provided for @stripeHeroPendingSub.
  ///
  /// In en, this message translates to:
  /// **'Stripe is reviewing your information. This usually takes 1–2 days.'**
  String get stripeHeroPendingSub;

  /// No description provided for @stripeHeroConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up payments'**
  String get stripeHeroConnectTitle;

  /// No description provided for @stripeHeroConnectSub.
  ///
  /// In en, this message translates to:
  /// **'Connect your bank account to start receiving payments from clients.'**
  String get stripeHeroConnectSub;

  /// No description provided for @stripeSetupProgress.
  ///
  /// In en, this message translates to:
  /// **'Setup progress'**
  String get stripeSetupProgress;

  /// No description provided for @stripeDetailsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Details submitted'**
  String get stripeDetailsSubmitted;

  /// No description provided for @stripeDetailsSubmittedSub.
  ///
  /// In en, this message translates to:
  /// **'Your business information has been submitted.'**
  String get stripeDetailsSubmittedSub;

  /// No description provided for @stripeChargesEnabled.
  ///
  /// In en, this message translates to:
  /// **'Charges enabled'**
  String get stripeChargesEnabled;

  /// No description provided for @stripeChargesEnabledSub.
  ///
  /// In en, this message translates to:
  /// **'You can accept payments from clients.'**
  String get stripeChargesEnabledSub;

  /// No description provided for @stripePayoutsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Payouts enabled'**
  String get stripePayoutsEnabled;

  /// No description provided for @stripePayoutsEnabledSub.
  ///
  /// In en, this message translates to:
  /// **'Funds will be transferred to your bank account.'**
  String get stripePayoutsEnabledSub;

  /// No description provided for @verificationUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload document'**
  String get verificationUploadFailed;

  /// No description provided for @verificationIdRequired.
  ///
  /// In en, this message translates to:
  /// **'ID document is required'**
  String get verificationIdRequired;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get stepOf;

  /// No description provided for @helpComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Help coming soon'**
  String get helpComingSoon;

  /// No description provided for @proSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro setup'**
  String get proSetupTitle;

  /// No description provided for @verificationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get verificationInProgress;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action required'**
  String get actionRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'+1 555 000 0000'**
  String get phoneNumberHint;

  /// No description provided for @verificationSmsHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to this number.'**
  String get verificationSmsHint;

  /// No description provided for @smsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'SMS verification coming soon'**
  String get smsComingSoon;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @idRequired.
  ///
  /// In en, this message translates to:
  /// **'ID required'**
  String get idRequired;

  /// No description provided for @idUploadDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload a valid government-issued ID for verification.'**
  String get idUploadDescription;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get tapToUpload;

  /// No description provided for @uploadFormats.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF (max 10 MB)'**
  String get uploadFormats;

  /// No description provided for @idSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Your ID is securely stored and only used for verification.'**
  String get idSecurityNote;

  /// No description provided for @submitDocuments.
  ///
  /// In en, this message translates to:
  /// **'Submit documents'**
  String get submitDocuments;

  /// No description provided for @bookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get bookAgain;

  /// No description provided for @filterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterLabel;

  /// No description provided for @tabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tabUpcoming;

  /// No description provided for @tabPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tabPast;

  /// No description provided for @tabTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get tabTickets;

  /// No description provided for @noUpcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'No upcoming bookings'**
  String get noUpcomingBookings;

  /// No description provided for @noUpcomingBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book a service to see\nyour appointments here'**
  String get noUpcomingBookingsSubtitle;

  /// No description provided for @discoverPros.
  ///
  /// In en, this message translates to:
  /// **'Discover pros'**
  String get discoverPros;

  /// No description provided for @noPastBookings.
  ///
  /// In en, this message translates to:
  /// **'No past bookings'**
  String get noPastBookings;

  /// No description provided for @noPastBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your completed appointments\nwill appear here'**
  String get noPastBookingsSubtitle;

  /// No description provided for @noTicketsYet.
  ///
  /// In en, this message translates to:
  /// **'No tickets'**
  String get noTicketsYet;

  /// No description provided for @noTicketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover events and buy\ntickets to find them here'**
  String get noTicketsSubtitle;

  /// No description provided for @browseEvents.
  ///
  /// In en, this message translates to:
  /// **'Browse events'**
  String get browseEvents;

  /// No description provided for @publishReview.
  ///
  /// In en, this message translates to:
  /// **'Publish review'**
  String get publishReview;

  /// No description provided for @shareYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Share your experience...'**
  String get shareYourExperience;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetFilters;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusLabel;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'PERIOD'**
  String get periodLabel;

  /// No description provided for @professionalLabel.
  ///
  /// In en, this message translates to:
  /// **'PROFESSIONAL'**
  String get professionalLabel;

  /// No description provided for @dateFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dateFrom;

  /// No description provided for @dateTo.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get dateTo;

  /// No description provided for @searchProHint.
  ///
  /// In en, this message translates to:
  /// **'Search a pro...'**
  String get searchProHint;

  /// No description provided for @applyTheFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyTheFilters;

  /// No description provided for @tonight.
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get tonight;

  /// No description provided for @thisWeekend.
  ///
  /// In en, this message translates to:
  /// **'This weekend'**
  String get thisWeekend;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @noEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get noEventsFound;

  /// No description provided for @sellingFast.
  ///
  /// In en, this message translates to:
  /// **'Selling fast'**
  String get sellingFast;

  /// No description provided for @soldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get soldOut;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @coverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get coverImage;

  /// No description provided for @coverImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is the first thing attendees will see'**
  String get coverImageSubtitle;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// No description provided for @eventDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name your event and tell people what it\'s about'**
  String get eventDetailsSubtitle;

  /// No description provided for @whenQuestion.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get whenQuestion;

  /// No description provided for @whenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the date and start time'**
  String get whenSubtitle;

  /// No description provided for @whereQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where?'**
  String get whereQuestion;

  /// No description provided for @whereSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let guests know the location and time details'**
  String get whereSubtitle;

  /// No description provided for @ticketsAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Tickets & Pricing'**
  String get ticketsAndPricing;

  /// No description provided for @ticketsAndPricingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Define your ticket types, pricing, and availability'**
  String get ticketsAndPricingSubtitle;

  /// No description provided for @titleAndLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and location are required'**
  String get titleAndLocationRequired;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'participants'**
  String get participants;

  /// No description provided for @noAttendees.
  ///
  /// In en, this message translates to:
  /// **'No attendees'**
  String get noAttendees;

  /// No description provided for @searchParticipantHint.
  ///
  /// In en, this message translates to:
  /// **'Search a participant...'**
  String get searchParticipantHint;

  /// No description provided for @loadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingText;

  /// No description provided for @eventLabel.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get eventLabel;

  /// No description provided for @salesProgress.
  ///
  /// In en, this message translates to:
  /// **'Sales progress'**
  String get salesProgress;

  /// No description provided for @ticketsScanned.
  ///
  /// In en, this message translates to:
  /// **'Tickets scanned'**
  String get ticketsScanned;

  /// No description provided for @ticketTypes.
  ///
  /// In en, this message translates to:
  /// **'Ticket types'**
  String get ticketTypes;

  /// No description provided for @scanTickets.
  ///
  /// In en, this message translates to:
  /// **'Scan tickets'**
  String get scanTickets;

  /// No description provided for @manageEvent.
  ///
  /// In en, this message translates to:
  /// **'Manage event'**
  String get manageEvent;

  /// No description provided for @shareTicket.
  ///
  /// In en, this message translates to:
  /// **'Share ticket'**
  String get shareTicket;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get addToCalendar;

  /// No description provided for @scanAnotherTicket.
  ///
  /// In en, this message translates to:
  /// **'Scan another ticket'**
  String get scanAnotherTicket;

  /// No description provided for @scannerQr.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get scannerQr;

  /// No description provided for @waitlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Waitlist'**
  String get waitlistTitle;

  /// No description provided for @youAreRegistered.
  ///
  /// In en, this message translates to:
  /// **'You are registered!'**
  String get youAreRegistered;

  /// No description provided for @ticketsSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Tickets sold out'**
  String get ticketsSoldOut;

  /// No description provided for @waitlistNotifyMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be notified if a ticket becomes available for \"{eventTitle}\". You will have 30 minutes to confirm.'**
  String waitlistNotifyMessage(String eventTitle);

  /// No description provided for @waitlistJoinMessage.
  ///
  /// In en, this message translates to:
  /// **'Join the waitlist to get notified if a ticket becomes available.'**
  String get waitlistJoinMessage;

  /// No description provided for @joinWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Join the waitlist'**
  String get joinWaitlist;

  /// No description provided for @ticketValidated.
  ///
  /// In en, this message translates to:
  /// **'Ticket validated!'**
  String get ticketValidated;

  /// No description provided for @alreadyScanned.
  ///
  /// In en, this message translates to:
  /// **'Already scanned'**
  String get alreadyScanned;

  /// No description provided for @alreadyScannedAt.
  ///
  /// In en, this message translates to:
  /// **'Already scanned at {time}'**
  String alreadyScannedAt(String time);

  /// No description provided for @invalidTicket.
  ///
  /// In en, this message translates to:
  /// **'Invalid ticket'**
  String get invalidTicket;

  /// No description provided for @ticketValidatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'This ticket has been scanned successfully.'**
  String get ticketValidatedSuccess;

  /// No description provided for @alreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This ticket has already been used.'**
  String get alreadyUsed;

  /// No description provided for @ticketCouldNotBeValidated.
  ///
  /// In en, this message translates to:
  /// **'This ticket could not be validated.'**
  String get ticketCouldNotBeValidated;

  /// No description provided for @backToEvents.
  ///
  /// In en, this message translates to:
  /// **'Back to events'**
  String get backToEvents;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// No description provided for @searchEventHint.
  ///
  /// In en, this message translates to:
  /// **'Search an event...'**
  String get searchEventHint;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @ticketsSoldCount.
  ///
  /// In en, this message translates to:
  /// **'{sold} / {total}'**
  String ticketsSoldCount(int sold, int total);

  /// No description provided for @ticketsSold.
  ///
  /// In en, this message translates to:
  /// **'Tickets sold'**
  String get ticketsSold;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'From \${price}'**
  String fromPrice(String price);

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// No description provided for @changeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLabel;

  /// No description provided for @tapToUploadCover.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload cover'**
  String get tapToUploadCover;

  /// No description provided for @recommendedSize.
  ///
  /// In en, this message translates to:
  /// **'Recommended: 1200 x 630px'**
  String get recommendedSize;

  /// No description provided for @eventTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get eventTitleLabel;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer Jazz Workshop'**
  String get eventTitleHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @eventDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the agenda, what attendees will learn, etc.'**
  String get eventDescriptionHint;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTimeLabel;

  /// No description provided for @venueNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue Name'**
  String get venueNameLabel;

  /// No description provided for @venueNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grand Convention Center'**
  String get venueNameHint;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @searchLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Search a location'**
  String get searchLocationHint;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @noTicketTypesYet.
  ///
  /// In en, this message translates to:
  /// **'No ticket types yet'**
  String get noTicketTypesYet;

  /// No description provided for @tapToAddFirstTicket.
  ///
  /// In en, this message translates to:
  /// **'Tap to add your first ticket tier'**
  String get tapToAddFirstTicket;

  /// No description provided for @ticketTierIndex.
  ///
  /// In en, this message translates to:
  /// **'Ticket Tier {index}'**
  String ticketTierIndex(int index);

  /// No description provided for @ticketNameLabel.
  ///
  /// In en, this message translates to:
  /// **'TICKET NAME'**
  String get ticketNameLabel;

  /// No description provided for @ticketNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. General Admission'**
  String get ticketNameHint;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get priceLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'QUANTITY'**
  String get quantityLabel;

  /// No description provided for @publishEventLabel.
  ///
  /// In en, this message translates to:
  /// **'Publish Event'**
  String get publishEventLabel;

  /// No description provided for @soldLabel.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get soldLabel;

  /// No description provided for @scannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Scanned'**
  String get scannedLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @revenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueLabel;

  /// No description provided for @spotsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} spots remaining'**
  String spotsRemaining(int count);

  /// No description provided for @publishedLabel.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get publishedLabel;

  /// No description provided for @draftLabel.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftLabel;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @pageAction.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pageAction;

  /// No description provided for @salesAction.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesAction;

  /// No description provided for @allEventsFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allEventsFilter;

  /// No description provided for @publishedEventsFilter.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get publishedEventsFilter;

  /// No description provided for @draftsEventsFilter.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get draftsEventsFilter;

  /// No description provided for @pastEventsFilter.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastEventsFilter;

  /// No description provided for @noEventsCreated.
  ///
  /// In en, this message translates to:
  /// **'No events created'**
  String get noEventsCreated;

  /// No description provided for @noEventsWithFilter.
  ///
  /// In en, this message translates to:
  /// **'No {filter} events'**
  String noEventsWithFilter(String filter);

  /// No description provided for @createFirstEventHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first event\nto start selling tickets.'**
  String get createFirstEventHint;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get noEvents;

  /// No description provided for @myEventsLabel.
  ///
  /// In en, this message translates to:
  /// **'My events'**
  String get myEventsLabel;

  /// No description provided for @scanTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a ticket'**
  String get scanTicketTitle;

  /// No description provided for @openingCamera.
  ///
  /// In en, this message translates to:
  /// **'Opening camera...'**
  String get openingCamera;

  /// No description provided for @chooseEventScanHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the event, then scan QR codes from tickets with the camera.'**
  String get chooseEventScanHint;

  /// No description provided for @dateToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Date to confirm'**
  String get dateToConfirm;

  /// No description provided for @myTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTicketsTitle;

  /// No description provided for @upcomingCount.
  ///
  /// In en, this message translates to:
  /// **'Upcoming ({count})'**
  String upcomingCount(int count);

  /// No description provided for @pastCount.
  ///
  /// In en, this message translates to:
  /// **'Past ({count})'**
  String pastCount(int count);

  /// No description provided for @noUpcomingTickets.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tickets'**
  String get noUpcomingTickets;

  /// No description provided for @upcomingTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming events will appear here.'**
  String get upcomingTicketsHint;

  /// No description provided for @noPastTickets.
  ///
  /// In en, this message translates to:
  /// **'No past tickets'**
  String get noPastTickets;

  /// No description provided for @pastTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Your past events will appear here.'**
  String get pastTicketsHint;

  /// No description provided for @statusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get statusUsed;

  /// No description provided for @statusValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get statusValid;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @scannedProgress.
  ///
  /// In en, this message translates to:
  /// **'{scanned} / {total} scanned'**
  String scannedProgress(int scanned, int total);

  /// No description provided for @invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a valid Spotbook ticket.'**
  String get invalidQrCode;

  // --- Additional abstract declarations ---

  String balanceOnSite(String amount, String currency);
  String blockUserConfirmMessage(String name);
  String commissionEstimate(String pct, String commission, String currency, String net);
  String commissionsExampleCatering(int price, String net);
  String commissionsExampleService(int price, String net);
  String commissionsExampleTicket(int price, String net);
  String commissionsSpotbookCommission(int pct);
  String confirmBalanceMessage(String amount, String currency);
  String depositAmountLabel(int pct);
  String linkPlatform(String platform);
  String noBookingsOn(String date);
  String noResultsFor(String query);
  String pasteLinkFor(String platform);
  String publicProfileTicketsLeft(int remaining);
  String publishingProgress(int percent);
  String reviewCountLabel(int count);
  String reviewsCount(int count);
  String settingsCommissionsSubtitle(int bookingPct, int eventPct, String fee);
  String ticketPriceLabel(String price);
  String videoReason(String reason);
  String videoSelectedDuration(String seconds);

  String get acceptBooking;
  String get accessDenied;
  String get activeBadge;
  String get addBioHint;
  String get addCommentHint;
  String get addNetworkTitle;
  String get addRule;
  String get addRuleFirst;
  String get addServiceAction;
  String get addTextTitle;
  String get addVideoAction;
  String get addVideoTitle;
  String get allNetworksAdded;
  String get amountPaid;
  String get analyticsLabel;
  String get applyPromo;
  String get appointmentDetails;
  String get appointmentMarkedDone;
  String get availabilityQuickAction;
  String get availabilityRulesHint;
  String get availabilitySection;
  String get availableDaysHint;
  String get avgRating;
  String get balanceMarkedPaid;
  String get balanceToCollectOnSite;
  String get balanceToPayOnSite;
  String get becomePro;
  String get becomeProManageServices;
  String get becomeProManageServicesDesc;
  String get becomeProPublishVideos;
  String get becomeProPublishVideosDesc;
  String get becomeProReceivePayments;
  String get becomeProReceivePaymentsDesc;
  String get becomeProSellTickets;
  String get becomeProSellTicketsDesc;
  String get becomeProSubtitle;
  String get bioHint;
  String get bioLabel;
  String get block;
  String get blockUserBlocked;
  String get blockUserConfirmTitle;
  String get blockUserDefault;
  String get blockedUsersEmpty;
  String get blockedUsersTitle;
  String get blockedUsersUnblock;
  String get bookingAccepted;
  String get bookingCodeLabel;
  String get bookingConfirmed;
  String get bookingConfirmedSubtitle;
  String get bookingConfirmedTitle;
  String get bookingNotFound;
  String get bookingReportDescription;
  String get bookingReportDetailsHint;
  String get bookingReportDetailsLabel;
  String get bookingReportReasonHarassment;
  String get bookingReportReasonInappropriate;
  String get bookingReportReasonNoShow;
  String get bookingReportReasonNotAsDescribed;
  String get bookingReportReasonPayment;
  String get bookingReportSentConfirmation;
  String get bookingReportTitle;
  String get bookingsLabel;
  String get bookingsWillAppearHere;
  String get buyTicketAction;
  String get calendarAndAvailability;
  String get cancelReasonHint;
  String get cancellationFactBasedOnStart;
  String get cancellationFactDisputes;
  String get cancellationFactRefundDelay;
  String get cancellationFactReschedule;
  String get cancellationHowItWorks;
  String get cancellationIfYouCancel;
  String get cancellationIfYouCancelDescription;
  String get cancellationKeyPoints;
  String get cancellationPolicyTitle;
  String get cancellationProtectDescription;
  String get cancellationProtectTitle;
  String get cancellationRuleNoShowDescription;
  String get cancellationRuleNoShowSubtitle;
  String get cancellationRuleNoShowTitle;
  String get changePhoto;
  String get choose;
  String get chooseADate;
  String get chooseAService;
  String get chooseAServiceSubtitle;
  String get chooseASlot;
  String get close;
  String get closedException;
  String get commission;
  String get commissionsCateringDeposits;
  String get commissionsCateringDesc;
  String get commissionsClientPaysFee;
  String get commissionsClientPaysService;
  String get commissionsClientServiceFee;
  String get commissionsClientTotal;
  String get commissionsDescription;
  String get commissionsDetailedExample;
  String get commissionsEventTickets;
  String get commissionsEventTicketsDesc;
  String get commissionsFixedFeeDescription;
  String get commissionsFixedFeePerBooking;
  String get commissionsPayouts;
  String get commissionsPayoutsDescription;
  String get commissionsRates;
  String get commissionsServiceBookings;
  String get commissionsServiceBookingsDesc;
  String get commissionsServicePrice;
  String get commissionsTitle;
  String get commissionsTransparentPricing;
  String get commissionsYouReceive;
  String get confirmBalanceTitle;
  String get confirmCancellation;
  String get confirmed;
  String get continueLabel;
  String get copyLinkAction;
  String get createEventAction;
  String get createProAccount;
  String get creditCard;
  String get darkMode;
  String get dashboardLoadError;
  String get deleteAccount;
  String get deleteAccountConfirmCheckbox;
  String get deleteAccountDescription;
  String get deleteAccountFailed;
  String get deleteAccountIrreversible;
  String get deleteAccountPermanently;
  String get deleteVideoConfirm;
  String get deleteVideoTitle;
  String get depositAmountCad;
  String get depositCadMinimum;
  String get depositClientPaysNow;
  String get depositDisabledDescription;
  String get depositEnabledDescription;
  String get depositExplanation;
  String get depositMinimumDescription;
  String get depositMinimumTitle;
  String get depositPaidOnline;
  String get depositPercent;
  String get depositPercentageDescription;
  String get depositPercentageTitle;
  String get depositPlusSurplace;
  String depositPreviewDescription(String price);
  String get depositPreviewTitle;
  String get depositQuickSelect;
  String get depositReceivedOnline;
  String depositRemainingOnDay(String amount);
  String get depositRequire;
  String get depositRequireOnBooking;
  String get depositSaveSettings;
  String get depositServiceFee;
  String get depositServiceTotal;
  String get depositSettingsSaved;
  String get depositSettingsTitle;
  String get depositsCollected;
  String get descriptionHint;
  String get descriptionOptional;
  String get descriptionRequired;
  String get displayNameLabel;
  String get doneCountLabel;
  String get durationLabel;
  String get editProfile;
  String get editVideoTitle;
  String get endLabel;
  String get enterCodeHint;
  String get eventsQuickAction;
  String get eventsTab;
  String get fastReplyBadge;
  String get feedDiscover;
  String get feedFollowing;
  String get filtersTool;
  String get followLabel;
  String get followMeSection;
  String get followersLabel;
  String get followingLabel;
  String get freePrice;
  String get friday;
  String get fullPayment;
  String get generateSlots;
  String get glutenFreeLabel;
  String get greetingAfternoon;
  String get greetingEvening;
  String get greetingMorning;
  String get grossRevenue;
  String get hashtagsHint;
  String get hashtagsLabel;
  String get invalidDepositAmount;
  String get invalidPrice;
  String get leaveReview;
  String get likeProsToFindHere;
  String get linkCopied;
  String get linkCopiedSnack;
  String get linkCopiedToClipboard;
  String get loadError;
  String get locationHint;
  String get locationLabel;
  String get logout;
  String get logoutConfirmMessage;
  String get logoutConfirmTitle;
  String get manageServices;
  String get markAsDone;
  String get markAsDoneMessage;
  String get markAsDoneTitle;
  String get memberBadge;
  String get menuTab;
  String get messageLabel;
  String get monday;
  String get moreOptionsAction;
  String get mostBookings;
  String get mostRecent;
  String get mostSpent;
  String get myClients;
  String get myEventsSection;
  String get myFavoritePros;
  String get myProfile;
  String get myQrCode;
  String get myServicesSection;
  String get myVideosSection;
  String get netRevenue;
  String get newBadge;
  String get newTimeSlot;
  String get nextEventHeader;
  String get nextLabel;
  String get noBookableServices;
  String get noCancel;
  String get noClients;
  String get noComments;
  String get noEventsLabel;
  String get noMenuAvailable;
  String get noProfessionalsAvailable;
  String get noRulesHint;
  String get noServicesAvailable;
  String get noServicesLabel;
  String get noSlotsForDate;
  String get noSlotsForDay;
  String get noTransactionsPeriod;
  String get noUpcomingAppointments;
  String get noVideosAvailable;
  String get noVideosYet;
  String get notConnected;
  String get notifMarketing;
  String get notifMarketingSubtitle;
  String get notifMessages;
  String get notifMessagesSubtitle;
  String get notifReminders;
  String get notifRemindersSubtitle;
  String get notifReviewRequests;
  String get notifReviewRequestsSubtitle;
  String get notifSectionAppointments;
  String get notifSectionCommunication;
  String get notifSectionEvents;
  String get notifSectionOther;
  String get notifUpdates;
  String get notifUpdatesSubtitle;
  String get notifWaitlist;
  String get notifWaitlistSubtitle;
  String get notificationsEmpty;
  String get notificationsMarkAllRead;
  String get ok;
  String get openForBooking;
  String get payButtonPrefix;
  String get payNowLabel;
  String get paymentFailed;
  String get paymentPending;
  String get paymentSubtitlePrefix;
  String get pending;
  String get perDay;
  String get periodNinetyDays;
  String get periodOneYear;
  String get periodSevenDays;
  String get periodThirtyDays;
  String get photoUploadError;
  String get priceCad;
  String get privacyPolicy;
  String get proProfileFromPrice;
  String get proProfileNoReviews;
  String get proShellCateringSubtitle;
  String get proShellGallery;
  String get proShellLanguage;
  String get proShellMyMenu;
  String get proShellMyPackages;
  String get proShellMyReviews;
  String get proShellPaymentConfig;
  String get proToolsSection;
  String get profileLoadError;
  String get profileLoadErrorMessage;
  String get profileNotFoundLabel;
  String get profileUpdated;
  String get promoApplied;
  String get promoCodeTitle;
  String get promoCodes;
  String get publishAService;
  String get publishMyService;
  String get qrShareInfo;
  String get quickActionsHeader;
  String get recentHistory;
  String get recordVideo;
  String get recordVideoSubtitle;
  String get refundErrorRetry;
  String get refundRequestTitle;
  String get remainingBalanceOnSite;
  String get remainingOnDay;
  String get report;
  String get reportBooking;
  String get reportReasonFakeProfile;
  String get reportReasonHarassment;
  String get reportReasonInappropriate;
  String get reportReasonOther;
  String get reportReasonSpam;
  String get reportSent;
  String get reportSubmitButton;
  String get reportWhyReporting;
  String get reservations;
  String get reserveLabel;
  String get retourLabel;
  String get revenue;
  String get revenueAndStats;
  String get revenueQuickAction;
  String get reviewDone;
  String get reviewFeedbackHelps;
  String get reviewHowWasAppointment;
  String get reviewLeaveReview;
  String get reviewShareExperience;
  String get reviewSubmit;
  String get reviewTapToRate;
  String get reviewThankYou;
  String get reviewsEmpty;
  String get reviewsFilterAll;
  String get reviewsLabel;
  String get reviewsReceivedTitle;
  String get reviewsTab;
  String get saturday;
  String get scanTicket;
  String get searchClientHint;
  String get searchProfessionalHint;
  String get secured;
  String get selectCategoryRequired;
  String get selectVideoMax;
  String get selectedLabel;
  String get serviceFee;
  String get serviceName;
  String get serviceNameMinChars;
  String get servicesAvailableLabel;
  String get servicesQuickAction;
  String get servicesTab;
  String get settingsAvailability;
  String get settingsCancellationPolicy;
  String get settingsCancellationPolicySubtitle;
  String get settingsChangePassword;
  String get settingsCommissions;
  String get settingsConfigurePayments;
  String get settingsContactUs;
  String get settingsDepositSettings;
  String get settingsDepositSettingsSubtitle;
  String get settingsHistory;
  String get settingsLanguage;
  String get settingsManageServices;
  String get settingsMyEvents;
  String get settingsMyQrCode;
  String get settingsMyReviews;
  String get settingsPreferences;
  String get settingsQuotes;
  String get settingsQuotesSubtitle;
  String get settingsRevenueStats;
  String get settingsSectionAccount;
  String get settingsSectionBookings;
  String get settingsSectionBusiness;
  String get settingsSectionLegal;
  String get settingsSectionNotifications;
  String get settingsSectionPayments;
  String get settingsSectionPreferences;
  String get settingsSectionSupport;
  String get shareCopy;
  String get shareMessages;
  String get shareMyProfile;
  String get shareProfileTitle;
  String get signIn;
  String get signInToFollow;
  String get signInToMessage;
  String get slotDurationLabel;
  String get slotsPreviewHeader;
  String get slotsUpdated;
  String get socialLinksAutoDetectHint;
  String get socialLinksHeader;
  String get socialNetworks;
  String get soumissionsLabel;
  String get startLabel;
  String get statsLoadError;
  String get statusPending;
  String get stepConfirmed;
  String get stepDate;
  String get stepPayment;
  String get stepService;
  String get stepSummary;
  String get stepTime;
  String get subscribedLabel;
  String get subtotal;
  String get summarySubtitle;
  String get sunday;
  String get syncing;
  String get tapToChange;
  String get termsOfService;
  String get textTool;
  String get thisWeek;
  String get thursday;
  String get topProBadge;
  String get totalPeriod;
  String get totalService;
  String get transactions;
  String get tuesday;
  String get upcomingAppointmentsHint;
  String get upcomingBookingsHeader;
  String get uploadVideo;
  String get uploadVideoSubtitle;
  String get usernameInvalidChars;
  String get usernameLabel;
  String get usernameMinChars;
  String get usernameTaken;
  String get veganLabel;
  String get vegetarianLabel;
  String get verifiedBadge;
  String get videoLabel;
  String get videoPublished;
  String get videoStatusFlagged;
  String get videoStatusPublished;
  String get videoStatusRejected;
  String get videoTooLong;
  String get videoUnavailable;
  String get videosTab;
  String get viewAll;
  String get viewCalendar;
  String get wednesday;
  String get weeklyRulesHeader;
  String get withdraw;
  String get yesCancel;
  String get yourTextHint;

  // ── Additional missing keys ──
  String get titleRequired;
  String get titleHint;
  String get addLabel2;
  String get reviewRating1;
  String get reviewRating2;
  String get reviewRating3;
  String get reviewRating4;
  String get reviewRating5;
  String get cancellationRule48hTitle;
  String get cancellationRule48hSubtitle;
  String get cancellationRule48hDescription;
  String get cancellationRule24to48hTitle;
  String get cancellationRule24to48hSubtitle;
  String get cancellationRule24to48hDescription;
  String get cancellationRuleLess24hTitle;
  String get cancellationRuleLess24hSubtitle;
  String get cancellationRuleLess24hDescription;
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
