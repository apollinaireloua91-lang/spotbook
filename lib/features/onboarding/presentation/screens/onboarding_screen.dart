import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_button.dart';

class _PageNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int page) => state = page;
}

final _onboardingPageProvider = NotifierProvider<_PageNotifier, int>(
  _PageNotifier.new,
  isAutoDispose: true,
);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final box = await Hive.openBox<bool>('settings');
    await box.put('onboarding_seen', true);
    if (!mounted) return;
    context.go('/account-type');
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(_onboardingPageProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 20),
                child: GestureDetector(
                  onTap: _complete,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: AppColors.gris, fontSize: 15),
                  ),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) =>
                    ref.read(_onboardingPageProvider.notifier).set(i),
                children: const [
                  _OnboardingSlide(
                    icon: Icons.play_circle_outline,
                    title: 'Watch. Discover. Book.',
                    subtitle:
                        'Explore local professionals through short videos. See their skills before you book.',
                  ),
                  _OnboardingSlide(
                    icon: Icons.calendar_month_outlined,
                    title: 'Book Services & Events',
                    subtitle:
                        'Connect with experts for 1:1 sessions or get tickets for live workshops directly in the app.',
                  ),
                  _OnboardingSlide(
                    icon: Icons.trending_up,
                    title: 'Create & Earn',
                    subtitle:
                        'Share your expertise through video, manage bookings, and sell event tickets.',
                  ),
                ],
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == page ? AppColors.blanc : AppColors.gris,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SpotbookButton.primary(
                label: page < 2 ? 'Suivant' : 'Get Started',
                onPressed: page < 2 ? _next : _complete,
              ),
            ),
            const SizedBox(height: 16),
            if (page == 2)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.go('/login');
                },
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(color: AppColors.blanc, fontSize: 14),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: AppColors.blanc),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gris,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
