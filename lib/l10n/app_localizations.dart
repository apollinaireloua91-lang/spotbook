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

  // ── Common ──
  String get a11yBack;
  String get buttonContinue;
  String get buttonNext;
  String get fieldRequired;

  // ── Auth: Login ──
  String get authWelcomeBack;
  String get authLoginSubtitle;
  String get authEmailHint;
  String get authErrorEmptyFields;
  String get authErrorEnterEmail;
  String get authMagicLinkSent;
  String get authMagicLinkSending;
  String get authMagicLink;
  String get authForgotPassword;
  String get authOrContinueWith;
  String get authContinueApple;
  String get authAppleComingSoon;
  String get authNoAccountPrefix;

  // ── Auth: Account Type Selection ──
  String get authWelcomeTitle;
  String get authSelectAccountType;
  String get authRoleClient;
  String get authRoleClientSubtitle;
  String get authRoleClientDescription;
  String get authRolePro;
  String get authRoleProSubtitle;
  String get authRoleProDescription;
  String get authAlreadyHaveAccount;

  // ── Auth: Forgot / Reset Password ──
  String get authForgotPasswordTitle;
  String get authForgotPasswordSubtitle;
  String get authEmailRequired;
  String get authEmailInvalid;
  String get authErrorTooManyAttempts;
  String get authErrorGenericEmail;
  String get authResetPassword;
  String get authRememberPassword;
  String get fieldEmail;
  String get authEmailSent;
  String get authCheckInbox;
  String get authCheckSpam;
  String get authResending;
  String get authResendLink;
  String get authBackToLogin;
  String get authResetLinkResent;
  String get authNewPasswordTitle;
  String get authNewPasswordSubtitle;
  String get authNewPasswordHint;
  String get authMinPassword;
  String get authConfirmPasswordHint;
  String get authPasswordMismatch;
  String get authPasswordUpdated;
  String get authUpdatePassword;

  // ── Auth: Sign Up ──
  String authStepLabel(int current, int total);
  String get authPasswordsDontMatch;
  String get authWhatInterests;
  String get authSelectCategoriesForFeed;
  String get authCreateMyAccount;
  String get authWhatServicesOffer;
  String get authSelectServiceCategories;
  String get authSignInWithGoogle;
  String get authCreateAccountTitle;
  String get authJoinCommunity;
  String get fieldFullName;
  String get fieldFullNameHint;
  String get fieldUsername;
  String get fieldAddress;
  String get fieldAddressHint;
  String get authYourInfo;
  String get authHowKnown;
  String get authYourProProfile;
  String get authPresentYourself;
  String get authMinSixChars;
  String get fieldConfirmPassword;

  // ── Complete Profile ──
  String get completeProfileUploadFailed;
  String get completeProfileSaveFailed;
  String get completeProfileAccountCreated;
  String get completeProfileTitle;
  String get completeProfileSubtitle;
  String get completeProfileBioHint;
  String get skipForNow;

  // ── Location Permission ──
  String get locationPermTitle;
  String get locationPermSubtitle;
  String get locationPermAllow;
  String get notNow;
  String get locationPermPrivacy;

  // ── Client Interest Categories ──
  String get categoriesLoadFailed;

  // ── Client Interest Goals ──
  String get goalsTitle;
  String get goalsSubtitle;
  String get goalDiscoverTitle;
  String get goalDiscoverDesc;
  String get goalBookTitle;
  String get goalBookDesc;
  String get goalEventsTitle;
  String get goalEventsDesc;
  String get goalPricesTitle;
  String get goalPricesDesc;

  // ── Pro Interest Categories ──
  String get proExpertiseTitle;
  String get proExpertiseSubtitle;

  // ── Pro Verification ──
  String get verificationUploadFailed;
  String get verificationIdRequired;
  String get proSetupTitle;
  String get verificationInProgress;
  String get actionRequired;
  String get phoneRequired;
  String get mobileNumber;
  String get phoneNumberHint;
  String get verificationSmsHint;
  String get smsComingSoon;
  String get sendCode;
  String get idRequired;
  String get idUploadDescription;
  String get tapToUpload;
  String get uploadFormats;
  String get idSecurityNote;
  String get submitDocuments;
  String get helpComingSoon;
  String get stepOf;

  // ── Stripe Connect ──
  String get stripePaymentsTitle;
  String get stripeOpenDashboard;
  String get stripeFinishSetup;
  String get stripeConnectBank;
  String get stripeHowItWorks;
  String get stripeStep1Title;
  String get stripeStep1Desc;
  String get stripeStep2Title;
  String get stripeStep2Desc;
  String get stripeStep3Title;
  String get stripeStep3Desc;
  String get stripeFeesTitle;
  String get stripeFeeBooking;
  String get stripeFeeBookingSub;
  String get stripeFeeEvent;
  String get stripeFeeEventSub;
  String get stripeFeeService;
  String get stripeFeeServiceSub;
  String get stripeNoMonthlyFees;
  String get stripeSecurityTitle;
  String get stripeTrustSsl;
  String get stripeTrustSslSub;
  String get stripeTrustPowered;
  String get stripeTrustPoweredSub;
  String get stripeTrustFast;
  String get stripeTrustFastSub;
  String get stripeFaqTitle;
  String get stripeFaqWhenPaid;
  String get stripeFaqWhenPaidAnswer;
  String get stripeFaqCancel;
  String get stripeFaqCancelAnswer;
  String get stripeFaqDeposit;
  String get stripeFaqDepositAnswer;
  String get stripeNeedHelp;
  String get stripeHeroActiveTitle;
  String get stripeHeroActiveSub;
  String get stripeHeroPendingTitle;
  String get stripeHeroPendingSub;
  String get stripeHeroConnectTitle;
  String get stripeHeroConnectSub;
  String get stripeSetupProgress;
  String get stripeDetailsSubmitted;
  String get stripeDetailsSubmittedSub;
  String get stripeChargesEnabled;
  String get stripeChargesEnabledSub;
  String get stripePayoutsEnabled;
  String get stripePayoutsEnabledSub;

  // ── Become Pro Setup ──
  String get becomeProTitle;
  String get becomeProStep1Title;
  String get becomeProStep1Subtitle;
  String get becomeProBusinessName;
  String get becomeProBusinessHint;
  String get becomeProCategoryLabel;
  String get becomeProCategoryHint;
  String get becomeProPhoneLabel;
  String get becomeProPhoneHint;
  String get becomeProStep2Title;
  String get becomeProStep2Subtitle;
  String get becomeProAddressLabel;
  String get becomeProAddressHint;
  String get becomeProStep3Title;
  String get becomeProStep3Subtitle;
  String get becomeProYourProfile;
  String get becomeProInfoBox;
  String get becomeProActivate;
  String get becomeProNameRequired;
  String get becomeProCategoryRequired;
  String get becomeProAddressRequired;
  String get becomeProAllFieldsRequired;
  String get becomeProSelectAddress;

  // ── Pro Business Details ──
  String get bizConfigInProgress;
  String get bizYourBusiness;
  String get bizSubtitle;
  String get bizBusinessName;
  String get bizBusinessHint;
  String get bizCategoryLabel;
  String get bizCategoryHint;
  String get bizAddressLabel;
  String get bizAddressHint;
  String get bizRequiredFieldsError;
  String get bizSelectAddressError;
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
