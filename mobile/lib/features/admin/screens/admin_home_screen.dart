import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/admin_widgets.dart';
import 'admin_customers_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: ListView(
          // Chừa chỗ phía dưới để không bị thanh điều hướng nổi che.
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            const Text(
              'Quản trị hệ thống',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Xin chào, ${user?.fullName ?? ''}',
              style: const TextStyle(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 24),
            _MenuTile(
              icon: Icons.people_alt_rounded,
              title: 'Khách hàng',
              subtitle: 'Danh sách, thêm, sửa, khóa, xóa',
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminCustomersScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _MenuTile(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Tài khoản đầu tư',
              subtitle: 'Sắp có',
            ),
            const SizedBox(height: 12),
            const _MenuTile(
              icon: Icons.candlestick_chart_rounded,
              title: 'Mã cổ phiếu',
              subtitle: 'Sắp có',
            ),
            const SizedBox(height: 12),
            const _MenuTile(
              icon: Icons.receipt_long_rounded,
              title: 'Lệnh và giao dịch',
              subtitle: 'Sắp có',
            ),
            const SizedBox(height: 12),
            const _MenuTile(
              icon: Icons.campaign_rounded,
              title: 'Thông báo',
              subtitle: 'Sắp có',
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AdminCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.darkTextMuted,
              ),
          ],
        ),
      ),
    );
  }
}