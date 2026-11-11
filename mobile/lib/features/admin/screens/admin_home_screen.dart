import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/admin_dashboard_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_accounts_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_stocks_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_transactions_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    Widget screen,
  ) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    // Quay lại thì tải lại chỉ số vì dữ liệu có thể đã thay đổi.
    ref.invalidate(adminDashboardProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final dashboard = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminDashboardProvider);
            try {
              await ref.read(adminDashboardProvider.future);
            } catch (_) {
              // Lỗi đã được hiển thị trên màn hình.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              const SizedBox(height: 20),
              dashboard.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => AdminCard(
                  onTap: () => ref.invalidate(adminDashboardProvider),
                  child: Text(
                    'Không tải được chỉ số: $e\nBấm để thử lại.',
                    style: const TextStyle(color: AppColors.priceDown),
                  ),
                ),
                data: (d) => _KpiGrid(d: d),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quản lý',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.people_alt_rounded,
                title: 'Khách hàng',
                subtitle: 'Danh sách, thêm, sửa, khóa, xóa',
                onTap: () => _open(context, ref, const AdminCustomersScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Tài khoản đầu tư',
                subtitle: 'Mở mới, sửa số dư, trạng thái, xóa',
                onTap: () => _open(context, ref, const AdminAccountsScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.candlestick_chart_rounded,
                title: 'Mã cổ phiếu',
                subtitle: 'Thêm, sửa giá trần/sàn, đổi trạng thái, xóa',
                onTap: () => _open(context, ref, const AdminStocksScreen()),
              ),
              const SizedBox(height: 12),
                            _MenuTile(
                icon: Icons.receipt_long_rounded,
                title: 'Sổ lệnh',
                subtitle: 'Tra cứu toàn hệ thống, hủy lệnh đang chờ',
                onTap: () => _open(context, ref, const AdminOrdersScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Lịch sử giao dịch',
                subtitle: 'Lịch sử khớp lệnh toàn hệ thống',
                onTap: () =>
                    _open(context, ref, const AdminTransactionsScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.campaign_rounded,
                title: 'Thông báo',
                subtitle: 'Soạn, gửi cho một hoặc tất cả khách hàng, xóa',
                onTap: () =>
                    _open(context, ref, const AdminNotificationsScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final AdminDashboardModel d;

  const _KpiGrid({required this.d});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        icon: Icons.people_alt_rounded,
        label: 'Khách hàng',
        value: '${d.totalCustomers}',
        note: '${d.activeCustomers} hoạt động · ${d.lockedCustomers} bị khóa',
      ),
      _KpiCard(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Tài khoản đầu tư',
        value: '${d.totalAccounts}',
        note: '${d.activeAccounts} hoạt động · ${d.suspendedAccounts} tạm ngưng',
      ),
      _KpiCard(
        icon: Icons.payments_rounded,
        label: 'Tổng tiền mặt',
        value: formatVnd(d.totalCashBalance),
        note: 'Tất cả tài khoản',
      ),
      _KpiCard(
        icon: Icons.savings_rounded,
        label: 'Tổng tài sản',
        value: formatVnd(d.totalAssetValue),
        note: 'Tất cả tài khoản',
      ),
      _KpiCard(
        icon: Icons.candlestick_chart_rounded,
        label: 'Mã cổ phiếu',
        value: '${d.totalStocks}',
        note: '${d.activeStocks} giao dịch · ${d.haltedStocks} tạm dừng',
      ),
      _KpiCard(
        icon: Icons.receipt_long_rounded,
        label: 'Lệnh hôm nay',
        value: '${d.totalOrdersToday}',
        note: '${d.pendingOrders} chờ · ${d.completedOrders} khớp · '
            '${d.cancelledOrders} hủy',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.25,
      children: cards,
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String note;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11),
          ),
        ],
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