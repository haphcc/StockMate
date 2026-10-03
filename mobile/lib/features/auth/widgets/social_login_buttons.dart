import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SocialAuthSection extends StatelessWidget {
  /// Replace these paths (or pass paths to the constructor) with the icon
  /// files you add under `assets/icons/`.
  static const defaultGoogleIconAsset = 'assets/icons/my_google_icon.png';
  static const defaultAppleIconAsset = 'assets/icons/my_apple_icon.png';

  final String dividerText;
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final String googleIconAsset;
  final String appleIconAsset;

  const SocialAuthSection({
    super.key,
    required this.dividerText,
    this.onGoogleTap,
    this.onAppleTap,
    this.googleIconAsset = defaultGoogleIconAsset,
    this.appleIconAsset = defaultAppleIconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Divider(color: AppColors.darkBorder, thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                dividerText,
                style: const TextStyle(
                  color: AppColors.darkTextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: AppColors.darkBorder, thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                onTap: onGoogleTap,
                iconAsset: googleIconAsset,
                label: 'Google',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                onTap: onAppleTap,
                iconAsset: appleIconAsset,
                label: 'Apple ID',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String iconAsset;
  final String label;

  const _SocialButton({
    required this.onTap,
    required this.iconAsset,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.darkInput,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkInputBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Image.asset(
                iconAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
