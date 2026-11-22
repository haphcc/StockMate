import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/language_switch_button.dart';
import '../../../providers/app_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: Text(l10n.settingsAndAccount),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: LanguageSwitchButton(height: 30),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Tài khoản / Profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.sectionGeneral,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: () => ProfileDialogs.showEditProfileDialog(
                  context: context,
                  ref: ref,
                  user: user,
                ),
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                label: Text(
                  l10n.editProfile,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: l10n.labelFullName,
                  value: user?.fullName ?? '—',
                  onTap: () => ProfileDialogs.showEditProfileDialog(
                    context: context,
                    ref: ref,
                    user: user,
                  ),
                ),
                const Divider(color: AppColors.darkCardBorder, height: 1),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: l10n.labelEmail,
                  value: user?.email ?? '—',
                ),
                const Divider(color: AppColors.darkCardBorder, height: 1),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: l10n.labelPhone,
                  value: user?.displayPhoneNumber ?? '—',
                  onTap: () => ProfileDialogs.showEditProfileDialog(
                    context: context,
                    ref: ref,
                    user: user,
                  ),
                ),
                const Divider(color: AppColors.darkCardBorder, height: 1),
                _InfoRow(
                  icon: Icons.verified_user_outlined,
                  label: l10n.labelLoginMethod,
                  value: (user?.isGoogleAccount ?? false)
                      ? l10n.googleAccount
                      : l10n.emailPasswordAccount,
                ),
                const Divider(color: AppColors.darkCardBorder, height: 1),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: l10n.labelRole,
                  value: user?.role ?? '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Ngôn ngữ / Language
          Text(
            l10n.sectionPreferences,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const LanguageSettingsTile(),
          const SizedBox(height: 24),

          // Section: Bảo mật / Security
          Text(
            l10n.sectionSecurity,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => ProfileDialogs.showChangePasswordDialog(
                  context: context,
                  ref: ref,
                  hasPassword: user?.hasPassword ?? true,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (user?.hasPassword ?? true)
                                  ? l10n.changePassword
                                  : l10n.setPassword,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (user?.hasPassword ?? true)
                                  ? l10n.updatePasswordDesc
                                  : l10n.setPasswordDesc,
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.darkTextSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Ứng dụng
          Text(
            l10n.sectionApplication,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'StockMate',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${l10n.appVersion} 1.0.0',
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.darkTextSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.darkTextMuted,
              size: 16,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }
    return content;
  }
}
