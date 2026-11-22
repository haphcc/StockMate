import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/language_switch_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final user = ref.watch(authProvider).value;
    final isDarkMode = ref.watch(themeModeProvider);

    final fullName = (user?.fullName.isNotEmpty ?? false) ? user!.fullName : 'NGUYỄN VĂN A';
    final email = (user?.email.isNotEmpty ?? false) ? user!.email : 'investor@stockmate.vn';
    final phoneNumber = (user?.phoneNumber.isNotEmpty ?? false) ? user!.phoneNumber : '0912 345 678';
    const accountNumber = '086C123456';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20.0,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home/overview');
            }
          },
        ),
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: LanguageSwitchButton(height: 32.0),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Summary Card
            _buildUserHeaderCard(
              fullName: fullName,
              accountNumber: accountNumber,
              verifiedLabel: l10n.accountVerifiedBadge,
            ),
            const SizedBox(height: 24.0),

            // Section 1: App Settings (Language, Theme, Biometrics)
            _buildSectionHeader(l10n.sectionPreferences),
            const SizedBox(height: 10.0),
            const LanguageSettingsTile(),
            const SizedBox(height: 10.0),
            _buildSettingsToggleTile(
              icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: l10n.labelTheme,
              subtitle: isDarkMode ? l10n.darkMode : l10n.lightMode,
              value: isDarkMode,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).set(val);
              },
            ),
            const SizedBox(height: 10.0),
            _buildSettingsToggleTile(
              icon: Icons.fingerprint_rounded,
              title: l10n.labelBiometrics,
              subtitle: l10n.biometricsDesc,
              value: _biometricsEnabled,
              onChanged: (val) {
                setState(() => _biometricsEnabled = val);
              },
            ),
            const SizedBox(height: 24.0),

            // Section 2: Personal Information
            _buildSectionHeader(l10n.sectionGeneral),
            const SizedBox(height: 10.0),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    label: l10n.labelFullName,
                    value: fullName,
                    icon: Icons.person_outline_rounded,
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    label: l10n.labelAccountNumber,
                    value: accountNumber,
                    icon: Icons.badge_outlined,
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    label: l10n.labelPhone,
                    value: phoneNumber,
                    icon: Icons.phone_outlined,
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    label: l10n.labelEmail,
                    value: email,
                    icon: Icons.email_outlined,
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    label: l10n.labelStatus,
                    value: l10n.statusActive,
                    icon: Icons.verified_user_outlined,
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Section 3: Security & Account
            _buildSectionHeader(l10n.sectionSecurity),
            const SizedBox(height: 10.0),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Column(
                children: [
                  _buildNavigationTile(
                    icon: Icons.lock_outline_rounded,
                    title: l10n.changePassword,
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.pin_outlined,
                    title: l10n.changePin,
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.security_rounded,
                    title: l10n.twoFactorAuth,
                    trailingText: 'SMS / OTP',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Section 4: Support & About
            _buildSectionHeader(l10n.sectionSupport),
            const SizedBox(height: 10.0),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Column(
                children: [
                  _buildNavigationTile(
                    icon: Icons.help_outline_rounded,
                    title: l10n.helpCenter,
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.headset_mic_outlined,
                    title: l10n.contactSupport,
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.description_outlined,
                    title: l10n.termsAndPolicies,
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.info_outline_rounded,
                    title: l10n.appVersion,
                    trailingText: 'v1.0.0 (Build 1)',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28.0),

            // Logout Button
            InkWell(
              onTap: () => _showLogoutConfirmDialog(context, ref, l10n),
              borderRadius: BorderRadius.circular(14.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                decoration: BoxDecoration(
                  color: AppColors.priceDown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: AppColors.priceDown.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppColors.priceDown,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      l10n.logoutButton,
                      style: const TextStyle(
                        color: AppColors.priceDown,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeaderCard({
    required String fullName,
    required String accountNumber,
    required String verifiedLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF162522),
            Color(0xFF101917),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.0),
              child: Image.network(
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Icon(Icons.person, color: Colors.white70, size: 32.0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  accountNumber,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 13.0,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 13.0,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        verifiedLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.darkTextMuted,
        fontSize: 12.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSettingsToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.0),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            inactiveThumbColor: AppColors.darkTextMuted,
            inactiveTrackColor: AppColors.darkBorder,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkTextSecondary, size: 18.0),
          const SizedBox(width: 12.0),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 13.0,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.darkTextSecondary, size: 18.0),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12.0,
                ),
              ),
              const SizedBox(width: 6.0),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.darkTextSecondary,
              size: 18.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1.0,
      thickness: 0.8,
      color: AppColors.darkCardBorder,
      indent: 16.0,
      endIndent: 16.0,
    );
  }

  void _showLogoutConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
            side: const BorderSide(color: AppColors.darkCardBorder),
          ),
          title: Text(
            l10n.logoutConfirmTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.logoutConfirmMessage,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: AppColors.darkTextSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: Text(
                l10n.confirm,
                style: const TextStyle(
                  color: AppColors.priceDown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
