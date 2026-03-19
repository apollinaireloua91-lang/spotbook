import 'package:go_router/go_router.dart';

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
import '../features/feed/presentation/screens/discover_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/feed/presentation/screens/my_videos_screen.dart';
import '../features/feed/presentation/screens/upload_video_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/client_profile_screen.dart';
import '../features/settings/presentation/screens/delete_account_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
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
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'My Bookings'),
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

    // ─── Pro shell (BottomNav 5 tabs) ───
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ProShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/feed',
              builder: (context, state) => const FeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/discover',
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
              path: '/pro/bookings',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Bookings'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pro/dashboard',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Dashboard'),
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
      builder: (context, state) => PlaceholderScreen(
        title: 'Chat ${state.pathParameters['conversationId'] ?? ''}',
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) =>
          const PlaceholderScreen(title: 'Notifications'),
    ),
    GoRoute(
      path: '/pro/:proId',
      builder: (context, state) => PlaceholderScreen(
        title: 'Pro ${state.pathParameters['proId'] ?? ''}',
      ),
    ),
    GoRoute(
      path: '/event/:eventId',
      builder: (context, state) => PlaceholderScreen(
        title: 'Event ${state.pathParameters['eventId'] ?? ''}',
      ),
    ),
    GoRoute(
      path: '/booking/:bookingId',
      builder: (context, state) => PlaceholderScreen(
        title: 'Booking ${state.pathParameters['bookingId'] ?? ''}',
      ),
    ),
  ],
);
