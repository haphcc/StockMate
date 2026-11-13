import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'TÀI KHOẢN',
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w700),
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
                _InfoRow(icon: Icons.person_outline_rounded, label: 'Họ và tên', value: user?.fullName ?? '—'),
                const Divider(color: AppColors.darkCardBorder, height: 1),
                _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '—'),
                const Divider(color: AppColors.darkCardBorder, height: 1),
                _InfoRow(icon: Icons.phone_outlined, label: 'Số điện thoại', value: user?.phoneNumber ?? '—'),
                const Divider(color: AppColors.darkCardBorder, height: 1),
                _InfoRow(icon: Icons.badge_outlined, label: 'Vai trò', value: user?.role ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'ỨNG DỤNG',
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkCardBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('StockMate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      SizedBox(height: 3),
                      Text('Phiên bản 1.0.0', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
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

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.darkTextSecondary))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

