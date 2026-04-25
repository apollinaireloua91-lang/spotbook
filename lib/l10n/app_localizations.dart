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
  /// **'Already have an account? '**
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
  /// **'No account? '**
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

  /// No description provided for @authPasswordComplexity.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters with a letter and a digit'**
  String get authPasswordComplexity;

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
  /// **'Refund policies depend on your cancellation settings (moderate or strict).'**
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

  /// No description provided for @invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a valid Spotbook ticket.'**
  String get invalidQrCode;

  /// No description provided for @acceptBooking.
  ///
  /// In en, this message translates to:
  /// **'Accept booking'**
  String get acceptBooking;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeBadge;

  /// No description provided for @addBioHint.
  ///
  /// In en, this message translates to:
  /// **'Add a bio to introduce yourself…'**
  String get addBioHint;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get addCommentHint;

  /// No description provided for @addNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Add network'**
  String get addNetworkTitle;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get addRule;

  /// No description provided for @addRuleFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a rule first'**
  String get addRuleFirst;

  /// No description provided for @addServiceAction.
  ///
  /// In en, this message translates to:
  /// **'Add a service'**
  String get addServiceAction;

  /// No description provided for @addTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Add text'**
  String get addTextTitle;

  /// No description provided for @addVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Add a video'**
  String get addVideoAction;

  /// No description provided for @addVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addVideoTitle;

  /// No description provided for @allNetworksAdded.
  ///
  /// In en, this message translates to:
  /// **'All networks added'**
  String get allNetworksAdded;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get amountPaid;

  /// No description provided for @analyticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsLabel;

  /// No description provided for @applyPromo.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyPromo;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Appointment details'**
  String get appointmentDetails;

  /// No description provided for @appointmentMarkedDone.
  ///
  /// In en, this message translates to:
  /// **'Appointment marked as done'**
  String get appointmentMarkedDone;

  /// No description provided for @availabilityQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityQuickAction;

  /// No description provided for @availabilityRulesHint.
  ///
  /// In en, this message translates to:
  /// **'Set your weekly availability rules'**
  String get availabilityRulesHint;

  /// No description provided for @availabilitySection.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilitySection;

  /// No description provided for @availableDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Available days'**
  String get availableDaysHint;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get avgRating;

  /// No description provided for @balanceMarkedPaid.
  ///
  /// In en, this message translates to:
  /// **'Balance marked as paid'**
  String get balanceMarkedPaid;

  /// No description provided for @balanceToCollectOnSite.
  ///
  /// In en, this message translates to:
  /// **'Balance to collect on site'**
  String get balanceToCollectOnSite;

  /// No description provided for @balanceToPayOnSite.
  ///
  /// In en, this message translates to:
  /// **'Balance to pay on site'**
  String get balanceToPayOnSite;

  /// No description provided for @becomePro.
  ///
  /// In en, this message translates to:
  /// **'Become a Pro'**
  String get becomePro;

  /// No description provided for @becomeProManageServices.
  ///
  /// In en, this message translates to:
  /// **'Manage your services'**
  String get becomeProManageServices;

  /// No description provided for @becomeProManageServicesDesc.
  ///
  /// In en, this message translates to:
  /// **'Create and manage your service offerings'**
  String get becomeProManageServicesDesc;

  /// No description provided for @becomeProPublishVideos.
  ///
  /// In en, this message translates to:
  /// **'Publish videos'**
  String get becomeProPublishVideos;

  /// No description provided for @becomeProPublishVideosDesc.
  ///
  /// In en, this message translates to:
  /// **'Showcase your work with video content'**
  String get becomeProPublishVideosDesc;

  /// No description provided for @becomeProReceivePayments.
  ///
  /// In en, this message translates to:
  /// **'Receive payments'**
  String get becomeProReceivePayments;

  /// No description provided for @becomeProReceivePaymentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get paid securely via Stripe'**
  String get becomeProReceivePaymentsDesc;

  /// No description provided for @becomeProSellTickets.
  ///
  /// In en, this message translates to:
  /// **'Sell tickets'**
  String get becomeProSellTickets;

  /// No description provided for @becomeProSellTicketsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create events and sell tickets'**
  String get becomeProSellTicketsDesc;

  /// No description provided for @becomeProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock professional features'**
  String get becomeProSubtitle;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Write a short bio…'**
  String get bioHint;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @blockUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get blockUserBlocked;

  /// No description provided for @blockUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block user?'**
  String get blockUserConfirmTitle;

  /// No description provided for @blockUserDefault.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get blockUserDefault;

  /// No description provided for @blockedUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get blockedUsersEmpty;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersTitle;

  /// No description provided for @blockedUsersUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get blockedUsersUnblock;

  /// No description provided for @bookingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Booking accepted'**
  String get bookingAccepted;

  /// No description provided for @bookingCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking code'**
  String get bookingCodeLabel;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingConfirmedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your appointment is confirmed'**
  String get bookingConfirmedSubtitle;

  /// No description provided for @bookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed!'**
  String get bookingConfirmedTitle;

  /// No description provided for @bookingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Booking not found'**
  String get bookingNotFound;

  /// No description provided for @bookingReportDescription.
  ///
  /// In en, this message translates to:
  /// **'Report an issue with this booking'**
  String get bookingReportDescription;

  /// No description provided for @bookingReportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in detail…'**
  String get bookingReportDetailsHint;

  /// No description provided for @bookingReportDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get bookingReportDetailsLabel;

  /// No description provided for @bookingReportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get bookingReportReasonHarassment;

  /// No description provided for @bookingReportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate behavior'**
  String get bookingReportReasonInappropriate;

  /// No description provided for @bookingReportReasonNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get bookingReportReasonNoShow;

  /// No description provided for @bookingReportReasonNotAsDescribed.
  ///
  /// In en, this message translates to:
  /// **'Not as described'**
  String get bookingReportReasonNotAsDescribed;

  /// No description provided for @bookingReportReasonPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment issue'**
  String get bookingReportReasonPayment;

  /// No description provided for @bookingReportSentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Report sent successfully'**
  String get bookingReportSentConfirmation;

  /// No description provided for @bookingReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report booking'**
  String get bookingReportTitle;

  /// No description provided for @bookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsLabel;

  /// No description provided for @bookingsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your bookings will appear here'**
  String get bookingsWillAppearHere;

  /// No description provided for @buyTicketAction.
  ///
  /// In en, this message translates to:
  /// **'Buy ticket'**
  String get buyTicketAction;

  /// No description provided for @calendarAndAvailability.
  ///
  /// In en, this message translates to:
  /// **'Calendar & Availability'**
  String get calendarAndAvailability;

  /// No description provided for @cancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation…'**
  String get cancelReasonHint;

  /// No description provided for @cancellationFactBasedOnStart.
  ///
  /// In en, this message translates to:
  /// **'Based on the appointment start time'**
  String get cancellationFactBasedOnStart;

  /// No description provided for @cancellationFactDisputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes can be resolved via support'**
  String get cancellationFactDisputes;

  /// No description provided for @cancellationFactRefundDelay.
  ///
  /// In en, this message translates to:
  /// **'Refunds may take 5-10 business days'**
  String get cancellationFactRefundDelay;

  /// No description provided for @cancellationFactReschedule.
  ///
  /// In en, this message translates to:
  /// **'You can reschedule instead of cancelling'**
  String get cancellationFactReschedule;

  /// No description provided for @cancellationHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get cancellationHowItWorks;

  /// No description provided for @cancellationIfYouCancel.
  ///
  /// In en, this message translates to:
  /// **'If you cancel'**
  String get cancellationIfYouCancel;

  /// No description provided for @cancellationIfYouCancelDescription.
  ///
  /// In en, this message translates to:
  /// **'The refund depends on your cancellation policy'**
  String get cancellationIfYouCancelDescription;

  /// No description provided for @cancellationKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'Key points'**
  String get cancellationKeyPoints;

  /// No description provided for @cancellationPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get cancellationPolicyTitle;

  /// No description provided for @cancellationProtectDescription.
  ///
  /// In en, this message translates to:
  /// **'Protects both clients and professionals'**
  String get cancellationProtectDescription;

  /// No description provided for @cancellationProtectTitle.
  ///
  /// In en, this message translates to:
  /// **'Fair for everyone'**
  String get cancellationProtectTitle;

  /// No description provided for @cancellationRuleNoShowDescription.
  ///
  /// In en, this message translates to:
  /// **'If the client does not show up, the deposit is kept'**
  String get cancellationRuleNoShowDescription;

  /// No description provided for @cancellationRuleNoShowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit is kept by the professional'**
  String get cancellationRuleNoShowSubtitle;

  /// No description provided for @cancellationRuleNoShowTitle.
  ///
  /// In en, this message translates to:
  /// **'No-show policy'**
  String get cancellationRuleNoShowTitle;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @chooseADate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseADate;

  /// No description provided for @chooseAService.
  ///
  /// In en, this message translates to:
  /// **'Choose a service'**
  String get chooseAService;

  /// No description provided for @chooseAServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the service you want to book'**
  String get chooseAServiceSubtitle;

  /// No description provided for @chooseASlot.
  ///
  /// In en, this message translates to:
  /// **'Choose a time slot'**
  String get chooseASlot;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closedException.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedException;

  /// No description provided for @commission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commission;

  /// No description provided for @commissionsCateringDeposits.
  ///
  /// In en, this message translates to:
  /// **'Catering & Deposits'**
  String get commissionsCateringDeposits;

  /// No description provided for @commissionsCateringDesc.
  ///
  /// In en, this message translates to:
  /// **'18% commission on catering orders'**
  String get commissionsCateringDesc;

  /// No description provided for @commissionsClientPaysFee.
  ///
  /// In en, this message translates to:
  /// **'Client pays service fee'**
  String get commissionsClientPaysFee;

  /// No description provided for @commissionsClientPaysService.
  ///
  /// In en, this message translates to:
  /// **'Client pays'**
  String get commissionsClientPaysService;

  /// No description provided for @commissionsClientServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Client service fee'**
  String get commissionsClientServiceFee;

  /// No description provided for @commissionsClientTotal.
  ///
  /// In en, this message translates to:
  /// **'Client total'**
  String get commissionsClientTotal;

  /// No description provided for @commissionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Understand how Spotbook commissions work'**
  String get commissionsDescription;

  /// No description provided for @commissionsDetailedExample.
  ///
  /// In en, this message translates to:
  /// **'Detailed example'**
  String get commissionsDetailedExample;

  /// No description provided for @commissionsEventTickets.
  ///
  /// In en, this message translates to:
  /// **'Event Tickets'**
  String get commissionsEventTickets;

  /// No description provided for @commissionsEventTicketsDesc.
  ///
  /// In en, this message translates to:
  /// **'12% commission on ticket sales'**
  String get commissionsEventTicketsDesc;

  /// No description provided for @commissionsFixedFeeDescription.
  ///
  /// In en, this message translates to:
  /// **'A fixed fee is added to each booking for the client'**
  String get commissionsFixedFeeDescription;

  /// No description provided for @commissionsFixedFeePerBooking.
  ///
  /// In en, this message translates to:
  /// **'Fixed fee per booking'**
  String get commissionsFixedFeePerBooking;

  /// No description provided for @commissionsPayouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get commissionsPayouts;

  /// No description provided for @commissionsPayoutsDescription.
  ///
  /// In en, this message translates to:
  /// **'Payouts are sent automatically via Stripe'**
  String get commissionsPayoutsDescription;

  /// No description provided for @commissionsRates.
  ///
  /// In en, this message translates to:
  /// **'Commission rates'**
  String get commissionsRates;

  /// No description provided for @commissionsServiceBookings.
  ///
  /// In en, this message translates to:
  /// **'Service Bookings'**
  String get commissionsServiceBookings;

  /// No description provided for @commissionsServiceBookingsDesc.
  ///
  /// In en, this message translates to:
  /// **'18% commission on service bookings'**
  String get commissionsServiceBookingsDesc;

  /// No description provided for @commissionsServicePrice.
  ///
  /// In en, this message translates to:
  /// **'Service price'**
  String get commissionsServicePrice;

  /// No description provided for @commissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Commissions & Fees'**
  String get commissionsTitle;

  /// No description provided for @commissionsTransparentPricing.
  ///
  /// In en, this message translates to:
  /// **'Transparent pricing'**
  String get commissionsTransparentPricing;

  /// No description provided for @commissionsYouReceive.
  ///
  /// In en, this message translates to:
  /// **'You receive'**
  String get commissionsYouReceive;

  /// No description provided for @confirmBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm balance'**
  String get confirmBalanceTitle;

  /// No description provided for @confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get confirmCancellation;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @copyLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLinkAction;

  /// No description provided for @createEventAction.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get createEventAction;

  /// No description provided for @createProAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Pro account'**
  String get createProAccount;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get creditCard;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get dashboardLoadError;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand this action is irreversible'**
  String get deleteAccountConfirmCheckbox;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all data'**
  String get deleteAccountDescription;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get deleteAccountFailed;

  /// No description provided for @deleteAccountIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get deleteAccountIrreversible;

  /// No description provided for @deleteAccountPermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountPermanently;

  /// No description provided for @deleteVideoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this video?'**
  String get deleteVideoConfirm;

  /// No description provided for @deleteVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete video'**
  String get deleteVideoTitle;

  /// No description provided for @depositAmountCad.
  ///
  /// In en, this message translates to:
  /// **'Deposit amount (CAD)'**
  String get depositAmountCad;

  /// No description provided for @depositCadMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum \$5 CAD'**
  String get depositCadMinimum;

  /// No description provided for @depositClientPaysNow.
  ///
  /// In en, this message translates to:
  /// **'Client pays now'**
  String get depositClientPaysNow;

  /// No description provided for @depositDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Client pays the full amount on site'**
  String get depositDisabledDescription;

  /// No description provided for @depositEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Client pays a deposit online'**
  String get depositEnabledDescription;

  /// No description provided for @depositExplanation.
  ///
  /// In en, this message translates to:
  /// **'The deposit secures the booking'**
  String get depositExplanation;

  /// No description provided for @depositMinimumDescription.
  ///
  /// In en, this message translates to:
  /// **'Minimum deposit amount'**
  String get depositMinimumDescription;

  /// No description provided for @depositMinimumTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum deposit'**
  String get depositMinimumTitle;

  /// No description provided for @depositPaidOnline.
  ///
  /// In en, this message translates to:
  /// **'Paid online'**
  String get depositPaidOnline;

  /// No description provided for @depositPercent.
  ///
  /// In en, this message translates to:
  /// **'Deposit %'**
  String get depositPercent;

  /// No description provided for @depositPercentageDescription.
  ///
  /// In en, this message translates to:
  /// **'Percentage of total price'**
  String get depositPercentageDescription;

  /// No description provided for @depositPercentageTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit percentage'**
  String get depositPercentageTitle;

  /// No description provided for @depositPlusSurplace.
  ///
  /// In en, this message translates to:
  /// **'Deposit + balance on site'**
  String get depositPlusSurplace;

  /// No description provided for @depositPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit preview'**
  String get depositPreviewTitle;

  /// No description provided for @depositQuickSelect.
  ///
  /// In en, this message translates to:
  /// **'Quick select'**
  String get depositQuickSelect;

  /// No description provided for @depositReceivedOnline.
  ///
  /// In en, this message translates to:
  /// **'Received online'**
  String get depositReceivedOnline;

  /// No description provided for @depositRequire.
  ///
  /// In en, this message translates to:
  /// **'Require deposit'**
  String get depositRequire;

  /// No description provided for @depositRequireOnBooking.
  ///
  /// In en, this message translates to:
  /// **'Require deposit on booking'**
  String get depositRequireOnBooking;

  /// No description provided for @depositSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get depositSaveSettings;

  /// No description provided for @depositServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get depositServiceFee;

  /// No description provided for @depositServiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Service total'**
  String get depositServiceTotal;

  /// No description provided for @depositSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Deposit settings saved'**
  String get depositSettingsSaved;

  /// No description provided for @depositSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit settings'**
  String get depositSettingsTitle;

  /// No description provided for @depositsCollected.
  ///
  /// In en, this message translates to:
  /// **'Deposits collected'**
  String get depositsCollected;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your service…'**
  String get descriptionHint;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @doneCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneCountLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @editVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit video'**
  String get editVideoTitle;

  /// No description provided for @endLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endLabel;

  /// No description provided for @enterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code'**
  String get enterCodeHint;

  /// No description provided for @eventsQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsQuickAction;

  /// No description provided for @eventsTab.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTab;

  /// No description provided for @fastReplyBadge.
  ///
  /// In en, this message translates to:
  /// **'Fast reply'**
  String get fastReplyBadge;

  /// No description provided for @feedDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get feedDiscover;

  /// No description provided for @feedFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedFollowing;

  /// No description provided for @feedLikeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update like. Please try again.'**
  String get feedLikeFailed;

  /// No description provided for @feedSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save this video. Please try again.'**
  String get feedSaveFailed;

  /// No description provided for @feedFollowFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update follow. Please try again.'**
  String get feedFollowFailed;

  /// No description provided for @feedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the feed. Check your connection.'**
  String get feedLoadError;

  /// No description provided for @feedRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get feedRetry;

  /// No description provided for @filtersTool.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTool;

  /// No description provided for @followLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followLabel;

  /// No description provided for @followMeSection.
  ///
  /// In en, this message translates to:
  /// **'Follow me'**
  String get followMeSection;

  /// No description provided for @followersLabel.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followersLabel;

  /// No description provided for @followingLabel.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingLabel;

  /// No description provided for @freePrice.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freePrice;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @fullPayment.
  ///
  /// In en, this message translates to:
  /// **'Full payment'**
  String get fullPayment;

  /// No description provided for @generateSlots.
  ///
  /// In en, this message translates to:
  /// **'Generate slots'**
  String get generateSlots;

  /// No description provided for @glutenFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Gluten-free'**
  String get glutenFreeLabel;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @grossRevenue.
  ///
  /// In en, this message translates to:
  /// **'Gross revenue'**
  String get grossRevenue;

  /// No description provided for @hashtagsHint.
  ///
  /// In en, this message translates to:
  /// **'Add hashtags…'**
  String get hashtagsHint;

  /// No description provided for @hashtagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Hashtags'**
  String get hashtagsLabel;

  /// No description provided for @invalidDepositAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid deposit amount'**
  String get invalidDepositAmount;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get leaveReview;

  /// No description provided for @likeProsToFindHere.
  ///
  /// In en, this message translates to:
  /// **'Like pros to find them here'**
  String get likeProsToFindHere;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @linkCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedSnack;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get loadError;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your location…'**
  String get locationHint;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @manageServices.
  ///
  /// In en, this message translates to:
  /// **'Manage services'**
  String get manageServices;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @uploadScreenEditorialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One video, one category, one description — your service finds its audience.'**
  String get uploadScreenEditorialSubtitle;

  /// No description provided for @uploadVideoEmptyDropzoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a video'**
  String get uploadVideoEmptyDropzoneTitle;

  /// No description provided for @uploadVideoReady.
  ///
  /// In en, this message translates to:
  /// **'Video ready'**
  String get uploadVideoReady;

  /// No description provided for @uploadVideoTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get uploadVideoTapToChange;

  /// No description provided for @uploadVideoFieldValid.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get uploadVideoFieldValid;

  /// No description provided for @uploadVideoFieldMinChars.
  ///
  /// In en, this message translates to:
  /// **'Min {count} characters'**
  String uploadVideoFieldMinChars(int count);

  /// No description provided for @uploadVideoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploadVideoUploading;

  /// No description provided for @uploadVideoPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing'**
  String get uploadVideoPublishing;

  /// No description provided for @addVideoChooseSource.
  ///
  /// In en, this message translates to:
  /// **'Choose a source'**
  String get addVideoChooseSource;

  /// No description provided for @markAsDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markAsDone;

  /// No description provided for @markAsDoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Mark this appointment as completed?'**
  String get markAsDoneMessage;

  /// No description provided for @markAsDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as done?'**
  String get markAsDoneTitle;

  /// No description provided for @memberBadge.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberBadge;

  /// No description provided for @menuTab.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTab;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @moreOptionsAction.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptionsAction;

  /// No description provided for @mostBookings.
  ///
  /// In en, this message translates to:
  /// **'Most bookings'**
  String get mostBookings;

  /// No description provided for @mostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most recent'**
  String get mostRecent;

  /// No description provided for @mostSpent.
  ///
  /// In en, this message translates to:
  /// **'Most spent'**
  String get mostSpent;

  /// No description provided for @myClients.
  ///
  /// In en, this message translates to:
  /// **'My clients'**
  String get myClients;

  /// No description provided for @myEventsSection.
  ///
  /// In en, this message translates to:
  /// **'My events'**
  String get myEventsSection;

  /// No description provided for @myFavoritePros.
  ///
  /// In en, this message translates to:
  /// **'My favorite pros'**
  String get myFavoritePros;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @myQrCode.
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get myQrCode;

  /// No description provided for @myServicesSection.
  ///
  /// In en, this message translates to:
  /// **'My services'**
  String get myServicesSection;

  /// No description provided for @myVideosSection.
  ///
  /// In en, this message translates to:
  /// **'My videos'**
  String get myVideosSection;

  /// No description provided for @netRevenue.
  ///
  /// In en, this message translates to:
  /// **'Net revenue'**
  String get netRevenue;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBadge;

  /// No description provided for @newTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'New time slot'**
  String get newTimeSlot;

  /// No description provided for @nextEventHeader.
  ///
  /// In en, this message translates to:
  /// **'Next event'**
  String get nextEventHeader;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @noBookableServices.
  ///
  /// In en, this message translates to:
  /// **'No bookable services'**
  String get noBookableServices;

  /// No description provided for @noCancel.
  ///
  /// In en, this message translates to:
  /// **'No, keep it'**
  String get noCancel;

  /// No description provided for @noClients.
  ///
  /// In en, this message translates to:
  /// **'No clients yet'**
  String get noClients;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noComments;

  /// No description provided for @noEventsLabel.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get noEventsLabel;

  /// No description provided for @noMenuAvailable.
  ///
  /// In en, this message translates to:
  /// **'No menu available'**
  String get noMenuAvailable;

  /// No description provided for @noProfessionalsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No professionals available'**
  String get noProfessionalsAvailable;

  /// No description provided for @noRulesHint.
  ///
  /// In en, this message translates to:
  /// **'No availability rules yet'**
  String get noRulesHint;

  /// No description provided for @noServicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No services available'**
  String get noServicesAvailable;

  /// No description provided for @noServicesLabel.
  ///
  /// In en, this message translates to:
  /// **'No services'**
  String get noServicesLabel;

  /// No description provided for @noSlotsForDate.
  ///
  /// In en, this message translates to:
  /// **'No slots available for this date'**
  String get noSlotsForDate;

  /// No description provided for @noSlotsForDay.
  ///
  /// In en, this message translates to:
  /// **'No slots for this day'**
  String get noSlotsForDay;

  /// No description provided for @noTransactionsPeriod.
  ///
  /// In en, this message translates to:
  /// **'No transactions for this period'**
  String get noTransactionsPeriod;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @noVideosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No videos available'**
  String get noVideosAvailable;

  /// No description provided for @noVideosYet.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get noVideosYet;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @notifMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get notifMarketing;

  /// No description provided for @notifMarketingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Promotions and special offers'**
  String get notifMarketingSubtitle;

  /// No description provided for @notifMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notifMessages;

  /// No description provided for @notifMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New messages from clients'**
  String get notifMessagesSubtitle;

  /// No description provided for @notifReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifReminders;

  /// No description provided for @notifRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment reminders'**
  String get notifRemindersSubtitle;

  /// No description provided for @notifReviewRequests.
  ///
  /// In en, this message translates to:
  /// **'Review requests'**
  String get notifReviewRequests;

  /// No description provided for @notifReviewRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requests to review your experience'**
  String get notifReviewRequestsSubtitle;

  /// No description provided for @notifSectionAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get notifSectionAppointments;

  /// No description provided for @notifSectionCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get notifSectionCommunication;

  /// No description provided for @notifSectionEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get notifSectionEvents;

  /// No description provided for @notifSectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get notifSectionOther;

  /// No description provided for @notifUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get notifUpdates;

  /// No description provided for @notifUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App updates and new features'**
  String get notifUpdatesSubtitle;

  /// No description provided for @notifWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Waitlist'**
  String get notifWaitlist;

  /// No description provided for @notifWaitlistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Waitlist notifications'**
  String get notifWaitlistSubtitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @openForBooking.
  ///
  /// In en, this message translates to:
  /// **'Open for booking'**
  String get openForBooking;

  /// No description provided for @payButtonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payButtonPrefix;

  /// No description provided for @payNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNowLabel;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPending;

  /// No description provided for @paymentSubtitlePrefix.
  ///
  /// In en, this message translates to:
  /// **'Payment for'**
  String get paymentSubtitlePrefix;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get perDay;

  /// No description provided for @periodNinetyDays.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get periodNinetyDays;

  /// No description provided for @periodOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get periodOneYear;

  /// No description provided for @periodSevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get periodSevenDays;

  /// No description provided for @periodThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get periodThirtyDays;

  /// No description provided for @photoUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get photoUploadError;

  /// No description provided for @priceCad.
  ///
  /// In en, this message translates to:
  /// **'Price (CAD)'**
  String get priceCad;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @proProfileFromPrice.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get proProfileFromPrice;

  /// No description provided for @proProfileNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get proProfileNoReviews;

  /// No description provided for @proShellCateringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your catering menu'**
  String get proShellCateringSubtitle;

  /// No description provided for @proShellGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get proShellGallery;

  /// No description provided for @proShellLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get proShellLanguage;

  /// No description provided for @proShellMyMenu.
  ///
  /// In en, this message translates to:
  /// **'My menu'**
  String get proShellMyMenu;

  /// No description provided for @proShellMyPackages.
  ///
  /// In en, this message translates to:
  /// **'My packages'**
  String get proShellMyPackages;

  /// No description provided for @proShellMyReviews.
  ///
  /// In en, this message translates to:
  /// **'My reviews'**
  String get proShellMyReviews;

  /// No description provided for @proShellPaymentConfig.
  ///
  /// In en, this message translates to:
  /// **'Payment configuration'**
  String get proShellPaymentConfig;

  /// No description provided for @proToolsSection.
  ///
  /// In en, this message translates to:
  /// **'Pro tools'**
  String get proToolsSection;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get profileLoadError;

  /// No description provided for @profileLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load this profile'**
  String get profileLoadErrorMessage;

  /// No description provided for @profileNotFoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFoundLabel;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @promoApplied.
  ///
  /// In en, this message translates to:
  /// **'Promo code applied'**
  String get promoApplied;

  /// No description provided for @promoCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCodeTitle;

  /// No description provided for @promoCodes.
  ///
  /// In en, this message translates to:
  /// **'Promo codes'**
  String get promoCodes;

  /// No description provided for @publishAService.
  ///
  /// In en, this message translates to:
  /// **'Publish a service'**
  String get publishAService;

  /// No description provided for @publishMyService.
  ///
  /// In en, this message translates to:
  /// **'Publish my service'**
  String get publishMyService;

  /// No description provided for @qrShareInfo.
  ///
  /// In en, this message translates to:
  /// **'Share this QR code with your clients'**
  String get qrShareInfo;

  /// No description provided for @quickActionsHeader.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActionsHeader;

  /// No description provided for @recentHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent history'**
  String get recentHistory;

  /// No description provided for @recordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get recordVideo;

  /// No description provided for @recordVideoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record a video of your service'**
  String get recordVideoSubtitle;

  /// No description provided for @refundErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Refund failed. Please try again.'**
  String get refundErrorRetry;

  /// No description provided for @refundRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund request'**
  String get refundRequestTitle;

  /// No description provided for @remainingBalanceOnSite.
  ///
  /// In en, this message translates to:
  /// **'Remaining balance on site'**
  String get remainingBalanceOnSite;

  /// No description provided for @remainingOnDay.
  ///
  /// In en, this message translates to:
  /// **'Remaining on the day'**
  String get remainingOnDay;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportBooking.
  ///
  /// In en, this message translates to:
  /// **'Report booking'**
  String get reportBooking;

  /// No description provided for @reportReasonFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get reportReasonFakeProfile;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSent;

  /// No description provided for @reportSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmitButton;

  /// No description provided for @reportWhyReporting.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting?'**
  String get reportWhyReporting;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @reserveLabel.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get reserveLabel;

  /// No description provided for @retourLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get retourLabel;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @revenueAndStats.
  ///
  /// In en, this message translates to:
  /// **'Revenue & Stats'**
  String get revenueAndStats;

  /// No description provided for @revenueQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueQuickAction;

  /// No description provided for @reviewDone.
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get reviewDone;

  /// No description provided for @reviewFeedbackHelps.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps improve the service'**
  String get reviewFeedbackHelps;

  /// No description provided for @reviewHowWasAppointment.
  ///
  /// In en, this message translates to:
  /// **'How was your appointment?'**
  String get reviewHowWasAppointment;

  /// No description provided for @reviewLeaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get reviewLeaveReview;

  /// No description provided for @reviewShareExperience.
  ///
  /// In en, this message translates to:
  /// **'Share your experience'**
  String get reviewShareExperience;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get reviewSubmit;

  /// No description provided for @reviewTapToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap to rate'**
  String get reviewTapToRate;

  /// No description provided for @reviewThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your review!'**
  String get reviewThankYou;

  /// No description provided for @reviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get reviewsEmpty;

  /// No description provided for @reviewsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reviewsFilterAll;

  /// No description provided for @reviewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsLabel;

  /// No description provided for @reviewsReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews received'**
  String get reviewsReceivedTitle;

  /// No description provided for @reviewsTab.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTab;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @scanTicket.
  ///
  /// In en, this message translates to:
  /// **'Scan ticket'**
  String get scanTicket;

  /// No description provided for @searchClientHint.
  ///
  /// In en, this message translates to:
  /// **'Search clients…'**
  String get searchClientHint;

  /// No description provided for @searchProfessionalHint.
  ///
  /// In en, this message translates to:
  /// **'Search professionals…'**
  String get searchProfessionalHint;

  /// No description provided for @secured.
  ///
  /// In en, this message translates to:
  /// **'Secured'**
  String get secured;

  /// No description provided for @selectCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get selectCategoryRequired;

  /// No description provided for @selectVideoMax.
  ///
  /// In en, this message translates to:
  /// **'Select a video (max 2 min)'**
  String get selectVideoMax;

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLabel;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get serviceFee;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get serviceName;

  /// No description provided for @serviceNameMinChars.
  ///
  /// In en, this message translates to:
  /// **'Service name must be at least 3 characters'**
  String get serviceNameMinChars;

  /// No description provided for @servicesAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Services available'**
  String get servicesAvailableLabel;

  /// No description provided for @servicesQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesQuickAction;

  /// No description provided for @servicesTab.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTab;

  /// No description provided for @settingsAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get settingsAvailability;

  /// No description provided for @settingsCancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get settingsCancellationPolicy;

  /// No description provided for @settingsCancellationPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your cancellation rules'**
  String get settingsCancellationPolicySubtitle;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsCommissions.
  ///
  /// In en, this message translates to:
  /// **'Commissions & Fees'**
  String get settingsCommissions;

  /// No description provided for @settingsConfigurePayments.
  ///
  /// In en, this message translates to:
  /// **'Configure payments'**
  String get settingsConfigurePayments;

  /// No description provided for @settingsContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get settingsContactUs;

  /// No description provided for @settingsDepositSettings.
  ///
  /// In en, this message translates to:
  /// **'Deposit settings'**
  String get settingsDepositSettings;

  /// No description provided for @settingsDepositSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure deposit requirements'**
  String get settingsDepositSettingsSubtitle;

  /// No description provided for @settingsHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get settingsHistory;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsManageServices.
  ///
  /// In en, this message translates to:
  /// **'Manage services'**
  String get settingsManageServices;

  /// No description provided for @settingsMyEvents.
  ///
  /// In en, this message translates to:
  /// **'My events'**
  String get settingsMyEvents;

  /// No description provided for @settingsMyQrCode.
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get settingsMyQrCode;

  /// No description provided for @settingsMyReviews.
  ///
  /// In en, this message translates to:
  /// **'My reviews'**
  String get settingsMyReviews;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get settingsQuotes;

  /// No description provided for @settingsQuotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage quote requests'**
  String get settingsQuotesSubtitle;

  /// No description provided for @settingsRevenueStats.
  ///
  /// In en, this message translates to:
  /// **'Revenue & Statistics'**
  String get settingsRevenueStats;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get settingsSectionBookings;

  /// No description provided for @settingsSectionBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get settingsSectionBusiness;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsSectionLegal;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get settingsSectionPayments;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSectionSupport;

  /// No description provided for @shareCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get shareCopy;

  /// No description provided for @shareMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get shareMessages;

  /// No description provided for @shareMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Share my profile'**
  String get shareMyProfile;

  /// No description provided for @shareProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfileTitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInToFollow.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow'**
  String get signInToFollow;

  /// No description provided for @signInToMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to message'**
  String get signInToMessage;

  /// No description provided for @slotDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Slot duration'**
  String get slotDurationLabel;

  /// No description provided for @slotsPreviewHeader.
  ///
  /// In en, this message translates to:
  /// **'Slots preview'**
  String get slotsPreviewHeader;

  /// No description provided for @slotsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Slots updated'**
  String get slotsUpdated;

  /// No description provided for @socialLinksAutoDetectHint.
  ///
  /// In en, this message translates to:
  /// **'Links are auto-detected'**
  String get socialLinksAutoDetectHint;

  /// No description provided for @socialLinksHeader.
  ///
  /// In en, this message translates to:
  /// **'Social links'**
  String get socialLinksHeader;

  /// No description provided for @socialNetworks.
  ///
  /// In en, this message translates to:
  /// **'Social networks'**
  String get socialNetworks;

  /// No description provided for @soumissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get soumissionsLabel;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @statsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics'**
  String get statsLoadError;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @stepConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get stepConfirmed;

  /// No description provided for @stepDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get stepDate;

  /// No description provided for @stepPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get stepPayment;

  /// No description provided for @stepService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get stepService;

  /// No description provided for @stepSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get stepSummary;

  /// No description provided for @stepTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get stepTime;

  /// No description provided for @subscribedLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get subscribedLabel;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @summarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your booking details'**
  String get summarySubtitle;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @textTool.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textTool;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @topProBadge.
  ///
  /// In en, this message translates to:
  /// **'Top Pro'**
  String get topProBadge;

  /// No description provided for @totalPeriod.
  ///
  /// In en, this message translates to:
  /// **'Total for period'**
  String get totalPeriod;

  /// No description provided for @totalService.
  ///
  /// In en, this message translates to:
  /// **'Total for service'**
  String get totalService;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @upcomingAppointmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming appointments'**
  String get upcomingAppointmentsHint;

  /// No description provided for @upcomingBookingsHeader.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bookings'**
  String get upcomingBookingsHeader;

  /// No description provided for @uploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload video'**
  String get uploadVideo;

  /// No description provided for @uploadVideoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a video of your service'**
  String get uploadVideoSubtitle;

  /// No description provided for @usernameInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscores'**
  String get usernameInvalidChars;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameMinChars.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameMinChars;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get usernameTaken;

  /// No description provided for @veganLabel.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get veganLabel;

  /// No description provided for @vegetarianLabel.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get vegetarianLabel;

  /// No description provided for @verifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedBadge;

  /// No description provided for @videoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// No description provided for @videoPublished.
  ///
  /// In en, this message translates to:
  /// **'Video published'**
  String get videoPublished;

  /// No description provided for @videoStatusFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get videoStatusFlagged;

  /// No description provided for @videoStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get videoStatusPublished;

  /// No description provided for @videoStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get videoStatusRejected;

  /// No description provided for @videoTooLong.
  ///
  /// In en, this message translates to:
  /// **'Video is too long (max 2 minutes)'**
  String get videoTooLong;

  /// No description provided for @videoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable'**
  String get videoUnavailable;

  /// No description provided for @videosTab.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videosTab;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View calendar'**
  String get viewCalendar;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @weeklyRulesHeader.
  ///
  /// In en, this message translates to:
  /// **'Weekly rules'**
  String get weeklyRulesHeader;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @cannotOpenStripeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open the Stripe dashboard'**
  String get cannotOpenStripeDashboard;

  /// No description provided for @stripeCountryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Where will you receive payouts?'**
  String get stripeCountryPickerTitle;

  /// No description provided for @stripeCountryPickerSub.
  ///
  /// In en, this message translates to:
  /// **'Your country determines your payout currency and can\'t be changed later.'**
  String get stripeCountryPickerSub;

  /// No description provided for @stripeCountryCA.
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get stripeCountryCA;

  /// No description provided for @stripeCountryCASub.
  ///
  /// In en, this message translates to:
  /// **'CAD — Canadian Dollars'**
  String get stripeCountryCASub;

  /// No description provided for @stripeCountryFR.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get stripeCountryFR;

  /// No description provided for @stripeCountryFRSub.
  ///
  /// In en, this message translates to:
  /// **'EUR — Euros'**
  String get stripeCountryFRSub;

  /// No description provided for @stripeCountryUS.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get stripeCountryUS;

  /// No description provided for @stripeCountryUSSub.
  ///
  /// In en, this message translates to:
  /// **'USD — US Dollars'**
  String get stripeCountryUSSub;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get yesCancel;

  /// No description provided for @yourTextHint.
  ///
  /// In en, this message translates to:
  /// **'Your text here…'**
  String get yourTextHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title (required)'**
  String get titleRequired;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Give your video a title…'**
  String get titleHint;

  /// No description provided for @addLabel2.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel2;

  /// No description provided for @reviewRating1.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get reviewRating1;

  /// No description provided for @reviewRating2.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get reviewRating2;

  /// No description provided for @reviewRating3.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get reviewRating3;

  /// No description provided for @reviewRating4.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewRating4;

  /// No description provided for @reviewRating5.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get reviewRating5;

  /// No description provided for @cancellationRuleMoreThan24hTitle.
  ///
  /// In en, this message translates to:
  /// **'More than 24h before'**
  String get cancellationRuleMoreThan24hTitle;

  /// No description provided for @cancellationRuleMoreThan24hSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full refund'**
  String get cancellationRuleMoreThan24hSubtitle;

  /// No description provided for @cancellationRuleMoreThan24hDescription.
  ///
  /// In en, this message translates to:
  /// **'Cancel more than 24 hours before the appointment for a full refund of the deposit.'**
  String get cancellationRuleMoreThan24hDescription;

  /// No description provided for @cancellationRuleLessThan24hTitle.
  ///
  /// In en, this message translates to:
  /// **'Less than 24h before'**
  String get cancellationRuleLessThan24hTitle;

  /// No description provided for @cancellationRuleLessThan24hSubtitle.
  ///
  /// In en, this message translates to:
  /// **'50% refund'**
  String get cancellationRuleLessThan24hSubtitle;

  /// No description provided for @cancellationRuleLessThan24hDescription.
  ///
  /// In en, this message translates to:
  /// **'Cancel less than 24 hours before the appointment for a 50% refund of the deposit.'**
  String get cancellationRuleLessThan24hDescription;

  /// No description provided for @balanceOnSite.
  ///
  /// In en, this message translates to:
  /// **'Balance on site: {amount} {currency}'**
  String balanceOnSite(String amount, String currency);

  /// No description provided for @blockUserConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block {name}?'**
  String blockUserConfirmMessage(String name);

  /// No description provided for @commissionEstimate.
  ///
  /// In en, this message translates to:
  /// **'Commission {pct}%: {commission} {currency} — you receive {net} {currency}'**
  String commissionEstimate(
      String pct, String commission, String currency, String net);

  /// No description provided for @commissionsExampleCatering.
  ///
  /// In en, this message translates to:
  /// **'Ex: \${price} catering → you receive \${net}'**
  String commissionsExampleCatering(int price, String net);

  /// No description provided for @commissionsExampleService.
  ///
  /// In en, this message translates to:
  /// **'Ex: \${price} service → you receive \${net}'**
  String commissionsExampleService(int price, String net);

  /// No description provided for @commissionsExampleTicket.
  ///
  /// In en, this message translates to:
  /// **'Ex: \${price} ticket → you receive \${net}'**
  String commissionsExampleTicket(int price, String net);

  /// No description provided for @commissionsSpotbookCommission.
  ///
  /// In en, this message translates to:
  /// **'Spotbook commission: {pct}%'**
  String commissionsSpotbookCommission(int pct);

  /// No description provided for @confirmBalanceMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm remaining balance of {amount} {currency} collected on site?'**
  String confirmBalanceMessage(String amount, String currency);

  /// No description provided for @depositAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'{pct}% deposit'**
  String depositAmountLabel(int pct);

  /// No description provided for @linkPlatform.
  ///
  /// In en, this message translates to:
  /// **'Link {platform}'**
  String linkPlatform(String platform);

  /// No description provided for @noBookingsOn.
  ///
  /// In en, this message translates to:
  /// **'No bookings on {date}'**
  String noBookingsOn(String date);

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @pasteLinkFor.
  ///
  /// In en, this message translates to:
  /// **'Paste your {platform} link'**
  String pasteLinkFor(String platform);

  /// No description provided for @publicProfileTicketsLeft.
  ///
  /// In en, this message translates to:
  /// **'{remaining} tickets left'**
  String publicProfileTicketsLeft(int remaining);

  /// No description provided for @publishingProgress.
  ///
  /// In en, this message translates to:
  /// **'Publishing… {percent}%'**
  String publishingProgress(int percent);

  /// No description provided for @reviewCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewCountLabel(int count);

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @settingsCommissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings {bookingPct}% · Events {eventPct}% · Fee \${fee}'**
  String settingsCommissionsSubtitle(int bookingPct, int eventPct, String fee);

  /// No description provided for @ticketPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String ticketPriceLabel(String price);

  /// No description provided for @videoReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String videoReason(String reason);

  /// No description provided for @videoSelectedDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {seconds}s'**
  String videoSelectedDuration(String seconds);

  /// No description provided for @depositPreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Preview: deposit on a \${price} service'**
  String depositPreviewDescription(String price);

  /// No description provided for @depositRemainingOnDay.
  ///
  /// In en, this message translates to:
  /// **'Remaining on site: \${amount}'**
  String depositRemainingOnDay(String amount);

  /// No description provided for @spotifySheetTrackAdded.
  ///
  /// In en, this message translates to:
  /// **'Track added: {track}'**
  String spotifySheetTrackAdded(String track);

  /// No description provided for @authStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String authStepLabel(int current, int total);

  /// No description provided for @waitlistNotifyMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be notified if a ticket becomes available for \\\"{eventTitle}\\\". You will have 30 minutes to confirm.'**
  String waitlistNotifyMessage(String eventTitle);

  /// No description provided for @alreadyScannedAt.
  ///
  /// In en, this message translates to:
  /// **'Already scanned at {time}'**
  String alreadyScannedAt(String time);

  /// No description provided for @ticketsSoldCount.
  ///
  /// In en, this message translates to:
  /// **'{sold} / {total}'**
  String ticketsSoldCount(int sold, int total);

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'From \${price}'**
  String fromPrice(String price);

  /// No description provided for @ticketTierIndex.
  ///
  /// In en, this message translates to:
  /// **'Ticket Tier {index}'**
  String ticketTierIndex(int index);

  /// No description provided for @spotsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} spots remaining'**
  String spotsRemaining(int count);

  /// No description provided for @noEventsWithFilter.
  ///
  /// In en, this message translates to:
  /// **'No {filter} events'**
  String noEventsWithFilter(String filter);

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

  /// No description provided for @scannedProgress.
  ///
  /// In en, this message translates to:
  /// **'{scanned} / {total} scanned'**
  String scannedProgress(int scanned, int total);

  /// No description provided for @yourQrCode.
  ///
  /// In en, this message translates to:
  /// **'Your QR Code'**
  String get yourQrCode;

  /// No description provided for @presentQrOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code when you arrive for your appointment.'**
  String get presentQrOnArrival;

  /// No description provided for @qrAlreadyValidated.
  ///
  /// In en, this message translates to:
  /// **'Already validated'**
  String get qrAlreadyValidated;

  /// No description provided for @myAppointment.
  ///
  /// In en, this message translates to:
  /// **'My appointment'**
  String get myAppointment;

  /// No description provided for @bookingValidated.
  ///
  /// In en, this message translates to:
  /// **'Appointment validated!'**
  String get bookingValidated;

  /// No description provided for @bookingValidatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'This appointment has been verified successfully.'**
  String get bookingValidatedSuccess;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelled;

  /// No description provided for @qrBookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'This booking has been cancelled and cannot be validated.'**
  String get qrBookingCancelled;

  /// No description provided for @invalidBookingQr.
  ///
  /// In en, this message translates to:
  /// **'Invalid booking QR'**
  String get invalidBookingQr;

  /// No description provided for @qrCouldNotBeValidated.
  ///
  /// In en, this message translates to:
  /// **'This QR code could not be validated.'**
  String get qrCouldNotBeValidated;

  /// No description provided for @scanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan another'**
  String get scanAnother;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to dashboard'**
  String get backToDashboard;

  /// No description provided for @appointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointment;

  /// No description provided for @ticket.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get ticket;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @scanTicketMode.
  ///
  /// In en, this message translates to:
  /// **'Event ticket scanning'**
  String get scanTicketMode;

  /// No description provided for @scanAllMode.
  ///
  /// In en, this message translates to:
  /// **'Scan tickets & appointments'**
  String get scanAllMode;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @typingIndicator.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get typingIndicator;

  /// No description provided for @ticketQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get ticketQuantity;

  /// No description provided for @ticketSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get ticketSubtotal;

  /// No description provided for @ticketServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee ({pct}%)'**
  String ticketServiceFee(int pct);

  /// No description provided for @ticketTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ticketTotal;

  /// No description provided for @ticketPurchasedSnack.
  ///
  /// In en, this message translates to:
  /// **'Ticket(s) purchased!'**
  String get ticketPurchasedSnack;

  /// No description provided for @ticketPayButton.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String ticketPayButton(String amount);

  /// No description provided for @ticketDecreaseQty.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get ticketDecreaseQty;

  /// No description provided for @ticketIncreaseQty.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get ticketIncreaseQty;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get chatMessageHint;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Say hi or pick a suggestion below'**
  String get chatEmptySubtitle;

  /// No description provided for @chatEmojiPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Emoji picker'**
  String get chatEmojiPickerLabel;

  /// No description provided for @quickReplyBarLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick replies'**
  String get quickReplyBarLabel;

  /// No description provided for @quickRepliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick replies'**
  String get quickRepliesTitle;

  /// No description provided for @quickRepliesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No custom replies yet'**
  String get quickRepliesEmptyTitle;

  /// No description provided for @quickRepliesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your own quick replies to respond to clients in a single tap.'**
  String get quickRepliesEmptySubtitle;

  /// No description provided for @quickRepliesAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add a reply'**
  String get quickRepliesAddButton;

  /// No description provided for @quickReplyEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reply'**
  String get quickReplyEditTitle;

  /// No description provided for @quickReplyAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New quick reply'**
  String get quickReplyAddTitle;

  /// No description provided for @quickReplyTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get quickReplyTextLabel;

  /// No description provided for @quickReplyTextHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. I’m available this weekend!'**
  String get quickReplyTextHint;

  /// No description provided for @quickReplySaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get quickReplySaveButton;

  /// No description provided for @quickReplyDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this reply?'**
  String get quickReplyDeleteConfirm;

  /// No description provided for @quickReplyErrorTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 200 characters'**
  String get quickReplyErrorTooLong;

  /// No description provided for @quickReplyErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Text cannot be empty'**
  String get quickReplyErrorEmpty;

  /// No description provided for @quickRepliesMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick replies'**
  String get quickRepliesMenuTitle;

  /// No description provided for @quickRepliesMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your ready-to-send messages'**
  String get quickRepliesMenuSubtitle;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get statusPaymentPending;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @paidOnline.
  ///
  /// In en, this message translates to:
  /// **'Paid online'**
  String get paidOnline;

  /// No description provided for @balanceToPay.
  ///
  /// In en, this message translates to:
  /// **'Balance to pay'**
  String get balanceToPay;

  /// No description provided for @balanceToCollect.
  ///
  /// In en, this message translates to:
  /// **'Balance to collect'**
  String get balanceToCollect;

  /// No description provided for @qrFullscreenTitle.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get qrFullscreenTitle;

  /// No description provided for @qrFullscreenHint.
  ///
  /// In en, this message translates to:
  /// **'Show this screen to the provider when you arrive.'**
  String get qrFullscreenHint;

  /// No description provided for @qrOpenFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get qrOpenFullscreen;

  /// No description provided for @qrCloseFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get qrCloseFullscreen;

  /// No description provided for @qrUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'QR not yet available'**
  String get qrUnavailableTitle;

  /// No description provided for @qrUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your QR code will be generated as soon as payment is confirmed.'**
  String get qrUnavailableSubtitle;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Videos from professionals will appear here'**
  String get feedEmptySubtitle;

  /// No description provided for @proSearchErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Search error'**
  String get proSearchErrorGeneric;

  /// No description provided for @proSearchEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Be the first to publish!'**
  String get proSearchEmptyCta;

  /// No description provided for @availabilityDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get availabilityDayOff;

  /// No description provided for @availabilityAddSlot.
  ///
  /// In en, this message translates to:
  /// **'Add a slot'**
  String get availabilityAddSlot;

  /// No description provided for @paymentReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt'**
  String get paymentReceiptTitle;

  /// No description provided for @favoriteRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites?'**
  String get favoriteRemoveConfirmTitle;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @videoBlockProAction.
  ///
  /// In en, this message translates to:
  /// **'Block this pro'**
  String get videoBlockProAction;

  /// No description provided for @videoCaptureLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load video: {error}'**
  String videoCaptureLoadFailed(String error);

  /// No description provided for @cateringQuoteGuestCountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the number of guests'**
  String get cateringQuoteGuestCountRequired;

  /// No description provided for @cateringDishNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a dish name'**
  String get cateringDishNameRequired;

  /// No description provided for @cateringForfaitNamePriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and price are required'**
  String get cateringForfaitNamePriceRequired;

  /// No description provided for @soumissionAddAtLeastOneItem.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item'**
  String get soumissionAddAtLeastOneItem;

  /// No description provided for @soumissionSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Quote sent to client!'**
  String get soumissionSentSuccess;
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
