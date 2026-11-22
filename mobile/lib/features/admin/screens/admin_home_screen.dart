import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
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
import 'admin_portfolios_screen.dart';
import 'admin_price_history_screen.dart';

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
    final l10n = ref.watch(l10nProvider);
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
              Text(
                l10n.isVietnamese ? 'Quản trị hệ thống' : 'System Administration',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.isVietnamese
                    ? 'Xin chào, ${user?.fullName ?? ''}'
                    : 'Welcome, ${user?.fullName ?? ''}',
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
                    l10n.isVietnamese
                        ? 'Không tải được chỉ số: $e\nBấm để thử lại.'
                        : 'Failed to load metrics: $e\nTap to retry.',
                    style: const TextStyle(color: AppColors.priceDown),
                  ),
                ),
                data: (d) => _KpiGrid(d: d, l10n: l10n),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.isVietnamese ? 'Quản lý' : 'Management',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.people_alt_rounded,
                title: l10n.isVietnamese ? 'Khách hàng' : 'Customers',
                subtitle: l10n.isVietnamese
                    ? 'Danh sách, thêm, sửa, khóa, xóa'
                    : 'List, add, edit, lock, delete',
                onTap: () => _open(context, ref, const AdminCustomersScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.account_balance_wallet_rounded,
                title: l10n.isVietnamese ? 'Tài khoản đầu tư' : 'Investment Accounts',
                subtitle: l10n.isVietnamese
                    ? 'Mở mới, sửa số dư, trạng thái, xóa'
                    : 'Open new, edit balance, status, delete',
                onTap: () => _open(context, ref, const AdminAccountsScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.candlestick_chart_rounded,
                title: l10n.isVietnamese ? 'Mã cổ phiếu' : 'Stock Symbols',
                subtitle: l10n.isVietnamese
                    ? 'Thêm, sửa giá trần/sàn, đổi trạng thái, xóa'
                    : 'Add, edit ceil/floor, update status, delete',
                onTap: () => _open(context, ref, const AdminStocksScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.receipt_long_rounded,
                title: l10n.isVietnamese ? 'Sổ lệnh' : 'Order Book',
                subtitle: l10n.isVietnamese
                    ? 'Tra cứu toàn hệ thống, hủy lệnh đang chờ'
                    : 'System-wide search, cancel pending orders',
                onTap: () => _open(context, ref, const AdminOrdersScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.swap_horiz_rounded,
                title: l10n.isVietnamese ? 'Lịch sử giao dịch' : 'Transaction History',
                subtitle: l10n.isVietnamese
                    ? 'Lịch sử khớp lệnh toàn hệ thống'
                    : 'System-wide trade execution history',
                onTap: () =>
                    _open(context, ref, const AdminTransactionsScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.pie_chart_rounded,
                title: l10n.isVietnamese ? 'Danh mục nắm giữ' : 'Holdings & Portfolios',
                subtitle: l10n.isVietnamese
                    ? 'Điều chỉnh số lượng cổ phiếu và giá vốn'
                    : 'Adjust share quantity and cost basis',
                onTap: () => _open(context, ref, const AdminPortfoliosScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.show_chart_rounded,
                title: l10n.isVietnamese ? 'Lịch sử giá' : 'Price History',
                subtitle: l10n.isVietnamese
                    ? 'Biểu đồ nến, thêm, sửa, xóa phiên giá'
                    : 'Candlestick chart, add, edit, delete candles',
                onTap: () =>
                    _open(context, ref, const AdminPriceHistoryScreen()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.campaign_rounded,
                title: l10n.isVietnamese ? 'Thông báo' : 'Notifications',
                subtitle: l10n.isVietnamese
                    ? 'Soạn, gửi cho một hoặc tất cả khách hàng, xóa'
                    : 'Compose, send to one or all customers, delete',
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
  final AppLocalizations l10n;

  const _KpiGrid({required this.d, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final vi = l10n.isVietnamese;
    final cards = [
      _KpiCard(
        icon: Icons.people_alt_rounded,
        label: vi ? 'Khách hàng' : 'Customers',
        value: '${d.totalCustomers}',
        note: vi
            ? '${d.activeCustomers} hoạt động · ${d.lockedCustomers} bị khóa'
            : '${d.activeCustomers} active · ${d.lockedCustomers} locked',
      ),
      _KpiCard(
        icon: Icons.account_balance_wallet_rounded,
        label: vi ? 'Tài khoản đầu tư' : 'Investment Accounts',
        value: '${d.totalAccounts}',
        note: vi
            ? '${d.activeAccounts} hoạt động · ${d.suspendedAccounts} tạm ngưng'
            : '${d.activeAccounts} active · ${d.suspendedAccounts} suspended',
      ),
      _KpiCard(
        icon: Icons.payments_rounded,
        label: vi ? 'Tổng tiền mặt' : 'Total Cash',
        value: formatVnd(d.totalCashBalance),
        note: vi ? 'Tất cả tài khoản' : 'All accounts',
      ),
      _KpiCard(
        icon: Icons.savings_rounded,
        label: vi ? 'Tổng tài sản' : 'Total Assets',
        value: formatVnd(d.totalAssetValue),
        note: vi ? 'Tất cả tài khoản' : 'All accounts',
      ),
      _KpiCard(
        icon: Icons.candlestick_chart_rounded,
        label: vi ? 'Mã cổ phiếu' : 'Stock Symbols',
        value: '${d.totalStocks}',
        note: vi
            ? '${d.activeStocks} giao dịch · ${d.haltedStocks} tạm dừng'
            : '${d.activeStocks} active · ${d.haltedStocks} halted',
      ),
      _KpiCard(
        icon: Icons.receipt_long_rounded,
        label: vi ? 'Lệnh hôm nay' : 'Orders Today',
        value: '${d.totalOrdersToday}',
        note: vi
            ? '${d.pendingOrders} chờ · ${d.completedOrders} khớp · ${d.cancelledOrders} hủy'
            : '${d.pendingOrders} pending · ${d.completedOrders} filled · ${d.cancelledOrders} cancelled',
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