import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/screens/account_type_selection_screen.dart';
import '../features/auth/presentation/screens/client_interest_categories_screen.dart';
import '../features/auth/presentation/screens/client_interest_goals_screen.dart';
import '../features/auth/presentation/screens/complete_profile_screen.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/permission_location_screen.dart';
import '../features/auth/presentation/screens/pro_business_details_screen.dart';
import '../features/auth/presentation/screens/pro_verification_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/stripe_connect_screen.dart';
import '../features/booking/presentation/screens/booking_cancellation_screen.dart';
import '../features/booking/presentation/screens/booking_detail_screen.dart';
import '../features/booking/presentation/screens/booking_flow_screen.dart';
import '../features/booking/presentation/screens/my_bookings_screen.dart';
import '../features/availability/presentation/screens/provider_availability_setup_screen.dart';
import '../features/booking/presentation/screens/pro_calendar_hub_screen.dart';
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
import '../features/events/presentation/screens/scanner_screen.dart';
import '../features/events/presentation/screens/ticket_detail_screen.dart';
import '../features/events/presentation/screens/waitlist_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/feed/presentation/screens/discover_screen.dart';
import '../features/feed/presentation/screens/discover_search_map_screen.dart';
import '../features/feed/presentation/screens/discover_search_results_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/feed/presentation/screens/my_videos_screen.dart';
import '../features/feed/presentation/screens/upload_video_screen.dart';
import '../features/moderation/presentation/screens/blocked_users_screen.dart';
import '../features/notifications/presentation/screens/notification_history_screen.dart';
import '../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/payment/presentation/screens/pro_subscription_screen.dart';
import '../features/payment/presentation/screens/stripe_checkout_webview.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/profile/data/datasources/provider_profile_remote_datasource.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/domain/entities/provider_profile_data.dart';
import '../features/profile/presentation/bloc/public_provider_profile_bloc.dart';
import '../features/profile/presentation/screens/client_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/pro_profile_screen.dart';
import '../features/profile/presentation/screens/provider_public_profile_client_view_screen.dart';
import '../features/profile/presentation/screens/provider_public_video_screen.dart';
import '../features/profile/presentation/screens/provider_settings_screen.dart';
import '../features/profile/presentation/screens/pro_qr_code_screen.dart';
import '../features/promo/presentation/screens/create_promo_code_screen.dart';
import '../features/promo/presentation/screens/referral_screen.dart';
import '../features/reviews/presentation/screens/review_screen.dart';
import '../features/settings/presentation/screens/delete_account_screen.dart';
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
  if (path == '/pro/feed') return '/pro';
  if (path == '/pro/appointments') return '/pro/calendar';
  if (path == '/pro/bookings') return '/pro/calendar';
  if (path == '/login') return '/auth/login';
  return null;
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) => _legacyRedirect(state),
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
      builder: (context, state) => const ProVerificationScreen(),
    ),
    GoRoute(
      path: '/pro/stripe-connect',
      builder: (context, state) => const StripeConnectScreen(),
    ),

    // ─── Client : routes plein écran (hors bottom nav) ───
    GoRoute(
      path: '/client/provider/:providerId',
      builder: (context, state) {
        final id = state.pathParameters['providerId'] ?? '';
        final client = Supabase.instance.client;
        return BlocProvider(
          create: (_) => PublicProviderProfileBloc(
            profileDatasource: ProviderProfileRemoteDatasource(client),
            profileRepository: ProfileRepository(supabase: client),
            chatRepository: ChatRepository(supabase: client),
            supabase: client,
          )..add(PublicProviderProfileStarted(id)),
          child: const ProviderPublicProfileClientViewScreen(),
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
      builder: (context, state) => BookingFlowScreen(
        providerId: state.pathParameters['providerId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/client/event/:eventId',
      builder: (context, state) => EventDetailScreen(
        eventId: state.pathParameters['eventId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/client/ticket-purchase/:eventId',
      builder: (context, state) => EventDetailScreen(
        eventId: state.pathParameters['eventId'] ?? '',
        openPurchaseFlow: true,
      ),
    ),
    GoRoute(
      path: '/client/messages',
      builder: (context, state) =>
          const MessagingInboxScreen(isProShell: false),
    ),
    GoRoute(
      path: '/client/messages/:conversationId',
      builder: (context, state) => ChatScreen(
        conversationId: state.pathParameters['conversationId'] ?? '',
        otherUserName:
            (state.extra as Map<String, String>?)?['otherUserName'],
      ),
    ),
    GoRoute(
      path: '/client/notifications',
      builder: (context, state) => const NotificationHistoryScreen(),
    ),

    // ─── Pro : hors shell ───
    GoRoute(
      path: '/pro/events',
      builder: (context, state) => const ProEventsListScreen(),
    ),
    GoRoute(
      path: '/pro/events/create',
      builder: (context, state) => const CreateEventScreen(),
    ),
    GoRoute(
      path: '/pro/events/:eventId/edit',
      builder: (context, state) => const CreateEventScreen(),
    ),
    GoRoute(
      path: '/pro/events/:eventId/attendees',
      builder: (context, state) => ScannerScreen(
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
      builder: (context, state) => const UploadVideoScreen(),
    ),
    GoRoute(
      path: '/pro/video/publish',
      builder: (context, state) => const UploadVideoScreen(),
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
      builder: (context, state) =>
          const ProScannerEventPickerScreen(),
    ),
    GoRoute(
      path: '/pro/scanner/result',
      redirect: (_, __) => '/pro/scanner',
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
          const MyBookingsScreen(forPro: true),
    ),
    GoRoute(
      path: '/pro/payouts',
      builder: (context, state) => const ProRevenueScreen(),
    ),
    GoRoute(
      path: '/pro/profile/reviews',
      builder: (context, state) => const ProInsightsScreen(),
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
              builder: (context, state) => const FeedScreen(),
              routes: [
                GoRoute(
                  path: 'video/:videoId',
                  redirect: (_, __) => '/client',
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/client/discover',
              builder: (context, state) => const DiscoverScreen(),
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
                  builder: (context, state) => const DiscoverScreen(),
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
                  builder: (context, state) => const MyBookingsScreen(),
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
              builder: (context, state) => const FeedScreen(),
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
              builder: (context, state) => const DiscoverScreen(),
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
              builder: (context, state) => const ProCalendarHubScreen(),
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
  ],
);
