import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';

/// Placeholder screen that displays the Stripe Checkout URL.
/// In production this would use a WebView (webview_flutter) to load the URL.
/// For now we display the URL and a "Done" button to simulate completion.
class StripeCheckoutWebview extends StatelessWidget {
  const StripeCheckoutWebview({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Close',
          child: IconButton(
            icon: const Icon(Icons.close, color: AppColors.blanc),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: const Text(
          'Stripe Checkout',
          style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, color: AppColors.gris, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Redirecting to Stripe...',
              style: TextStyle(
                color: AppColors.blanc,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              url,
              style: const TextStyle(color: AppColors.gris, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            const Text(
              'In production, this page will display the Stripe payment form via WebView.',
              style: TextStyle(color: AppColors.gris, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blanc,
                  foregroundColor: AppColors.fond,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
