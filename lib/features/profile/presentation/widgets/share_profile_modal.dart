import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_bottom_sheet.dart';

/// Bottom sheet : QR profil + partage (copier, SMS, WhatsApp, Instagram, natif).
Future<void> showShareProfileModal({
  required BuildContext context,
  required String profileUrl,
  required String displayName,
  String? avatarUrl,
}) {
  return showSpotbookBottomSheet<void>(
    context: context,
    title: 'Share profile',
    child: ShareProfileModal(
      profileUrl: profileUrl,
      displayName: displayName,
      avatarUrl: avatarUrl,
    ),
  );
}

class ShareProfileModal extends StatelessWidget {
  const ShareProfileModal({
    super.key,
    required this.profileUrl,
    required this.displayName,
    this.avatarUrl,
  });

  final String profileUrl;
  final String displayName;
  final String? avatarUrl;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: profileUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            'Link copied',
            style: TextStyle(color: AppColors.blanc),
          ),
        ),
      );
    }
  }

  Future<void> _sms() async {
    final uri = Uri.parse(
      'sms:?body=${Uri.encodeComponent('$displayName on Spotbook : $profileUrl')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsapp() async {
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent('$displayName on Spotbook : $profileUrl')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _instagram() async {
    final ig = Uri.parse('https://www.instagram.com/');
    if (await canLaunchUrl(ig)) {
      await launchUrl(ig, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareNative() async {
    await SharePlus.instance.share(
      ShareParams(text: '$displayName on Spotbook\n$profileUrl'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: QrImageView(
              data: profileUrl,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: AppColors.blanc,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.blanc,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _SheetTile(
            icon: Icons.link,
            label: 'Copy link',
            onTap: () => _copy(context),
          ),
          _SheetTile(
            icon: Icons.sms_outlined,
            label: 'SMS',
            onTap: _sms,
          ),
          _SheetTile(
            icon: Icons.chat,
            label: 'WhatsApp',
            onTap: _whatsapp,
          ),
          _SheetTile(
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            onTap: _instagram,
          ),
          _SheetTile(
            icon: Icons.ios_share,
            label: 'More…',
            onTap: _shareNative,
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.blanc, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.blanc,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.of(context).maybePop();
        onTap();
      },
    );
  }
}
