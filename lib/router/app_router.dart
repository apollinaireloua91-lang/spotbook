import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/client/presentation/feed/client_feed_screen.dart';
import '../features/client/presentation/feed/cubit/client_feed_cubit.dart';
import '../features/client/presentation/search/client_search_screen.dart';
import '../features/feed/data/video_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../shared/animations/page_transitions.dart';

import '../features/auth/presentation/screens/account_type_selection_screen.dart';
import '../features/auth/presentation/screens/client_interest_categories_screen.dart';
import '../features/auth/presentation/screens/client_interest_goals_screen.dart';
import '../features/auth/presentation/screens/complete_profile_screen.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/permission_location_screen.dart';
import '../features/auth/presentation/screens/pro_business_details_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/stripe_connect_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/forgot_password_confirmation_screen.dart';
import '../features/booking/presentation/screens/booking_cancellation_screen.dart';
import '../features/booking/presentation/screens/booking_detail_screen.dart';
import '../features/booking/presentation/screens/booking_flow_screen.dart';
import '../features/booking/presentation/screens/my_bookings_screen.dart';
import '../features/availability/presentation/screens/provider_availability_setup_screen.dart';
import '../features/booking/presentation/screens/pro_dashboard_screen.dart';
import '../features/booking/presentation/screens/pro_revenue_screen.dart';
import '../features/booking/presentation/screens/pro_services_manage_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/events/domain/event_models.dart';
import '../features/chat/presentation/screens/messaging_inbox_screen.dart';
import '../features/events/presentation/screens/create_event_screen.dart';
import '../features/events/presentation/screens/event_detail_screen.dart';
import '../features/events/presentation/screens/pro_event_sales_screen.dart';
import '../features/events/presentation/screens/pro_events_list_screen.dart';
import '../features/events/presentation/screens/pro_scanner_event_picker_screen.dart';
import '../features/events/presentation/screens/client_events_discovery_screen.dart';
import '../features/events/presentation/screens/my_tickets_screen.dart';
import '../features/events/presentation/screens/provider_attendees_list_screen.dart';
import '../features/events/presentation/screens/qr_scan_result_screen.dart';
import '../features/events/presentation/screens/scanner_screen.dart';
import '../features/events/presentation/screens/ticket_detail_screen.dart';
import '../features/events/presentation/screens/waitlist_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/booking/presentation/screens/provider_clients_list_screen.dart';
import '../features/feed/presentation/screens/client_video_detail_screen.dart';
import '../features/feed/presentation/screens/discover_search_map_screen.dart';
import '../features/feed/presentation/screens/discover_search_results_screen.dart';
import '../features/feed/presentation/screens/pro_feed_screen.dart';
import '../features/feed/presentation/screens/pro_search_screen.dart';
import '../features/feed/presentation/screens/my_videos_screen.dart';
import '../features/booking/presentation/screens/pro_rdv_screen.dart';
import '../features/feed/presentation/screens/provider_video_edit_screen.dart';
import '../features/feed/presentation/screens/provider_video_publish_screen.dart';
import '../features/feed/presentation/screens/upload_video_screen.dart';
import '../features/payment/presentation/screens/provider_payout_history_screen.dart';
import '../features/reviews/presentation/screens/provider_reviews_received_screen.dart';
import '../features/moderation/presentation/screens/blocked_users_screen.dart';
import '../features/notifications/presentation/screens/notification_history_screen.dart';
import '../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/payment/presentation/screens/pro_subscription_screen.dart';
import '../features/payment/presentation/screens/stripe_checkout_webview.dart';
import '../features/profile/domain/entities/provider_profile_data.dart';
import '../features/profile/presentation/screens/client_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/pro_profile_screen.dart';
import '../features/profile/presentation/screens/provider_public_video_screen.dart';
import '../features/profile/presentation/screens/provider_settings_screen.dart';
import '../features/profile/presentation/screens/pro_qr_code_screen.dart';
import '../features/payment/presentation/screens/payment_receipt_screen.dart';
import '../features/promo/presentation/screens/create_promo_code_screen.dart';
import '../features/promo/presentation/screens/referral_screen.dart';
import '../features/booking/presentation/screens/refund_request_screen.dart';
import '../features/favorites/presentation/screens/saved_posts_screen.dart';
import '../features/reviews/presentation/screens/review_screen.dart';
import '../features/settings/presentation/screens/delete_account_screen.dart';
import '../features/settings/presentation/screens/language_settings_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/social/presentation/screens/pro_insights_screen.dart';
import '../shared/widgets/placeholder_screen.dart';
import 'client_shell.dart';
import 'pro_shell.dart';

