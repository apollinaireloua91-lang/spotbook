// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Spotbook';

  @override
  String get feed => 'Feed';

  @override
  String get discover => 'Discover';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get profile => 'Profile';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get search => 'Search';

  @override
  String get camera => 'Camera';

  @override
  String get appointments => 'Appointments';

  @override
  String get events => 'Events';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Sign up';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orSeparator => 'or';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get noAccount => 'No account? Sign up';

  @override
  String get alreadyAccount => 'Already have an account? Log in';

  @override
  String get chooseRole => 'Choose your role';

  @override
  String get client => 'Client';

  @override
  String get pro => 'Professional';

  @override
  String get book => 'Book';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get offline => 'Offline';

  @override
  String get favorites => 'Favorites';

  @override
  String get history => 'History';

  @override
  String get myTickets => 'My Tickets';

  @override
  String get consentMessage =>
      'We use analytics cookies to improve your experience.';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get share => 'Share';

  @override
  String clientProfileReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '$count review',
    );
    return '$_temp0';
  }

  @override
  String clientProfileMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get clientProfileConnectedSocials => 'CONNECTED SOCIALS';

  @override
  String get clientProfileCollaborationTitle => 'Contact for Collaboration';

  @override
  String get clientProfileCollaborationBody =>
      'Are you a service provider? Send a request to discuss partnerships and collaborations.';

  @override
  String get clientProfileSendCollaborationRequest =>
      'Send Collaboration Request';

  @override
  String get clientProfileCollaborationOpened => 'Conversation opened';

  @override
  String get clientProfileTakePhoto => 'Take a photo';

  @override
  String get clientProfileFromGallery => 'Gallery';

  @override
  String get clientProfileEditProfile => 'Edit Profile';

  @override
  String get clientProfilePrivateTabs =>
      'Only you can see this content on your profile.';

  @override
  String get clientProfileRemovedFavorite => 'Removed from favorites';

  @override
  String get clientProfileBookNow => 'Book Now';

  @override
  String get clientProfileTicketValid => 'Valid';

  @override
  String get clientProfileTicketUsed => 'Used';

  @override
  String get clientProfileNoFavorites => 'No favorites yet';

  @override
  String get clientProfileNoHistory => 'No past appointments';

  @override
  String get clientProfileNoTickets => 'No tickets yet';

  @override
  String get clientProfileNotSignedIn => 'Not signed in';

  @override
  String get clientProfileCollaborationError => 'Could not open conversation';

  @override
  String get proSettingsTitle => 'Pro settings';

  @override
  String get proSettingsSavedToast => 'Saved';

  @override
  String get proSettingsSectionAccount => 'ACCOUNT';

  @override
  String get proSettingsPhone => 'Phone';

  @override
  String get proSettingsChangePassword => 'Change password';

  @override
  String get proSettingsSectionBusiness => 'BUSINESS';

  @override
  String get proSettingsBusinessProfile => 'Business profile';

  @override
  String get proSettingsWorkAddress => 'Work address';

  @override
  String get proSettingsSectionBookings => 'BOOKINGS';

  @override
  String get proSettingsCancellationPolicy => 'Cancellation policy';

  @override
  String get proSettingsPolicyModerate => 'Moderate';

  @override
  String get proSettingsPolicyStrict => 'Strict';

  @override
  String get proSettingsPolicyFlexible => 'Flexible';

  @override
  String get proSettingsMinAdvance => 'Minimum advance booking';

  @override
  String get proSettingsHoursShort => 'h';

  @override
  String get proSettingsMinGap => 'Minimum gap between appointments';

  @override
  String get proSettingsMinutesShort => 'min';

  @override
  String get proSettingsMaxPerDay => 'Max appointments per day';

  @override
  String get proSettingsSectionPayments => 'PAYMENTS';

  @override
  String get proSettingsPayoutHistory => 'Payout history';

  @override
  String get proSettingsPaymentsInfo =>
      'Connect Stripe to receive payouts from clients.';

  @override
  String get proSettingsSectionNotifications => 'NOTIFICATIONS';

  @override
  String get proSettingsNotifSettings => 'Notification settings';

  @override
  String get proSettingsSectionPrivacy => 'PRIVACY';

  @override
  String get proSettingsProfilePublic => 'Public profile';

  @override
  String get proSettingsSearchVisible => 'Visible in search';

  @override
  String get proSettingsSectionLanguage => 'LANGUAGE';

  @override
  String get proSettingsLanguage => 'App language';

  @override
  String get proSettingsLangEnglish => 'English';

  @override
  String get proSettingsLangFrench => 'French';

  @override
  String get proSettingsSectionHelp => 'HELP';

  @override
  String get proSettingsFaq => 'FAQ';

  @override
  String get proSettingsContactSupport => 'Contact support';

  @override
  String get proSettingsDangerZone => 'DANGER ZONE';

  @override
  String get proSettingsSignOut => 'Sign out';

  @override
  String get proSettingsDeleteAccount => 'Delete my account';

  @override
  String get proSettingsModifyEmailTitle => 'Change email';

  @override
  String get proSettingsModifyPhoneTitle => 'Change phone';

  @override
  String get proSettingsSignOutTitle => 'Sign out?';

  @override
  String get proSettingsSignOutConfirm => 'Sign out';

  @override
  String get proSettingsStripeActive => 'Stripe active';

  @override
  String get proSettingsBankEnding => 'Bank';

  @override
  String get proSettingsStripeVerifying => 'Verification in progress';

  @override
  String get proSettingsStripeNotConfigured => 'Stripe not configured';

  @override
  String get proSettingsStripeConfigure => 'Configure Stripe Connect';

  @override
  String get proChangePasswordTitle => 'Change password';

  @override
  String get proCurrentPassword => 'Current password';

  @override
  String get proNewPassword => 'New password';

  @override
  String get proConfirmPassword => 'Confirm password';

  @override
  String get proSettingsSectionSpotify => 'MUSIC (FEED)';

  @override
  String get proSettingsSpotifyTitle => 'Spotify';

  @override
  String get proSettingsSpotifyLinked => 'Spotify account connected';

  @override
  String get proSettingsSpotifyConnect => 'Connect Spotify';

  @override
  String get proSettingsSpotifyDisconnect => 'Disconnect Spotify';

  @override
  String get proSettingsSpotifyHint =>
      'Link your account to see your top tracks in the pro feed music sheet.';

  @override
  String get proSettingsSpotifyMissingClientId =>
      'SPOTIFY_CLIENT_ID missing in .env';

  @override
  String get spotifySheetTitle => 'Add music';

  @override
  String get spotifySheetLinkedHint =>
      'Spotify linked — top tracks and richer search.';

  @override
  String get spotifySheetNotLinkedHint =>
      'Not linked: search only. Connect Spotify in Pro settings.';

  @override
  String get spotifySheetOpenSettings => 'Settings';

  @override
  String get spotifySheetSearchHint => 'Search a track or artist…';

  @override
  String get spotifySheetTopTracksHeader => 'Your recent top tracks (Spotify)';

  @override
  String get spotifySheetNoResults => 'No results';

  @override
  String get spotifySheetEmptyTop =>
      'No top tracks yet. Listen on Spotify and try again.';

  @override
  String get spotifySheetEmptyNeedLink =>
      'Connect Spotify in Pro settings to show your top tracks here.';

  @override
  String spotifySheetTrackAdded(String name) {
    return '$name — added to post';
  }

  @override
  String get settingsLanguageScreenTitle => 'Language';

  @override
  String get settingsLanguageScreenSubtitle =>
      'Choose Spotbook’s display language. Your preference is saved on this device.';

  @override
  String get settingsLanguageSavedSnack => 'Language saved';

  @override
  String get settingsLanguageMenuLabel => 'Language';
}
