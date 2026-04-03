import 'dart:io';

import 'package:go_router/go_router.dart';

import '../core/animations/page_transitions.dart';
import '../features/pro/presentation/camera/video_preview_screen.dart';
import '../features/auth/presentation/screens/account_type_selection_screen.dart';
import '../features/auth/presentation/screens/client_interest_categories_screen.dart';
import '../features/auth/presentation/screens/client_interest_goals_screen.dart';
import '../features/auth/presentation/screens/complete_profile_screen.dart';
import '../features/auth/presentation/screens/forgot_password_confirmation_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/permission_location_screen.dart';
import '../features/auth/presentation/screens/pro_interest_categories_screen.dart';
import '../features/auth/presentation/screens/pro_business_details_screen.dart';
import '../features/auth/presentation/screens/pro_verification_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/stripe_connect_screen.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/booking/presentation/screens/booking_cancellation_screen.dart';
import '../features/booking/presentation/screens/booking_detail_screen.dart';
import '../features/booking/presentation/screens/my_bookings_screen.dart';
import '../features/booking/presentation/screens/pro_dashboard_screen.dart';
import '../features/booking/presentation/screens/pro_rdv_screen.dart';
import '../features/booking/presentation/screens/pro_services_manage_screen.dart';
import '../features/booking/presentation/screens/pro_revenue_screen.dart';
import '../features/availability/presentation/screens/provider_availability_setup_screen.dart';
import '../features/events/domain/event_models.dart';
import '../features/events/presentation/screens/create_event_screen.dart';
import '../features/events/presentation/screens/event_detail_screen.dart';
import '../features/events/presentation/screens/pro_my_events_screen.dart';
import '../features/events/presentation/screens/scanner_screen.dart';
import '../features/events/presentation/screens/ticket_detail_screen.dart';
import '../features/events/presentation/screens/waitlist_screen.dart';
import '../features/client/presentation/search/client_search_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/feed/presentation/screens/my_videos_screen.dart';
import '../features/feed/presentation/screens/upload_video_screen.dart';
import '../features/pro/presentation/camera/video_capture_screen.dart';
import '../features/feed/presentation/screens/pro_search_screen.dart';
import '../features/pro/presentation/feed/pro_feed_screen.dart';
import '../features/profile/presentation/screens/pro_qr_code_screen.dart';
import '../features/events/presentation/screens/pro_scanner_event_picker_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/payment/presentation/screens/pro_subscription_screen.dart';
import '../features/payment/presentation/screens/stripe_checkout_webview.dart';
import '../features/profile/presentation/screens/client_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/pro_profile_screen.dart';
import '../features/profile/presentation/screens/pro_shell_profile_screen.dart';
import '../features/settings/presentation/screens/delete_account_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/moderation/presentation/screens/blocked_users_screen.dart';
import '../features/notifications/presentation/screens/notification_history_screen.dart';
import '../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../features/promo/presentation/screens/create_promo_code_screen.dart';
import '../features/promo/presentation/screens/referral_screen.dart';
import '../features/reviews/presentation/screens/review_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/social/presentation/screens/pro_insights_screen.dart';
import '../features/chat/presentation/screens/messaging_inbox_screen.dart';
import '../features/booking/presentation/screens/booking_flow_screen.dart';
import '../features/booking/presentation/screens/refund_request_screen.dart';
import '../features/events/presentation/screens/my_tickets_screen.dart';
import '../features/events/presentation/screens/client_events_discovery_screen.dart';
import '../features/favorites/presentation/screens/saved_posts_screen.dart';
import '../features/settings/presentation/screens/language_settings_screen.dart';
import '../features/payment/presentation/screens/payment_receipt_screen.dart';
import 'client_shell.dart';
import 'pro_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // ─── Non connecté ───
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/select-account-type',
      builder: (context, state) => const AccountTypeSelectionScreen(),
    ),
    GoRoute(
      path: '/signup/client',
      builder: (context, state) => const SignUpScreen(role: 'client'),
    ),
    GoRoute(
      path: '/signup/pro',
      builder: (context, state) => const SignUpScreen(role: 'pro'),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/forgot-password-confirmation',
      builder: (context, state) => const ForgotPasswordConfirmationScreen(),
    ),

    // ─── Post-inscription ───
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),

    // ─── Onboarding Client ───
    GoRoute(
      path: '/client/interests',
      builder: (context, state) => const ClientInterestCategoriesScreen(),
    ),
    GoRoute(
      path: '/client/goals',
      builder: (context, state) => const ClientInterestGoalsScreen(),
    ),
    GoRoute(
      path: '/client/location',
      builder: (context, state) => const PermissionLocationScreen(),
    ),

    // ─── Onboarding Pro ───
    GoRoute(
      path: '/pro/business-details',
      builder: (context, state) => const ProBusinessDetailsScreen(),
    ),
    GoRoute(
      path: '/pro/verification',
      builder: (context, state) => const ProVerificationScreen(),
    ),
    GoRoute(
      path: '/pro/stripe-connect',
      builder: (context, state) => const StripeConnectScreen(),
    ),
    GoRoute(
      path: '/pro/interests',
      builder: (context, state) => const ProInterestCategoriesScreen(),
    ),

    // ─── Client shell (BottomNav 4 tabs) ───
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ClientShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client/feed',
              builder: (context, state) => const FeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client/discover',
              builder: (context, state) => const ClientSearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client/bookings',
              builder: (context, state) => const MyBookingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client/profile',
              builder: (context, state) => const ClientProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // ─── Pro shell (Feed + Dashboard + FAB Camera + Search + RDV + Profile) ───
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ProShell(navigationShell: navigationShell),
      branches: [
        // 0 — Feed (TikTok-style, Pro-specific top bar + right column)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/feed',
              builder: (context, state) => const ProFeedScreen(),
            ),
          ],
        ),
        // 1 — Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/dashboard',
              builder: (context, state) => const ProDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/camera',
              builder: (context, state) => const VideoCaptureScreen(),
            ),
          ],
        ),
        // 3 — Search
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/search',
              builder: (context, state) => const ProSearchScreen(),
            ),
          ],
        ),
        // 4 — RDV
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/rdv',
              builder: (context, state) => const ProRdvScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/profile',
              builder: (context, state) => const ProShellProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // ─── Routes Pro (sub-screens) ───
    GoRoute(
      path: '/pro/services',
      builder: (context, state) => const ProServicesManageScreen(),
    ),
    GoRoute(
      path: '/pro/availability',
      builder: (context, state) => const ProviderAvailabilitySetupScreen(),
    ),
    GoRoute(
      path: '/pro/revenue',
      builder: (context, state) => const ProRevenueScreen(),
    ),
    GoRoute(
      path: '/pro/events',
      builder: (context, state) => const ProMyEventsScreen(),
    ),
    GoRoute(
      path: '/pro/qr-code',
      builder: (context, state) => const ProQrCodeScreen(),
    ),
    GoRoute(
      path: '/pro/scanner-picker',
      builder: (context, state) => const ProScannerEventPickerScreen(),
    ),
    GoRoute(
      path: '/pro/publish',
      builder: (context, state) =>
          VideoPreviewScreen(videoFile: state.extra! as File),
    ),

    // ─── Routes partagées (avec transitions 3D) ───
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/delete-account',
      builder: (context, state) => const DeleteAccountScreen(),
    ),
    GoRoute(
      path: '/my-videos',
      builder: (context, state) => const MyVideosScreen(),
    ),
    GoRoute(
      path: '/upload-video',
      builder: (context, state) => const UploadVideoScreen(),
    ),
    GoRoute(
      path: '/chat/:conversationId',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return FadeSlideTransitionPage(
          key: state.pageKey,
          child: ChatScreen(
            conversationId: state.pathParameters['conversationId'] ?? '',
            otherUserName: extra?['otherUserName'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationHistoryScreen(),
    ),
    GoRoute(
      path: '/notification-settings',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: const EditProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/:proId',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: ProProfileScreen(
          proId: state.pathParameters['proId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/event/:eventId',
      pageBuilder: (context, state) => DepthTransitionPage(
        key: state.pageKey,
        child: EventDetailScreen(
          eventId: state.pathParameters['eventId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/create-event',
      builder: (context, state) => const CreateEventScreen(),
    ),
    GoRoute(
      path: '/ticket-detail',
      pageBuilder: (context, state) => ScaleRotateTransitionPage(
        key: state.pageKey,
        child: TicketDetailScreen(ticket: state.extra! as TicketModel),
      ),
    ),
    GoRoute(
      path: '/scanner/:eventId',
      builder: (context, state) => ScannerScreen(
        eventId: state.pathParameters['eventId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/waitlist',
      builder: (context, state) {
        final args = state.extra! as Map<String, String>;
        return WaitlistScreen(
          ticketTypeId: args['ticketTypeId']!,
          eventTitle: args['eventTitle']!,
        );
      },
    ),
    GoRoute(
      path: '/booking/:bookingId',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: BookingDetailScreen(
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/cancel-booking/:bookingId',
      builder: (context, state) => BookingCancellationScreen(
        bookingId: state.pathParameters['bookingId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/pro-subscription',
      builder: (context, state) => const ProSubscriptionScreen(),
    ),
    GoRoute(
      path: '/subscription-checkout',
      builder: (context, state) =>
          StripeCheckoutWebview(url: state.extra as String? ?? ''),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) {
        final args = state.extra! as Map<String, String>;
        return ReviewScreen(
          bookingId: args['bookingId']!,
          proId: args['proId']!,
          serviceName: args['serviceName'],
        );
      },
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/promo-codes',
      builder: (context, state) => const CreatePromoCodeScreen(),
    ),
    GoRoute(
      path: '/referral',
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: '/blocked-users',
      builder: (context, state) => const BlockedUsersScreen(),
    ),
    GoRoute(
      path: '/pro-insights',
      builder: (context, state) => const ProInsightsScreen(),
    ),

    // ─── Routes Client (sub-screens) ───
    GoRoute(
      path: '/client/messages',
      builder: (context, state) =>
          const MessagingInboxScreen(isProShell: false),
    ),
    GoRoute(
      path: '/client/booking-flow/:proId',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: BookingFlowScreen(
          providerId: state.pathParameters['proId'] ?? '',
          initialServiceId: state.uri.queryParameters['serviceId'],
        ),
      ),
    ),
    GoRoute(
      path: '/client/events',
      pageBuilder: (context, state) => FadeSlideTransitionPage(
        key: state.pageKey,
        child: const ClientEventsDiscoveryScreen(),
      ),
    ),
    GoRoute(
      path: '/client/tickets',
      builder: (context, state) => const MyTicketsScreen(),
    ),

    // ─── Route Pro messages ───
    GoRoute(
      path: '/pro/messages',
      builder: (context, state) =>
          const MessagingInboxScreen(isProShell: true),
    ),

    // ─── Routes partagées supplémentaires ───
    GoRoute(
      path: '/refund/:bookingId',
      builder: (context, state) => RefundRequestScreen(
        bookingId: state.pathParameters['bookingId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/saved-posts',
      builder: (context, state) => const SavedPostsScreen(),
    ),
    GoRoute(
      path: '/language-settings',
      builder: (context, state) => const LanguageSettingsScreen(),
    ),
    GoRoute(
      path: '/payment-receipt/:bookingId',
      builder: (context, state) => PaymentReceiptScreen(
        bookingId: state.pathParameters['bookingId'] ?? '',
      ),
    ),
  ],
);
