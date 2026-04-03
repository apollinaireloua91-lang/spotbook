import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/locale/app_locale_notifier.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/spotbook_bottom_sheet.dart';
import '../../../../shared/widgets/spotbook_button.dart';
import '../../../../shared/widgets/spotbook_card.dart';
import '../../../../shared/widgets/spotbook_loading_shimmer.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../feed/data/spotify_link_notifier.dart';
import '../../../feed/data/spotify_oauth_service.dart';
import '../../../feed/data/spotify_repository.dart';
import '../../data/provider_settings_repository.dart';
import '../notifiers/pro_settings_notifier.dart';

/// Paramètres Pro : navigation, formulaires légers et persistance via [ProSettingsNotifier].
class ProviderSettingsScreen extends ConsumerWidget {
  const ProviderSettingsScreen({super.key});

  static const _advanceHours = [2, 6, 12, 24, 48];
  static const _gapMinutes = [0, 15, 30, 60];
  static const _policies = ['flexible', 'moderate', 'strict'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(proSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: l10n.cancel,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.blanc, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          l10n.proSettingsTitle,
          style: const TextStyle(
            color: AppColors.blanc,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: async.when(
        data: (data) => _SettingsBody(data: data),
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: SpotbookLoadingShimmer.card(),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gris),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.data});

  final ProSettingsSnapshot data;

  void _savedToast(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.proSettingsSavedToast),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(appLocaleProvider);

    Future<void> patchSettings(Map<String, dynamic> p) async {
      try {
        await ref.read(proSettingsProvider.notifier).patchSettings(p);
        if (context.mounted) _savedToast(context, l10n);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    Future<void> patchPro(Map<String, dynamic> p) async {
      try {
        await ref.read(proSettingsProvider.notifier).patchProfilePro(p);
        if (context.mounted) _savedToast(context, l10n);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _SectionTitle(text: l10n.proSettingsSectionAccount),
        SpotbookCard(
          child: Column(
            children: [
              _Tile(
                label: l10n.email,
                value: data.email.isEmpty ? '—' : data.email,
                onTap: () => _showEmailSheet(context, ref, l10n),
              ),
              const Divider(color: AppColors.border, height: 1),
              _Tile(
                label: l10n.proSettingsPhone,
                value: data.phone?.isNotEmpty == true ? data.phone! : '—',
                onTap: () => _showPhoneSheet(context, ref, l10n),
              ),
              const Divider(color: AppColors.border, height: 1),
              _Tile(
                label: l10n.proSettingsChangePassword,
                value: '',
                showChevron: true,
                onTap: () =>
                    context.push('/pro/profile/settings/change-password'),
              ),
            ],
          ),
        ),
        _SectionTitle(text: l10n.proSettingsSectionBusiness),
        SpotbookCard(
          child: Column(
            children: [
              _Tile(
                label: l10n.proSettingsBusinessProfile,
                value: '',
                showChevron: true,
                onTap: () => context.push('/pro/profile/edit'),
              ),
              const Divider(color: AppColors.border, height: 1),
              _Tile(
                label: l10n.proSettingsWorkAddress,
                value: '',
                showChevron: true,
                onTap: () => context.push('/pro/profile/edit'),
              ),
            ],
          ),
        ),
        _SectionTitle(text: l10n.proSettingsSectionBookings),
        SpotbookCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DropdownRow<String>(
                label: l10n.proSettingsCancellationPolicy,
                value: ProviderSettingsScreen._policies
                        .contains(data.cancellationPolicy)
                    ? data.cancellationPolicy
                    : 'flexible',
                items: ProviderSettingsScreen._policies,
                display: (v) => switch (v) {
                  'moderate' => l10n.proSettingsPolicyModerate,
                  'strict' => l10n.proSettingsPolicyStrict,
                  _ => l10n.proSettingsPolicyFlexible,
                },
                onChanged: (v) {
                  if (v == null) return;
                  HapticFeedback.selectionClick();
                  patchSettings({'cancellation_policy': v});
                },
              ),
              const Divider(color: AppColors.border, height: 24),
              _DropdownRow<int>(
                label: l10n.proSettingsMinAdvance,
                value: ProviderSettingsScreen._advanceHours
                        .contains(data.minAdvanceHours)
                    ? data.minAdvanceHours
                    : 24,
                items: ProviderSettingsScreen._advanceHours,
                display: (h) =>
                    '$h${l10n.proSettingsHoursShort}',
                onChanged: (v) {
                  if (v == null) return;
                  HapticFeedback.selectionClick();
                  patchSettings({'min_advance_hours': v});
                },
              ),
              const Divider(color: AppColors.border, height: 24),
              _DropdownRow<int>(
                label: l10n.proSettingsMinGap,
                value: ProviderSettingsScreen._gapMinutes
                        .contains(data.minGapMinutes)
                    ? data.minGapMinutes
                    : 0,
                items: ProviderSettingsScreen._gapMinutes,
                display: (m) => m == 0
                    ? '0 ${l10n.proSettingsMinutesShort}'
                    : '$m ${l10n.proSettingsMinutesShort}',
                onChanged: (v) {
                  if (v == null) return;
                  HapticFeedback.selectionClick();
                  patchSettings({'min_gap_minutes': v});
                },
              ),
              const Divider(color: AppColors.border, height: 24),
              _MaxBookingsField(
                value: data.maxBookingsPerDay,
                label: l10n.proSettingsMaxPerDay,
                onSave: (n) => patchSettings({'max_bookings_per_day': n}),
              ),
            ],
          ),
        ),
        _SectionTitle(text: l10n.proSettingsSectionPayments),
        SpotbookCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StripeBlock(
                data: data,
                onRefresh: () =>
                    ref.read(proSettingsProvider.notifier).refresh(),
              ),
              const SizedBox(height: 12),
              SpotbookButton.outlined(
                label: l10n.proSettingsPayoutHistory,
                onPressed: () => context.push('/pro/payouts'),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.proSettingsPaymentsInfo,
                style: const TextStyle(
                  color: AppColors.gris,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        _SectionTitle(text: l10n.proSettingsSectionSpotify),
        SpotbookCard(
          child: _SpotifyProSettingsBlock(),
        ),
        _SectionTitle(text: 'Outils Pro'),
        SpotbookCard(
          child: Column(
            children: [
              _Tile(
                label: 'Codes Promo',
                value: '',
                showChevron: true,
                onTap: () => context.push('/pro/profile/promo-codes'),
              ),
              const Divider(color: AppColors.border, height: 1),
              _Tile(
                label: 'Mon QR Code',
                value: '',
                showChevron: true,
                onTap: () => context.push('/pro/profile/qr-code'),
              ),
              const Divider(color: AppColors.border, height: 1),
              _Tile(
                label: 'Analytiques',
                value: '',
                showChevron: true,
                onTap: () => context.push('/pro/analytics'),
              ),
            ],
          ),
        ),
        _SectionTitle(text: l10n.proSettingsSectionNotifications),
        SpotbookCard(
          child: _Tile(
            label: l10n.proSettingsNotifSettings,
            value: '',
            showChevron: true,
            onTap: () => context.push('/pro/profile/notifications-settings'),
          ),
        ),
        _SectionTitle(text: l10n.proSettingsSectionPrivacy),
        SpotbookCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.proSettingsProfilePublic,
                  style: const TextStyle(color: AppColors.blanc),
                ),
                value: data.isPublic,
                activeThumbColor: AppColors.blanc,
                activeTrackColor: AppColors.gris,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  patchPro({'is_public': v});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.proSettingsSearchVisible,
                  style: const TextStyle(color: AppColors.blanc),
                ),
                value: data.searchVisible,
                activeThumbColor: AppColors.blanc,
                activeTrackColor: AppColors.gris,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  patchPro({'search_visible': v});
                },
              ),
            ],
          ),
        ),
        _SectionTitle(text: l10n.proSettingsSectionLanguage),
        SpotbookCard(
          child: _Tile(
            label: l10n.proSettingsLanguage,
            value: locale.languageCode == 'en'
                ? l10n.proSettingsLangEnglish
                : l10n.proSettingsLangFrench,
            showChevron: true,
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/pro/profile/settings/language');
            },
          ),
        ),
        _SectionTitle(text: l10n.proSettingsSectionHelp),
        SpotbookCard(
          child: Column(
            children: [
              _Tile(
                label: l10n.proSettingsFaq,
                value: '',
                showChevron: true,
                onTap: () async {
                  final uri = Uri.parse('https://spotbook.app/faq');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const Divider(color: AppColors.border, height: 1),
              _Tile(
                label: l10n.proSettingsContactSupport,
                value: '',
                showChevron: true,
                onTap: () async {
                  final uri = Uri(
                    scheme: 'mailto',
                    path: 'support@spotbook.app',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        ),
        _SectionTitle(text: l10n.proSettingsDangerZone),
        SpotbookCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.proSettingsSignOut,
                  style: const TextStyle(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _confirmSignOut(context, ref, l10n),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.proSettingsDeleteAccount,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => context.push('/delete-account'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEmailSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final ctrl = TextEditingController(text: data.email);
    await showSpotbookBottomSheet<void>(
      context: context,
      title: l10n.proSettingsModifyEmailTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.blanc),
              decoration: InputDecoration(
                labelText: l10n.email,
                labelStyle: const TextStyle(color: AppColors.gris),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.blanc),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SpotbookButton.primary(
              label: l10n.save,
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .updateEmail(ctrl.text.trim());
                  await ref.read(proSettingsProvider.notifier).refresh();
                  if (!context.mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.proSettingsSavedToast),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _showPhoneSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final ctrl = TextEditingController(text: data.phone ?? '');
    await showSpotbookBottomSheet<void>(
      context: context,
      title: l10n.proSettingsModifyPhoneTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.blanc),
              decoration: InputDecoration(
                labelText: l10n.proSettingsPhone,
                labelStyle: const TextStyle(color: AppColors.gris),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.blanc),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SpotbookButton.primary(
              label: l10n.save,
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(providerSettingsRepositoryProvider)
                      .updatePhone(ctrl.text.trim());
                  await ref.read(proSettingsProvider.notifier).refresh();
                  if (!context.mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.proSettingsSavedToast),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.proSettingsSignOutTitle,
          style: const TextStyle(color: AppColors.blanc),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.gris)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.proSettingsSignOutConfirm,
                style: const TextStyle(color: AppColors.blanc)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      HapticFeedback.mediumImpact();
      try {
        await ref.read(authRepositoryProvider).signOut();
      } catch (e) {
        debugPrint('[pro_settings] signOut error ignored: $e');
      }
      if (context.mounted) context.go('/login');
    }
  }
}

/// Connexion OAuth Spotify (top titres + recherche enrichie sur le feed pro).
class _SpotifyProSettingsBlock extends ConsumerStatefulWidget {
  const _SpotifyProSettingsBlock();

  @override
  ConsumerState<_SpotifyProSettingsBlock> createState() =>
      _SpotifyProSettingsBlockState();
}

class _SpotifyProSettingsBlockState extends ConsumerState<_SpotifyProSettingsBlock> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final link = ref.watch(spotifyLinkProvider);
    final oauth = ref.watch(spotifyOAuthServiceProvider);

    return link.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.blanc,
            ),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.error,
          style: const TextStyle(color: AppColors.gris),
        ),
      ),
      data: (info) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: info.linked
                      ? AppColors.spotifyGreen
                      : AppColors.gris,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.proSettingsSpotifyTitle,
                    style: const TextStyle(
                      color: AppColors.blanc,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.proSettingsSpotifyHint,
              style: const TextStyle(
                color: AppColors.gris,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (info.linked) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.spotifyGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.proSettingsSpotifyLinked,
                      style: const TextStyle(
                        color: AppColors.blanc,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (info.linked)
              SpotbookButton.outlined(
                label: l10n.proSettingsSpotifyDisconnect,
                isLoading: _busy,
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        HapticFeedback.mediumImpact();
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref
                              .read(spotifyRepositoryProvider)
                              .disconnect();
                          await ref
                              .read(spotifyLinkProvider.notifier)
                              .refresh();
                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.proSettingsSavedToast),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
              )
            else
              SpotbookButton.primary(
                label: l10n.proSettingsSpotifyConnect,
                isLoading: _busy,
                onPressed: _busy
                    ? null
                    : () async {
                        if (!oauth.isConfigured) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(l10n.proSettingsSpotifyMissingClientId),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        setState(() => _busy = true);
                        HapticFeedback.mediumImpact();
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final code = await oauth.authorizeInteractive();
                          await ref
                              .read(spotifyRepositoryProvider)
                              .exchangeOAuthCode(code);
                          await ref
                              .read(spotifyLinkProvider.notifier)
                              .refresh();
                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.proSettingsSavedToast),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
              ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.gris,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.onTap,
    this.showChevron = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.blanc,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: value.isNotEmpty
          ? Text(
              value,
              style: const TextStyle(color: AppColors.gris),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: showChevron
          ? const Icon(Icons.chevron_right, color: AppColors.gris)
          : const Icon(Icons.edit_outlined,
              color: AppColors.gris, size: 20),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) display;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gris,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceAlt,
          style: const TextStyle(color: AppColors.blanc, fontSize: 15),
          underline: const SizedBox(),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(display(e)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MaxBookingsField extends StatefulWidget {
  const _MaxBookingsField({
    required this.value,
    required this.label,
    required this.onSave,
  });

  final int value;
  final String label;
  final Future<void> Function(int) onSave;

  @override
  State<_MaxBookingsField> createState() => _MaxBookingsFieldState();
}

class _MaxBookingsFieldState extends State<_MaxBookingsField> {
  late final TextEditingController _c =
      TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(covariant _MaxBookingsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        int.tryParse(_c.text) != widget.value) {
      _c.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    final n = int.tryParse(_c.text.trim());
    if (n == null || n < 1 || n > 100) return;
    HapticFeedback.selectionClick();
    await widget.onSave(n);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.gris,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _c,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.blanc),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.blanc),
            ),
          ),
          onEditingComplete: _commit,
          onSubmitted: (_) => _commit(),
        ),
      ],
    );
  }
}

class _StripeBlock extends ConsumerStatefulWidget {
  const _StripeBlock({
    required this.data,
    required this.onRefresh,
  });

  final ProSettingsSnapshot data;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_StripeBlock> createState() => _StripeBlockState();
}

class _StripeBlockState extends ConsumerState<_StripeBlock> {
  bool _opening = false;

  String _statusLine(AppLocalizations l10n) {
    final d = widget.data;
    if (d.stripeOnboarded) {
      final last = d.stripePayoutLast4;
      if (last != null && last.isNotEmpty) {
        return '${l10n.proSettingsStripeActive} · ${l10n.proSettingsBankEnding} ·••• $last';
      }
      return l10n.proSettingsStripeActive;
    }
    if (d.stripeAccountId != null && d.stripeAccountId!.isNotEmpty) {
      return l10n.proSettingsStripeVerifying;
    }
    return l10n.proSettingsStripeNotConfigured;
  }

  Future<void> _openConnect(BuildContext context) async {
    if (_opening) return;
    setState(() => _opening = true);
    final router = GoRouter.of(context);
    try {
      final url =
          await ref.read(providerSettingsRepositoryProvider).fetchStripeConnectOnboardingUrl();
      if (!mounted) return;
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.inAppWebView,
        );
      } else {
        router.push('/pro/stripe-setup');
      }
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configured = widget.data.stripeOnboarded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _statusLine(l10n),
          style: const TextStyle(
            color: AppColors.blanc,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if (!configured) ...[
          const SizedBox(height: 12),
          SpotbookButton.primary(
            label: l10n.proSettingsStripeConfigure,
            isLoading: _opening,
            onPressed: _opening ? null : () => _openConnect(context),
          ),
        ],
      ],
    );
  }
}
