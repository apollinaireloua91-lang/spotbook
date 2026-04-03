import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../shared/theme/app_colors.dart';

class _OnboardingPageNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int page) => state = page;
}

final _onboardingPageProvider = NotifierProvider<_OnboardingPageNotifier, int>(
  _OnboardingPageNotifier.new,
  isAutoDispose: true,
);

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
}

const _slides = [
  _SlideData(
    icon: Icons.play_circle_fill_rounded,
    title: 'Découvrez',
    subtitle:
        'Découvrez les meilleurs professionnels près de chez vous grâce à des vidéos immersives.',
    gradientColors: [AppColors.violet, AppColors.violetClair],
  ),
  _SlideData(
    icon: Icons.calendar_month_rounded,
    title: 'Réservez',
    subtitle:
        'Réservez un service en quelques taps.\nPaiement sécurisé par Stripe.',
    gradientColors: [AppColors.rose, AppColors.roseClair],
  ),
  _SlideData(
    icon: Icons.confirmation_number_rounded,
    title: 'Vivez',
    subtitle:
        'Participez aux meilleurs événements de votre ville avec vos billets QR.',
    gradientColors: [AppColors.violet, AppColors.rose],
  ),
];

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
    HapticFeedback.mediumImpact();
    final box = Hive.box('settings');
    await box.put('onboarding_seen', true);
    if (!mounted) return;
    context.go('/select-account-type');
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    _controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(_onboardingPageProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: Column(
        children: [
          // Skip button
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 20),
                child: TextButton(
                  onPressed: _complete,
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: AppColors.gris,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Page view slides
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) =>
                  ref.read(_onboardingPageProvider.notifier).set(i),
              itemCount: _slides.length,
              itemBuilder: (context, index) =>
                  _OnboardingSlide(data: _slides[index]),
            ),
          ),

          // Dot indicators
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final isActive = i == currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: isActive ? AppColors.gradientAccent : null,
                    color: isActive ? null : AppColors.gris.withAlpha(60),
                  ),
                );
              }),
            ),
          ),

          // Action button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppColors.gradientAccent,
                ),
                child: ElevatedButton(
                  onPressed: currentPage < 2 ? _nextPage : _complete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: AppColors.blanc,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      currentPage < 2 ? 'Suivant' : 'Commencer',
                      key: ValueKey(currentPage < 2 ? 'next' : 'start'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon scene with gradient background
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.gradientColors[0].withAlpha(30),
                  data.gradientColors[1].withAlpha(15),
                ],
              ),
              border: Border.all(
                color: data.gradientColors[0].withAlpha(40),
                width: 1,
              ),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: data.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(rect),
                child: Icon(
                  data.icon,
                  size: 80,
                  color: AppColors.blanc,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gris.withAlpha(200),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