/// Clé racine pour les routes plein écran (hors shell) si besoin futur.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

String? _legacyRedirect(GoRouterState state) {
  final path = state.uri.path;
  if (path == '/client/feed') return '/client';
  if (path == '/client/search') return '/client/discover';
  if (path.startsWith('/client/pro/')) {
    final id = path.substring('/client/pro/'.length);
    if (id.isNotEmpty && !id.contains('/')) {
      return '/client/provider/$id';
    }
  }
  if (path.startsWith('/client/ticket/')) {
    final id = path.substring('/client/ticket/'.length);
    if (id.isNotEmpty && !id.contains('/')) {
      return '/client/ticket-purchase/$id';
    }
  }
  if (path == '/pro/feed') return '/pro';
  if (path == '/pro/appointments') return '/pro/calendar';
  if (path == '/pro/bookings') return '/pro/calendar';
  if (path == '/login') return '/auth/login';
  return null;
}

/// Paths that don't require authentication.
const _publicPaths = {
  '/splash',
  '/onboarding',
  '/auth/login',
  '/signup',
  '/forgot-password',
  '/forgot-password-confirmation',
  '/account-type',
  '/complete-profile',
  '/',
};

String? _authAndRoleGuard(BuildContext context, GoRouterState state) {
  // Legacy redirects first
  final legacy = _legacyRedirect(state);
  if (legacy != null) return legacy;

  final path = state.uri.path;

  // Allow public paths through
  if (_publicPaths.contains(path)) return null;

  // Check authentication
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return '/auth/login';

  // Check role-based routing
  final user = Supabase.instance.client.auth.currentUser;
  final role = user?.userMetadata?['role'] as String?;

  if (path.startsWith('/pro') && role == 'client') return '/client';
  if (path.startsWith('/client') && role == 'pro') return '/pro';

  return null;
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) => _authAndRoleGuard(context, state),
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      redirect: (_, __) => '/splash',
    ),

    // ─── Onboarding & auth (chemins historiques + /auth/login) ───
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/account-type',
      builder: (context, state) => const AccountTypeSelectionScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) =>
          SignUpScreen(initialRole: state.extra as String?),
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/auth/forgot-password-confirmation',
      builder: (context, state) =>
          const ForgotPasswordConfirmationScreen(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),

    // ─── Post-inscription client / pro ───
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
    GoRoute(
      path: '/pro/business-details',
      builder: (context, state) => const ProBusinessDetailsScreen(),
    ),
    GoRoute(
      path: '/pro/verification',
      redirect: (_, __) => '/pro/stripe-connect',
    ),
    GoRoute(
      path: '/pro/stripe-connect',
      builder: (context, state) => const StripeConnectScreen(),
    ),

    // ─── Client : routes plein écran (hors bottom nav) ───
    GoRoute(
      path: '/client/provider/:providerId',
      pageBuilder: (context, state) {
        final id = state.pathParameters['providerId'] ?? '';
        return fadeSlideTransitionPage(
          key: state.pageKey,
          child: ProProfileScreen(
            proId: id,
            showOwnerTools: false,
          ),
        );
      },
    ),
    GoRoute(
      path: '/client/profile-video',
      builder: (context, state) {
        final v = state.extra as VideoEntity?;
        if (v == null) {
          return const PlaceholderScreen(title: 'Vidéo introuvable');
        }
        return ProviderPublicVideoScreen(video: v);
      },
    ),
    GoRoute(
      path: '/client/booking-flow/:providerId',
      pageBuilder: (context, state) => slideUpTransitionPage(
        key: state.pageKey,
        child: BookingFlowScreen(
          providerId: state.pathParameters['providerId'] ?? '',
          initialServiceId: state.uri.queryParameters['serviceId'],
        ),
      ),
    ),
    GoRoute(
      path: '/client/booking/:serviceId/:proId',
      builder: (context, state) => BookingFlowScreen(
        providerId: state.pathParameters['proId'] ?? '',
        initialServiceId: state.pathParameters['serviceId'],
      ),
    ),
    GoRoute(
      path: '/client/event/:eventId',
      pageBuilder: (context, state) => fadeSlideTransitionPage(
        key: state.pageKey,
        child: EventDetailScreen(
          eventId: state.pathParameters['eventId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/client/ticket-purchase/:eventId',
      pageBuilder: (context, state) => slideUpTransitionPage(
        key: state.pageKey,
        child: EventDetailScreen(
          eventId: state.pathParameters['eventId'] ?? '',
          openPurchaseFlow: true,
        ),
      ),
    ),
    GoRoute(
      path: '/client/messages',
      builder: (context, state) =>
          const MessagingInboxScreen(isProShell: false),
    ),
    GoRoute(
      path: '/client/messages/:conversationId',
      pageBuilder: (context, state) => fadeSlideTransitionPage(
        key: state.pageKey,
        child: ChatScreen(
          conversationId: state.pathParameters['conversationId'] ?? '',
          otherUserName:
              (state.extra as Map<String, String>?)?['otherUserName'],
        ),
      ),
    ),
    GoRoute(
      path: '/client/notifications',
      pageBuilder: (context, state) => fadeSlideTransitionPage(
        key: state.pageKey,
        child: const NotificationHistoryScreen(),
      ),
    ),

    // ─── Pro : hors shell ───
    GoRoute(
      path: '/pro/events',
      builder: (context, state) => const ProEventsListScreen(),
    ),
    GoRoute(
      path: '/pro/events/create',
      pageBuilder: (context, state) => slideUpTransitionPage(
        key: state.pageKey,
        child: const CreateEventScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/events/:eventId/edit',
      builder: (context, state) => CreateEventScreen(
        eventId: state.pathParameters['eventId'],
      ),
    ),
    GoRoute(
      path: '/pro/events/:eventId/attendees',
      builder: (context, state) => ProviderAttendeesListScreen(
        eventId: state.pathParameters['eventId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/pro/events/:eventId/sales',
      builder: (context, state) => ProEventSalesScreen(
        eventId: state.pathParameters['eventId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/pro/video/edit',
      builder: (context, state) {
        final path = state.extra as String? ?? '';
        return ProviderVideoEditScreen(videoPath: path);
      },
    ),
    GoRoute(
      path: '/pro/video/publish',
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return slideUpTransitionPage(
          key: state.pageKey,
          child: ProviderVideoPublishScreen(editData: data),
        );
      },
    ),
    GoRoute(
      path: '/pro/messages',
      builder: (context, state) =>
          const MessagingInboxScreen(isProShell: true),
    ),
    GoRoute(
      path: '/pro/messages/:conversationId',
      builder: (context, state) => ChatScreen(
        conversationId: state.pathParameters['conversationId'] ?? '',
        otherUserName:
            (state.extra as Map<String, String>?)?['otherUserName'],
      ),
    ),
    GoRoute(
      path: '/pro/notifications',
      builder: (context, state) => const NotificationHistoryScreen(),
    ),
    GoRoute(
      path: '/pro/scanner',
      pageBuilder: (context, state) => slideUpTransitionPage(
        key: state.pageKey,
        child: const ProScannerEventPickerScreen(),
      ),
    ),
    GoRoute(
      path: '/pro/scanner/result',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final result = extra?['result'] as ScanResult? ??
            const ScanResult(valid: false, reason: 'unknown');
        final eventId = extra?['eventId'] as String? ?? '';
        return scaleTransitionPage(
          key: state.pageKey,
          child: QrScanResultScreen(result: result, eventId: eventId),
        );
      },
    ),
    GoRoute(
      path: '/pro/stripe-setup',
      builder: (context, state) => const StripeConnectScreen(),
    ),
    GoRoute(
      path: '/pro/revenue',
      builder: (context, state) => const ProRevenueScreen(),
    ),
    GoRoute(
      path: '/pro/analytics',
      builder: (context, state) => const ProInsightsScreen(),
    ),
    GoRoute(
      path: '/pro/clients',
      builder: (context, state) =>
          const ProviderClientsListScreen(),
    ),
    GoRoute(
      path: '/pro/payouts',
      builder: (context, state) => const ProviderPayoutHistoryScreen(),
    ),
    GoRoute(
      path: '/pro/profile/reviews',
      builder: (context, state) => const ProviderReviewsReceivedScreen(),
    ),
    GoRoute(
      path: '/pro/profile/notifications-settings',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/pro/profile/qr-code',
      builder: (context, state) => const ProQrCodeScreen(),
    ),

    // ─── Client shell (4 onglets) ───
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ClientShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client',
              builder: (context, state) {
                final client = Supabase.instance.client;
                return BlocProvider(
                  create: (_) => ClientFeedCubit(
                    videoRepository: VideoRepository(supabase: client),
                    notificationRepository:
                        NotificationRepository(supabase: client),
                  ),
                  child: const ClientFeedScreen(),
                );
              },
              routes: [
                GoRoute(
                  path: 'video/:videoId',
                  builder: (context, state) => ClientVideoDetailScreen(
                    videoId: state.pathParameters['videoId'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client/discover',
              builder: (context, state) => const ClientSearchScreen(),
              routes: [
                GoRoute(
                  path: 'results',
                  builder: (context, state) =>
                      const DiscoverSearchResultsScreen(),
                ),
                GoRoute(
                  path: 'map',
                  builder: (context, state) =>
                      const DiscoverSearchMapScreen(),
                ),
                GoRoute(
                  path: 'events',
                  builder: (context, state) => const ClientEventsDiscoveryScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client/bookings',
              builder: (context, state) => const MyBookingsScreen(),
              routes: [
                GoRoute(
                  path: 'tickets',
                  builder: (context, state) => const MyTicketsScreen(),
                ),
                GoRoute(
                  path: ':bookingId',
                  builder: (context, state) => BookingDetailScreen(
                    bookingId: state.pathParameters['bookingId'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client/profile',
              builder: (context, state) => ClientProfileScreen(
                profileUserKey: state.uri.queryParameters['id'] ?? '',
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const EditProfileScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'change-password',
                      builder: (context, state) =>
                          const ChangePasswordScreen(),
                    ),
                    GoRoute(
                      path: 'language',
                      builder: (context, state) =>
                          const LanguageSettingsScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'favorites',
                  builder: (context, state) => const FavoritesScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ─── Pro shell (5 onglets — Feed d’abord, pas d’onglet Événements) ───
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ProShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro',
              builder: (context, state) => const ProFeedScreen(),
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const ProDashboardScreen(),
                ),
                GoRoute(
                  path: 'video/:videoId',
                  redirect: (_, __) => '/pro',
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/search',
              builder: (context, state) => const ProSearchScreen(),
              routes: [
                GoRoute(
                  path: 'results',
                  builder: (context, state) =>
                      const DiscoverSearchResultsScreen(),
                ),
                GoRoute(
                  path: 'map',
                  builder: (context, state) =>
                      const DiscoverSearchMapScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/camera',
              builder: (context, state) => const UploadVideoScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/calendar',
              builder: (context, state) => const ProRdvScreen(),
              routes: [
                GoRoute(
                  path: 'bookings',
                  builder: (context, state) =>
                      const MyBookingsScreen(forPro: true),
                  routes: [
                    GoRoute(
                      path: ':bookingId',
                      builder: (context, state) => BookingDetailScreen(
                        bookingId: state.pathParameters['bookingId'] ?? '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/profile',
              builder: (context, state) {
                final uid = Supabase.instance.client.auth.currentUser?.id;
                if (uid == null) {
                  return const PlaceholderScreen(title: 'Profil Pro');
                }
                return ProProfileScreen(proId: uid);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const EditProfileScreen(),
                ),
                GoRoute(
                  path: 'services',
                  builder: (context, state) =>
                      const ProServicesManageScreen(),
                ),
                GoRoute(
                  path: 'availability',
                  builder: (context, state) =>
                      const ProviderAvailabilitySetupScreen(),
                ),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const ProviderSettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'change-password',
                      builder: (context, state) =>
                          const ChangePasswordScreen(),
                    ),
                    GoRoute(
                      path: 'language',
                      builder: (context, state) =>
                          const LanguageSettingsScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'promo-codes',
                  builder: (context, state) =>
                      const CreatePromoCodeScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ─── Routes partagées (compat) ───
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
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
      builder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return ChatScreen(
          conversationId: state.pathParameters['conversationId'] ?? '',
          otherUserName: extra?['otherUserName'],
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
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/event/:eventId',
      redirect: (context, state) =>
          '/client/event/${state.pathParameters['eventId']}',
    ),
    GoRoute(
      path: '/create-event',
      builder: (context, state) => const CreateEventScreen(),
    ),
    GoRoute(
      path: '/ticket-detail',
      builder: (context, state) =>
          TicketDetailScreen(ticket: state.extra! as TicketModel),
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
      builder: (context, state) => BookingDetailScreen(
        bookingId: state.pathParameters['bookingId'] ?? '',
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
    GoRoute(
      path: '/refund/:bookingId',
      builder: (context, state) => RefundRequestScreen(
        bookingId: state.pathParameters['bookingId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/receipt/:bookingId',
      pageBuilder: (context, state) => scaleTransitionPage(
        key: state.pageKey,
        child: PaymentReceiptScreen(
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/saved-posts',
      builder: (context, state) => const SavedPostsScreen(),
    ),
  ],
);
