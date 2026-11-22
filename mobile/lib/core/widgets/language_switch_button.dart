import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../../providers/app_providers.dart';

/// Nút chuyển đổi ngôn ngữ Tiếng Việt / Tiếng Anh.
/// Hỗ trợ hiển thị dạng thanh trượt nhỏ (compact pill) hoặc dạng dòng cài đặt (settings tile).
class LanguageSwitchButton extends ConsumerWidget {
  final double height;
  final bool showFlag;

  const LanguageSwitchButton({
    super.key,
    this.height = 34.0,
    this.showFlag = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isVi = currentLocale.languageCode == 'vi';

    return Container(
      height: height,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: AppColors.darkInput,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: AppColors.darkInputBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context: context,
            ref: ref,
            code: 'vi',
            flag: '🇻🇳',
            label: 'VI',
            isActive: isVi,
          ),
          const SizedBox(width: 2.0),
          _buildOption(
            context: context,
            ref: ref,
            code: 'en',
            flag: '🇬🇧',
            label: 'EN',
            isActive: !isVi,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required WidgetRef ref,
    required String code,
    required String flag,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      key: ValueKey('lang_opt_$code'),
      onTap: () {
        if (!isActive) {
          HapticFeedback.selectionClick();
          ref.read(localeProvider.notifier).setLocale(Locale(code));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(height / 2),
          gradient: isActive
              ? const LinearGradient(
                  colors: [
                    Color(0xFF00E6A8),
                    Color(0xFF00C896),
                  ],
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showFlag) ...[
              Text(
                flag,
                style: const TextStyle(fontSize: 13.0),
              ),
              const SizedBox(width: 4.0),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF032617) : AppColors.darkTextSecondary,
                fontSize: 12.0,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dòng cài đặt ngôn ngữ chuyên biệt cho màn hình Hồ sơ (Profile) / Cài đặt.
class LanguageSettingsTile extends ConsumerWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final currentLocale = ref.watch(localeProvider);
    final isVi = currentLocale.languageCode == 'vi';

    return InkWell(
      onTap: () {
        _showLanguagePicker(context, ref);
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
              child: const Icon(
                Icons.translate_rounded,
                color: AppColors.primary,
                size: 20.0,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.labelLanguage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    isVi ? 'Tiếng Việt (Vietnamese)' : 'English (Tiếng Anh)',
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            const LanguageSwitchButton(height: 32.0),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final l10n = ref.read(l10nProvider);
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.selectLanguage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.darkTextSecondary),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                _LanguageModalItem(
                  flag: '🇻🇳',
                  name: 'Tiếng Việt',
                  subname: 'Vietnamese',
                  isSelected: currentLocale.languageCode == 'vi',
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('vi'));
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 10.0),
                _LanguageModalItem(
                  flag: '🇬🇧',
                  name: 'English',
                  subname: 'Tiếng Anh',
                  isSelected: currentLocale.languageCode == 'en',
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 12.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageModalItem extends StatelessWidget {
  final String flag;
  final String name;
  final String subname;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageModalItem({
    required this.flag,
    required this.name,
    required this.subname,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.darkInput,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkInputBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22.0)),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subname,
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20.0,
              ),
          ],
        ),
      ),
    );
  }
}
