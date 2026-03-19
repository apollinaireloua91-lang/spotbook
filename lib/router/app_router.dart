import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/screens/account_type_selection_screen.dart';
import '../features/auth/presentation/screens/client_interest_categories_screen.dart';
import '../features/auth/presentation/screens/client_interest_goals_screen.dart';
import '../features/auth/presentation/screens/complete_profile_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/permission_location_screen.dart';
import '../features/auth/presentation/screens/pro_business_details_screen.dart';
import '../features/auth/presentation/screens/pro_verification_screen.dart';
import '../features/auth/presentation/screens/sign_up_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/stripe_connect_screen.dart';
import '../features/booking/presentation/screens/booking_cancellation_screen.dart';
import '../features/booking/presentation/screens/my_bookings_screen.dart';
import '../features/booking/presentation/screens/pro_dashboard_screen.dart';
import '../features/events/domain/event_models.dart';
import '../features/events/presentation/screens/create_event_screen.dart';
import '../features/events/presentation/screens/event_detail_screen.dart';
import '../features/events/presentation/screens/scanner_screen.dart';
import '../features/events/presentation/screens/ticket_detail_screen.dart';
import '../features/events/presentation/screens/waitlist_screen.dart';
import '../features/feed/presentation/screens/discover_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/feed/presentation/screens/my_videos_screen.dart';
import '../features/feed/presentation/screens/upload_video_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/payment/presentation/screens/pro_subscription_screen.dart';
import '../features/payment/presentation/screens/stripe_checkout_webview.dart';
import '../features/profile/presentation/screens/client_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/pro_profile_screen.dart';
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
import '../shared/widgets/placeholder_screen.dart';
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
      path: '/account-type',
      builder: (context, state) => const AccountTypeSelectionScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) =>
          SignUpScreen(initialRole: state.extra as String?),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
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
              builder: (context, state) => const DiscoverScreen(),
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

    // ─── Pro shell (BottomNav 6 tabs) ───
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ProShell(navigationShell: navigationShell),
      branches: [
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
              path: '/pro/search',
              builder: (context, state) => const DiscoverScreen(),
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
              path: '/pro/appointments',
              builder: (context, state) => const MyBookingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/events',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Événements'),
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
            ),
          ],
        ),
      ],
    ),

    // ─── Routes partagées ───
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
      path: '/pro/:proId',
      builder: (context, state) => ProProfileScreen(
        proId: state.pathParameters['proId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/event/:eventId',
      builder: (context, state) => EventDetailScreen(
        eventId: state.pathParameters['eventId'] ?? '',
      ),
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
      builder: (context, state) => PlaceholderScreen(
        title: 'Booking ${state.pathParameters['bookingId'] ?? ''}',
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
