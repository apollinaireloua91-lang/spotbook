import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/animations/premium_transitions.dart';

import '../features/pro/presentation/camera/video_capture_screen.dart';
import '../features/pro/presentation/camera/video_preview_screen.dart';
import '../features/feed/presentation/screens/provider_video_publish_screen.dart';
import '../features/auth/presentation/screens/account_type_selection_screen.dart';
import '../features/auth/presentation/screens/become_pro_setup_screen.dart';
import '../features/auth/presentation/screens/client_interest_categories_screen.dart';
import '../features/auth/presentation/screens/client_interest_goals_screen.dart';
import '../features/auth/presentation/screens/complete_profile_screen.dart';
import '../features/auth/presentation/screens/forgot_password_confirmation_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/permission_location_screen.dart';
import '../features/auth/presentation/screens/pro_interest_categories_screen.dart';
import '../features/auth/presentation/screens/pro_business_details_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/stripe_connect_screen.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/booking/presentation/screens/booking_cancellation_screen.dart';
import '../features/booking/presentation/screens/booking_detail_screen.dart';
import '../features/booking/presentation/screens/my_bookings_screen.dart';
import '../features/booking/presentation/screens/pro_dashboard_screen.dart';
import '../features/booking/presentation/screens/pro_rdv_screen.dart';
import '../features/booking/presentation/screens/booking_flow_v2_screen.dart';
import '../features/payment/presentation/screens/get_paid_faster_screen.dart';
import '../features/squire/presentation/screens/walk_in_queue_screen.dart';
import '../features/squire/presentation/screens/loyalty_screen.dart';
import '../features/squire/presentation/screens/referral_screen.dart';
import '../features/squire/presentation/screens/my_receipts_screen.dart';
import '../features/booking/presentation/screens/pro_service_addons_screen.dart';
import '../features/booking/presentation/screens/pro_services_manage_screen.dart';
import '../features/booking/presentation/screens/pro_revenue_screen.dart';
import '../features/availability/presentation/screens/provider_availability_setup_screen.dart';
import '../features/events/domain/event_models.dart';
import '../features/events/presentation/screens/create_event_screen.dart';
import '../features/events/presentation/screens/event_detail_screen.dart';
import '../features/events/presentation/screens/pro_my_events_screen.dart';
import '../features/events/presentation/screens/scanner_screen.dart';
import '../features/scanner/presentation/screens/unified_scanner_screen.dart';
import '../features/scanner/presentation/screens/unified_scan_result_screen.dart';
import '../features/events/presentation/screens/ticket_detail_screen.dart';
import '../features/events/presentation/screens/waitlist_screen.dart';
import '../features/client/presentation/search/client_search_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/feed/presentation/screens/my_videos_screen.dart';
import '../features/feed/presentation/screens/upload_video_screen.dart';
import '../features/feed/presentation/screens/pro_search_screen.dart';
import '../features/pro/presentation/feed/pro_feed_screen.dart';
import '../features/profile/presentation/screens/pro_qr_code_screen.dart';
import '../features/events/presentation/screens/pro_scanner_event_picker_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/client_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/pro_profile_screen.dart';
import '../features/profile/presentation/screens/pro_shell_profile_screen.dart';
import '../features/settings/presentation/screens/delete_account_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/chat/presentation/screens/pro_quick_replies_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/moderation/presentation/screens/blocked_users_screen.dart';
import '../features/notifications/presentation/screens/notification_history_screen.dart';
import '../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../features/promo/presentation/screens/create_promo_code_screen.dart';
import '../features/promo/presentation/screens/referral_screen.dart';
import '../features/reviews/presentation/screens/client_reviews_inbox_screen.dart';
import '../features/reviews/presentation/screens/review_screen.dart';
import '../features/settings/presentation/screens/cancellation_policy_screen.dart';
import '../features/settings/presentation/screens/commissions_screen.dart';
import '../features/settings/presentation/screens/deposit_settings_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/social/presentation/screens/pro_insights_screen.dart';
import '../features/chat/presentation/screens/messaging_inbox_screen.dart';
import '../features/booking/presentation/screens/refund_request_screen.dart';
import '../features/events/presentation/screens/my_tickets_screen.dart';
import '../features/events/presentation/screens/client_events_discovery_screen.dart';
import '../features/favorites/presentation/screens/saved_posts_screen.dart';
import '../features/settings/presentation/screens/language_settings_screen.dart';
import '../features/payment/presentation/screens/payment_receipt_screen.dart';
import '../features/payment/presentation/screens/provider_payout_history_screen.dart';
import '../features/profile/presentation/screens/provider_settings_screen.dart';
import '../features/soumission/presentation/screens/soumissions_list_screen.dart';
import '../features/soumission/presentation/screens/create_soumission_screen.dart';
import '../features/pos/domain/pos_models.dart';
import '../features/pos/presentation/pages/pos_amount_page.dart';
import '../features/pos/presentation/pages/pos_error_page.dart';
import '../features/pos/presentation/pages/pos_history_page.dart';
import '../features/pos/presentation/pages/pos_reader_page.dart';
import '../features/pos/presentation/pages/pos_success_page.dart';
import '../features/pos/presentation/pages/pos_transaction_detail_page.dart';
import '../features/profile/presentation/screens/provider_public_profile_client_view_screen.dart';
import '../features/profile/presentation/bloc/public_provider_profile_bloc.dart';
import '../features/profile/data/datasources/provider_profile_remote_datasource.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/chat/data/chat_repository.dart';
import 'client_shell.dart';
import 'pro_shell.dart';

