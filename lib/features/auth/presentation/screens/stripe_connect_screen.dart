import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';

class StripeConnectScreen extends StatelessWidget {
  const StripeConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondDark,
      appBar: AppBar(
        backgroundColor: AppColors.fondDark,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
        title: const Text(
          'Configurer vos reversements',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Wallet icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.accent.withAlpha(26),
                  border: Border.all(
                    color: AppColors.accent.withAlpha(51),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.accent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Via Stripe Connect',
                style: TextStyle(
                  color: AppColors.blanc,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Spotbook utilise Stripe pour garantir des paiements rapides et sécurisés directement sur votre compte bancaire.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gris,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Open Stripe Connect onboarding WebView
                    context.go('/pro/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blanc,
                    foregroundColor: AppColors.fondDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Connecter avec Stripe',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Trust badges
              _trustBadge(
                Icons.lock,
                'Transactions sécurisées SSL',
                'Cryptage de bout en bout conforme PCI',
              ),
              const SizedBox(height: 12),
              _trustBadge(
                Icons.verified_user,
                'Vérification Spotbook Pro',
                'Identité confirmée et protégée',
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Besoin d\'aide ? Contactez le support',
                  style: TextStyle(color: AppColors.accent, fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustBadge(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAuth,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.gris,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20),
        ],
      ),
    );
  }
}