/// Routes that don't require authentication.
const _publicPaths = <String>{
  '/',
  '/onboarding',
  '/login',
  '/select-account-type',
  '/signup/client',
  '/signup/pro',
  '/forgot-password',
  '/forgot-password-confirmation',
  '/reset-password',
};

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final path = state.matchedLocation;

    // Allow public routes without a session.
    if (_publicPaths.contains(path)) {
      // If user IS authenticated and tries to visit login/signup → redirect.
      if (session != null && (path == '/login' || path.startsWith('/signup'))) {
        final role = Supabase.instance.client.auth.currentUser
                ?.userMetadata?['role'] as String?;
        return role == 'pro' ? '/pro/feed' : '/client/feed';
      }
      return null;
    }

    // Onboarding post-signup paths (complete-profile, interests, location, etc.)
    // are allowed if there's a session even though profile may be incomplete.
    final onboardingPaths = <String>{
      '/complete-profile',
      '/client/interests',
      '/client/goals',
      '/client/location',
      '/pro/business-details',
      '/pro/interests',
      '/become-pro',
    };
    if (onboardingPaths.contains(path)) {
      if (session == null) return '/login';
      return null;
    }

    // All other routes require an active session.
    if (session == null) return '/login';

    return null; // Allow navigation.
  },
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
      builder: (context, state) => ForgotPasswordConfirmationScreen(
        email: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),

    // ─── Post-inscription ───
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),

    // ─── Become Pro (client → pro upgrade) ───
    GoRoute(
      path: '/become-pro',
      pageBuilder: (context, state) => premiumSlideUpPage(
        state: state,
        child: const BecomeProSetupScreen(),
      ),
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

    // ─── Pro shell (Feed + Dashboard + Search + RDV + Profile) ───
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ProShell(navigationShell: navigationShell),
      branches: [
        // 0 — Feed
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
        // 2 — Search
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/search',
              builder: (context, state) => const ProSearchScreen(),
            ),
          ],
        ),
        // 3 — RDV
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/rdv',
              builder: (context, state) => const ProRdvScreen(),
            ),
          ],
        ),
        // 4 — Profile
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
    GoRoute(
      path: '/pro/services',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ProServicesManageScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/get-paid-faster',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const GetPaidFasterScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/walk-in-queue',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const WalkInQueueScreen(),
      ),
    ),

    // ─── POS (Tap to Pay) ────────────────────────────────────────────────
    GoRoute(
      path: '/pro/pos/amount',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const PosAmountPage(),
      ),
    ),
    GoRoute(
      path: '/pro/pos/reader',
      pageBuilder: (context, state) {
        // PosAmount is the primary extra; fall back to an empty amount so
        // the reader opens in idle rather than hard-crashing if the user
        // deep-links here without going through amount entry.
        final extra = state.extra;
        final amount = extra is PosAmount ? extra : const PosAmount();
        return premiumPage(
          state: state,
          child: PosReaderPage(amount: amount),
        );
      },
    ),
    GoRoute(
      path: '/pro/pos/success',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final map = extra is Map<String, Object?> ? extra : const {};
        final amount = map['amount'] is PosAmount
            ? map['amount'] as PosAmount
            : const PosAmount();
        final result =
            map['result'] is PosPaymentResult? ? map['result'] as PosPaymentResult? : null;
        return premiumPage(
          state: state,
          child: PosSuccessPage(amount: amount, result: result),
        );
      },
    ),
    GoRoute(
      path: '/pro/pos/error',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final map = extra is Map<String, Object?> ? extra : const {};
        final amount = map['amount'] is PosAmount
            ? map['amount'] as PosAmount
            : const PosAmount();
        final result =
            map['result'] is PosPaymentResult? ? map['result'] as PosPaymentResult? : null;
        return premiumPage(
          state: state,
          child: PosErrorPage(amount: amount, result: result),
        );
      },
    ),
    GoRoute(
      path: '/pro/pos/history',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const PosHistoryPage(),
      ),
    ),
    GoRoute(
      path: '/pro/pos/transaction/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return premiumPage(
          state: state,
          child: PosTransactionDetailPage(transactionId: id),
        );
      },
    ),
    GoRoute(
      path: '/pro/loyalty',
      pageBuilder: (context, state) {
        final proId = state.uri.queryParameters['proId'] ?? '';
        return premiumPage(
          state: state,
          child: LoyaltyProgramScreen(proId: proId),
        );
      },
    ),
    GoRoute(
      path: '/client/referrals-squire',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const SquireReferralScreen(),
      ),
    ),
    GoRoute(
      path: '/client/receipts',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const MyReceiptsScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/services/:serviceId/addons',
      pageBuilder: (context, state) {
        final serviceId = state.pathParameters['serviceId']!;
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return premiumPage(
          state: state,
          child: ProServiceAddonsScreen(
            serviceId: serviceId,
            serviceName: extra['serviceName'] as String? ?? 'Service',
            currency: extra['currency'] as String? ?? 'CAD',
            proId: extra['proId'] as String? ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/pro/availability',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ProviderAvailabilitySetupScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/revenue',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ProRevenueScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/events',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ProMyEventsScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/qr-code',
      pageBuilder: (context, state) => premiumFadePage(
        state: state,
        child: const ProQrCodeScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/scanner-picker',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ProScannerEventPickerScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/scanner-unified',
      pageBuilder: (context, state) => premiumFadePage(
        state: state,
        child: UnifiedScannerScreen(
          eventId: state.uri.queryParameters['eventId'],
        ),
      ),
    ),
    GoRoute(
      path: '/pro/scanner/result',
      pageBuilder: (context, state) => premiumFadePage(
        state: state,
        child: UnifiedScanResultScreen(
          result: state.extra! as UnifiedScanResult,
        ),
      ),
    ),
    GoRoute(
      path: '/pro/publish',
      pageBuilder: (context, state) => premiumSlideUpPage(
        state: state,
        child: VideoPreviewScreen(videoFile: state.extra! as File),
      ),
    ),
    GoRoute(
      path: '/pro/camera',
      pageBuilder: (context, state) => premiumSlideUpPage(
        state: state,
        child: const VideoCaptureScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/video/publish',
      pageBuilder: (context, state) => premiumSlideUpPage(
        state: state,
        child: ProviderVideoPublishScreen(
          editData: state.extra as Map<String, dynamic>?,
        ),
      ),
    ),

    // ─── Pro Settings sub-screens ───
    GoRoute(
      path: '/pro/settings/cancellation',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const CancellationPolicyScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/settings/deposit',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const DepositSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/settings/commissions',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const CommissionsScreen(),
      ),
    ),

    // ─── Routes partagées — premium transitions ───
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/change-password',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ChangePasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/delete-account',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const DeleteAccountScreen(),
      ),
    ),
    GoRoute(
      path: '/my-videos',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const MyVideosScreen(),
      ),
    ),
    GoRoute(
      path: '/upload-video',
      pageBuilder: (context, state) => premiumSlideUpPage(
        state: state,
        child: const UploadVideoScreen(),
      ),
    ),

    // ── Soumissions (quotes) ──
    GoRoute(
      path: '/pro/soumissions',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const SoumissionsListScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/soumissions/create',
      pageBuilder: (context, state) => premiumSlideUpPage(
        state: state,
        child: const CreateSoumissionScreen(),
      ),
    ),

    GoRoute(
      path: '/chat/:conversationId',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, String?>?;
        return premiumPage(
          state: state,
          child: ChatScreen(
            conversationId: state.pathParameters['conversationId'] ?? '',
            otherUserName: extra?['otherUserName'],
            otherUserAvatar: extra?['otherUserAvatar'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const NotificationHistoryScreen(),
      ),
    ),
    GoRoute(
      path: '/notification-settings',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const NotificationSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const EditProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/messages',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const MessagingInboxScreen(isProShell: true),
      ),
    ),
    GoRoute(
      path: '/pro/:proId',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: ProProfileScreen(
          proId: state.pathParameters['proId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/event/:eventId',
      pageBuilder: (context, state) => premiumSlideUpPage(
        state: state,
        child: EventDetailScreen(
          eventId: state.pathParameters['eventId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/create-event',
      pageBuilder: (context, state) => premiumSlideUpPage(
        state: state,
        child: const CreateEventScreen(),
      ),
    ),
    GoRoute(
      path: '/ticket-detail',
      pageBuilder: (context, state) => premiumFadePage(
        state: state,
        child: TicketDetailScreen(ticket: state.extra! as TicketModel),
      ),
    ),
    GoRoute(
      path: '/scanner/:eventId',
      pageBuilder: (context, state) => premiumFadePage(
        state: state,
        child: ScannerScreen(
          eventId: state.pathParameters['eventId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/waitlist',
      pageBuilder: (context, state) {
        final args = state.extra! as Map<String, String>;
        return premiumPage(
          state: state,
          child: WaitlistScreen(
            ticketTypeId: args['ticketTypeId']!,
            eventTitle: args['eventTitle']!,
          ),
        );
      },
    ),
    GoRoute(
      path: '/booking/:bookingId',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: BookingDetailScreen(
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/cancel-booking/:bookingId',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: BookingCancellationScreen(
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/review',
      redirect: (context, state) {
        // /review requires Map<String,String> extras with bookingId + proId.
        // If navigated to without valid args (e.g. state restoration after
        // cold start — GoRouter can't persist `extra`), fall back to
        // bookings list instead of crashing with a null-check error.
        final extra = state.extra;
        if (extra is! Map<String, String> ||
            extra['bookingId'] == null ||
            extra['proId'] == null) {
          return '/client/bookings';
        }
        return null;
      },
      pageBuilder: (context, state) {
        final args = state.extra! as Map<String, String>;
        return premiumSlideUpPage(
          state: state,
          child: ReviewScreen(
            bookingId: args['bookingId']!,
            proId: args['proId']!,
            serviceName: args['serviceName'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const FavoritesScreen(),
      ),
    ),
    GoRoute(
      path: '/client/reviews-inbox',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ClientReviewsInboxScreen(),
      ),
    ),
    GoRoute(
      path: '/promo-codes',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const CreatePromoCodeScreen(),
      ),
    ),
    GoRoute(
      path: '/referral',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ReferralScreen(),
      ),
    ),
    GoRoute(
      path: '/blocked-users',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const BlockedUsersScreen(),
      ),
    ),
    GoRoute(
      path: '/pro-insights',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ProInsightsScreen(),
      ),
    ),

    // ─── Routes Client (sub-screens) ───
    GoRoute(
      path: '/client/messages',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const MessagingInboxScreen(isProShell: false),
      ),
    ),
    GoRoute(
      path: '/client/booking-flow/:proId',
      pageBuilder: (context, state) => premiumSlideUpPage(
        state: state,
        child: BookingFlowV2Screen(
          providerId: state.pathParameters['proId'] ?? '',
          initialServiceId: state.uri.queryParameters['serviceId'],
        ),
      ),
    ),
    GoRoute(
      path: '/client/events',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ClientEventsDiscoveryScreen(),
      ),
    ),
    GoRoute(
      path: '/client/tickets',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const MyTicketsScreen(),
      ),
    ),
    GoRoute(
      path: '/client/provider/:proId',
      pageBuilder: (context, state) {
        final proId = state.pathParameters['proId'] ?? '';
        final supabase = Supabase.instance.client;
        return premiumPage(
          state: state,
          child: BlocProvider(
            create: (_) => PublicProviderProfileBloc(
              profileDatasource: ProviderProfileRemoteDatasource(supabase),
              profileRepository: ProfileRepository(supabase: supabase),
              chatRepository: ChatRepository(supabase: supabase),
              supabase: supabase,
            )..add(PublicProviderProfileStarted(proId)),
            child: const ProviderPublicProfileClientViewScreen(),
          ),
        );
      },
    ),

    // ─── Routes partagées supplémentaires ───
    GoRoute(
      path: '/refund/:bookingId',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: RefundRequestScreen(
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/saved-posts',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const SavedPostsScreen(),
      ),
    ),
    GoRoute(
      path: '/language-settings',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const LanguageSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/payment-receipt/:bookingId',
      pageBuilder: (context, state) => premiumFadePage(
        state: state,
        child: PaymentReceiptScreen(
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
    ),

    // ─── Pro routes ajoutées / alias ───────────────────────
    // Historique des payouts Stripe (câblé à l'écran existant).
    GoRoute(
      path: '/pro/payouts',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ProviderPayoutHistoryScreen(),
      ),
    ),
    // Paramètres Pro (écran distinct des settings Client).
    GoRoute(
      path: '/pro/settings',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ProviderSettingsScreen(),
      ),
    ),
    // Alias legacy : /pro/profile/settings → /pro/settings.
    GoRoute(
      path: '/pro/profile/settings',
      redirect: (_, __) => '/pro/settings',
    ),
    GoRoute(
      path: '/pro/profile/settings/change-password',
      redirect: (_, __) => '/change-password',
    ),
    GoRoute(
      path: '/pro/profile/settings/language',
      redirect: (_, __) => '/language-settings',
    ),
    GoRoute(
      path: '/pro/profile/edit',
      redirect: (_, __) => '/edit-profile',
    ),
    GoRoute(
      path: '/pro/profile/promo-codes',
      redirect: (_, __) => '/promo-codes',
    ),
    GoRoute(
      path: '/pro/profile/qr-code',
      redirect: (_, __) => '/pro/qr-code',
    ),
    GoRoute(
      path: '/pro/profile/notifications-settings',
      redirect: (_, __) => '/notification-settings',
    ),
    GoRoute(
      path: '/pro/analytics',
      redirect: (_, __) => '/pro-insights',
    ),
    GoRoute(
      path: '/pro/quick-replies',
      pageBuilder: (context, state) => premiumPage(
        state: state,
        child: const ProQuickRepliesScreen(),
      ),
    ),
    // "Toutes mes réservations" depuis le hub calendrier.
    GoRoute(
      path: '/pro/calendar/bookings',
      redirect: (_, __) => '/pro/rdv',
    ),
    GoRoute(
      path: '/pro/calendar/bookings/:bookingId',
      redirect: (_, state) =>
          '/booking/${state.pathParameters['bookingId']}',
    ),
    // Alias legacy auth path utilisé depuis le profil pro public.
    GoRoute(
      path: '/auth/login',
      redirect: (_, __) => '/login',
    ),
    // Deep-link legacy : /client/booking/:serviceId/:proId
    // → /client/booking-flow/:proId?serviceId=:serviceId
    GoRoute(
      path: '/client/booking/:serviceId/:proId',
      redirect: (_, state) {
        final proId = state.pathParameters['proId'] ?? '';
        final serviceId = state.pathParameters['serviceId'] ?? '';
        return '/client/booking-flow/$proId?serviceId=$serviceId';
      },
    ),
  ],
  // Fallback explicite : évite l'écran blanc sur route invalide.
  errorBuilder: (context, state) => _RouterErrorScreen(error: state.error),
);

/// Écran de secours affiché lorsqu'une navigation pointe vers une
/// route non déclarée. Évite l'écran blanc silencieux.
class _RouterErrorScreen extends StatelessWidget {
  const _RouterErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Page introuvable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'Route inconnue',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFA0A0B8), fontSize: 13),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    GoRouter.of(context).go('/');
                  }
                },
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
