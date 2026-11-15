import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sparkline_chart.dart';
import '../../../core/widgets/stockmate_brand.dart';
import '../providers/dashboard_provider.dart';
import '../../../providers/selected_account_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_dialogs.dart';
import '../widgets/stock_search_dialog.dart';
import '../widgets/notifications_sheet.dart';
import '../widgets/dashboard_dialogs.dart';
import '../providers/notification_provider.dart';
import '../../../data/models/stock_model.dart';
import '../../../core/theme/price_colors.dart';

enum _ProfileAction { editProfile, changePassword, settings, logout }

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 12),
      Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedCategory = 'VN30';
  String _selectedSort = 'volume';

  static const List<String> _categories = [
    'VN30',
    'Tất cả',
    'HOSE',
    'HNX',
    'Ngân hàng',
    'Bất động sản',
    'Chứng khoán',
    'Thép',
    'Năng lượng',
    'Bán lẻ & Tiêu dùng',
  ];

  static const Map<String, (String label, IconData icon)> _sortOptions = {
    'volume': ('Top Khối lượng', Icons.bar_chart_rounded),
    'gain': ('Top Tăng giá', Icons.trending_up_rounded),
    'loss': ('Top Giảm giá', Icons.trending_down_rounded),
    'price_high': ('Giá cao nhất', Icons.arrow_upward_rounded),
    'price_low': ('Giá thấp nhất', Icons.arrow_downward_rounded),
    'alpha': ('Mã A - Z', Icons.sort_by_alpha_rounded),
  };

  static const Set<String> _vn30Set = {
    'ACB', 'BCM', 'BID', 'BVH', 'CTG', 'FPT', 'GAS', 'GVR', 'HDB', 'HPG',
    'MBB', 'MSN', 'MWG', 'PLX', 'POW', 'SAB', 'SHB', 'SSB', 'SSI', 'STB',
    'TCB', 'TPB', 'VCB', 'VHM', 'VIB', 'VIC', 'VJC', 'VNM', 'VPB', 'VRE'
  };

  static const Set<String> _bankingSet = {
    'VCB', 'TCB', 'MBB', 'ACB', 'VPB', 'CTG', 'BID', 'SSB',
    'LPB', 'OCB', 'SHB', 'STB', 'HDB', 'TPB', 'VIB', 'MSB', 'EIB', 'NAB', 'BAB'
  };

  static const Set<String> _reSet = {
    'VHM', 'VIC', 'VRE', 'NVL', 'DIG', 'PDR', 'DXG', 'KDH',
    'KBC', 'BCM', 'NLG', 'CEO', 'HDG', 'SCR', 'HQC'
  };

  static const Set<String> _secSet = {
    'SSI', 'VND', 'VCI', 'HCM', 'SHS', 'FTS', 'MBS', 'BSI', 'CTS', 'VIX', 'AGR', 'ORIC'
  };

  static const Set<String> _steelSet = {
    'HPG', 'HSG', 'NKG', 'TLH', 'POM', 'SMC', 'VGS'
  };

  static const Set<String> _energySet = {
    'GAS', 'POW', 'PLX', 'PVD', 'PVS', 'BSR', 'GEX', 'GEG', 'NT2', 'PC1'
  };

  static const Set<String> _retailSet = {
    'MWG', 'FRT', 'PNJ', 'MSN', 'VNM', 'SAB', 'KDC', 'DGW'
  };

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final baseStocks = dashboardAsync.value?.marketBoard.isNotEmpty == true
        ? dashboardAsync.value!.marketBoard
        : _defaultStocks;
    final filtered = _getFilteredStocks(baseStocks);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: () async => ref.refresh(dashboardProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header Bar
                _buildTopHeader(),
                const SizedBox(height: 14),

                // 2. Virtual Balance Bar
                _buildVirtualBalanceBar(dashboardAsync.value),
                const SizedBox(height: 18),

                // 3. Section: Live Indices HOSE / HNX
                _buildIndicesHeader(),
                const SizedBox(height: 10),
                _buildIndicesCards(),
                const SizedBox(height: 18),

                // 4. Market Breadth Card
                _buildMarketBreadthCard(),
                const SizedBox(height: 16),

                // 5. Hot News / Highlight Card
                _buildHotNewsCard(),
                const SizedBox(height: 18),

                // 6. Category Filter Chips
                _buildCategoryChips(baseStocks),
                const SizedBox(height: 18),

                // 7. Online Price Board Header & Sort
                _buildPriceBoardHeader(filtered.length),
                const SizedBox(height: 12),

                // 8. Stocks List
                dashboardAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Lỗi tải dữ liệu: $err',
                        style: const TextStyle(color: AppColors.priceDown),
                      ),
                    ),
                  ),
                  data: (_) => _buildStockTable(filtered),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Top Header Bar ---
  Widget _buildTopHeader() {
    final user = ref.watch(authProvider).value;
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Logo + LIVE Badge
        const StockMateBrand(iconSize: 28, fontSize: 19, showLiveBadge: true),

        // Right Actions: Search, Notification with dot, Avatar
        Row(
          children: [
            IconButton(
              tooltip: 'Tìm kiếm cổ phiếu',
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => StockSearchDialog.show(context),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            const SizedBox(width: 4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Thông báo',
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => NotificationsSheet.show(context),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                if (unreadNotifs > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_ProfileAction>(
              tooltip: 'Tài khoản',
              color: AppColors.darkCard,
              elevation: 10,
              offset: const Offset(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.darkCardBorder),
              ),
              onSelected: (action) => _handleProfileAction(action),
              itemBuilder: (context) => [
                PopupMenuItem<_ProfileAction>(
                  enabled: false,
                  height: 72,
                  child: Row(
                    children: [
                      _buildAvatar(user?.avatarUrl, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName.isNotEmpty == true
                                  ? user!.fullName
                                  : 'Tài khoản StockMate',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.editProfile,
                  child: _ProfileMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Sửa thông tin',
                  ),
                ),
                const PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.changePassword,
                  child: _ProfileMenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Đổi mật khẩu',
                  ),
                ),
                const PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.settings,
                  child: _ProfileMenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Cài đặt',
                  ),
                ),
                const PopupMenuItem<_ProfileAction>(
                  value: _ProfileAction.logout,
                  child: _ProfileMenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Đăng xuất',
                    color: AppColors.priceDown,
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: _buildAvatar(user?.avatarUrl, size: 34),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(String? avatarUrl, {required double size}) {
    final imageUrl = avatarUrl?.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: imageUrl == null || imageUrl.isEmpty
            ? const ColoredBox(
                color: Color(0xFF1E293B),
                child: Center(
                  child: Icon(Icons.person, color: Colors.white70, size: 20),
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFF1E293B),
                  child: Center(
                    child: Icon(Icons.person, color: Colors.white70, size: 20),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _handleProfileAction(_ProfileAction action) async {
    final user = ref.read(authProvider).value;
    if (action == _ProfileAction.editProfile) {
      await ProfileDialogs.showEditProfileDialog(
        context: context,
        ref: ref,
        user: user,
      );
      return;
    }

    if (action == _ProfileAction.changePassword) {
      await ProfileDialogs.showChangePasswordDialog(
        context: context,
        ref: ref,
      );
      return;
    }

    if (action == _ProfileAction.settings) {
      context.push('/home/settings');
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc muốn đăng xuất khỏi StockMate?',
          style: TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.priceDown),
            ),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  // --- 2. Virtual Balance Bar ---
  Widget _buildVirtualBalanceBar(DashboardData? data) {
    final accountLabel = data?.account.accountNumber ?? 'Đang tải...';
    final cashLabel = data?.assets.cashBalance.formatVnd() ?? 'Đang tải...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (data != null && data.accounts.length > 1)
                PopupMenuButton<int>(
                  tooltip: 'Chọn tài khoản',
                  padding: EdgeInsets.zero,
                  position: PopupMenuPosition.under,
                  color: AppColors.darkCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.darkCardBorder),
                  ),
                  onSelected: (id) {
                    ref.read(selectedAccountProvider.notifier).select(id);
                    ref.invalidate(dashboardProvider);
                  },
                  itemBuilder: (context) => data.accounts
                      .map(
                        (a) => PopupMenuItem<int>(
                          value: a.accountId,
                          child: Row(
                            children: [
                              Icon(
                                a.accountId == data.account.accountId
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color: a.accountId == data.account.accountId
                                    ? AppColors.primary
                                    : AppColors.darkTextSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                a.accountNumber,
                                style: TextStyle(
                                  color: a.accountId == data.account.accountId
                                      ? AppColors.primary
                                      : Colors.white,
                                  fontWeight: a.accountId == data.account.accountId
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.credit_card_outlined,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tài khoản $accountLabel',
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.darkTextSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.credit_card_outlined,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tài khoản $accountLabel',
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Thị trường',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số dư tiền mặt',
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cashLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/deposit'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                          size: 15,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Nạp tiền',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. Indices Section ---
  Widget _buildIndicesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CHỈ SỐ TRỰC TIẾP HOSE / HNX',
              style: TextStyle(
                color: Color(0xFF2DD4BF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const Text(
          'Khớp liên tục',
          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildIndicesCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildIndexCard(
            title: 'VN-INDEX',
            points: '1,284.50',
            change: '+12.35 (+0.97%)',
            isPositive: true,
          ),
          const SizedBox(width: 10),
          _buildIndexCard(
            title: 'VN30',
            points: '1,310.20',
            change: '+14.60 (+1.13%)',
            isPositive: true,
          ),
          const SizedBox(width: 10),
          _buildIndexCard(
            title: 'HNX-INDEX',
            points: '242.15',
            change: '-0.85 (-0.35%)',
            isPositive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildIndexCard({
    required String title,
    required String points,
    required String change,
    required bool isPositive,
  }) {
    final color = isPositive ? AppColors.primary : AppColors.priceDown;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => DashboardDialogs.showIndexDetailDialog(
          context,
          title: title,
          points: points,
          change: change,
          isPositive: isPositive,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 156,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: color,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                points,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                change,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. Market Breadth Card ---
  Widget _buildMarketBreadthCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => DashboardDialogs.showMarketBreadthDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Độ rộng toàn thị trường',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'Tích cực',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Multi-segmented bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const SizedBox(
                  height: 7,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 12,
                        child: ColoredBox(color: AppColors.priceCeiling),
                      ),
                      SizedBox(width: 2),
                      Expanded(
                        flex: 245,
                        child: ColoredBox(color: AppColors.primary),
                      ),
                      SizedBox(width: 2),
                      Expanded(
                        flex: 68,
                        child: ColoredBox(color: Color(0xFF06B6D4)),
                      ),
                      SizedBox(width: 2),
                      Expanded(
                        flex: 132,
                        child: ColoredBox(color: Color(0xFFF87171)),
                      ),
                      SizedBox(width: 2),
                      Expanded(
                        flex: 3,
                        child: ColoredBox(color: Color(0xFF38BDF8)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Counters row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBreadthStat('12 Trần', AppColors.priceCeiling),
                  _buildBreadthStat('245 Tăng', AppColors.primary),
                  _buildBreadthStat('68 TC', const Color(0xFF06B6D4)),
                  _buildBreadthStat('132 Giảm', const Color(0xFFF87171)),
                  _buildBreadthStat('3 Sàn', const Color(0xFF38BDF8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadthStat(String label, Color color) {
    final parts = label.split(' ');
    final count = parts.first;
    final text = parts.length > 1 ? parts.last : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count $text',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }

  // --- 5. Hot News / Highlight Card ---
  Widget _buildHotNewsCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => DashboardDialogs.showHotNewsDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: Color(0xFFC084FC),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ĐIỂM NÓNG HOSE',
                          style: TextStyle(
                            color: Color(0xFFC084FC),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Dòng tiền lan tỏa nhóm Bán Lẻ & Công Nghệ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Thanh khoản đạt 18.2K tỷ VNĐ, khối ngoại mua ròng SSI & MWG.',
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // News Thumbnail image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 76,
                  height: 76,
                  color: const Color(0xFF1E2838),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=200',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countForCategory(String cat, List<StockModel> stocks) {
    if (cat == 'Tất cả') return stocks.length;
    if (cat == 'HOSE') return stocks.where((s) => s.exchange == 'HOSE').length;
    if (cat == 'HNX') return stocks.where((s) => s.exchange == 'HNX').length;
    if (cat == 'VN30') {
      return stocks
          .where((s) => _vn30Set.contains(s.symbol.toUpperCase()))
          .length;
    }
    if (cat == 'Ngân hàng') {
      return stocks
          .where((s) =>
              (s.industry?.toLowerCase().contains('ngân hàng') == true) ||
              _bankingSet.contains(s.symbol.toUpperCase()))
          .length;
    }
    if (cat == 'Bất động sản') {
      return stocks
          .where((s) =>
              (s.industry?.toLowerCase().contains('bất động sản') == true) ||
              _reSet.contains(s.symbol.toUpperCase()))
          .length;
    }
    if (cat == 'Chứng khoán') {
      return stocks
          .where((s) =>
              (s.industry?.toLowerCase().contains('chứng khoán') == true) ||
              (s.industry?.toLowerCase().contains('tài chính') == true) ||
              _secSet.contains(s.symbol.toUpperCase()))
          .length;
    }
    if (cat == 'Thép') {
      return stocks
          .where((s) =>
              (s.industry?.toLowerCase().contains('thép') == true) ||
              (s.industry?.toLowerCase().contains('tài nguyên') == true) ||
              _steelSet.contains(s.symbol.toUpperCase()))
          .length;
    }
    if (cat == 'Năng lượng') {
      return stocks
          .where((s) =>
              (s.industry?.toLowerCase().contains('điện') == true) ||
              (s.industry?.toLowerCase().contains('xăng dầu') == true) ||
              (s.industry?.toLowerCase().contains('năng lượng') == true) ||
              _energySet.contains(s.symbol.toUpperCase()))
          .length;
    }
    if (cat == 'Bán lẻ & Tiêu dùng') {
      return stocks
          .where((s) =>
              (s.industry?.toLowerCase().contains('bán lẻ') == true) ||
              (s.industry?.toLowerCase().contains('tiêu dùng') == true) ||
              (s.industry?.toLowerCase().contains('thực phẩm') == true) ||
              _retailSet.contains(s.symbol.toUpperCase()))
          .length;
    }
    return stocks.length;
  }

  List<StockModel> _getFilteredStocks(List<StockModel> baseStocks) {
    final filtered = baseStocks.where((stock) {
      if (_selectedCategory == 'Tất cả') return true;
      if (_selectedCategory == 'HOSE') return stock.exchange == 'HOSE';
      if (_selectedCategory == 'HNX') return stock.exchange == 'HNX';
      if (_selectedCategory == 'VN30') {
        return _vn30Set.contains(stock.symbol.toUpperCase());
      }
      if (_selectedCategory == 'Ngân hàng') {
        return (stock.industry?.toLowerCase().contains('ngân hàng') == true) ||
            _bankingSet.contains(stock.symbol.toUpperCase());
      }
      if (_selectedCategory == 'Bất động sản') {
        return (stock.industry?.toLowerCase().contains('bất động sản') ==
                true) ||
            _reSet.contains(stock.symbol.toUpperCase());
      }
      if (_selectedCategory == 'Chứng khoán') {
        return (stock.industry?.toLowerCase().contains('chứng khoán') ==
                true) ||
            (stock.industry?.toLowerCase().contains('tài chính') == true) ||
            _secSet.contains(stock.symbol.toUpperCase());
      }
      if (_selectedCategory == 'Thép') {
        return (stock.industry?.toLowerCase().contains('thép') == true) ||
            (stock.industry?.toLowerCase().contains('tài nguyên') == true) ||
            _steelSet.contains(stock.symbol.toUpperCase());
      }
      if (_selectedCategory == 'Năng lượng') {
        return (stock.industry?.toLowerCase().contains('điện') == true) ||
            (stock.industry?.toLowerCase().contains('xăng dầu') == true) ||
            (stock.industry?.toLowerCase().contains('năng lượng') == true) ||
            _energySet.contains(stock.symbol.toUpperCase());
      }
      if (_selectedCategory == 'Bán lẻ & Tiêu dùng') {
        return (stock.industry?.toLowerCase().contains('bán lẻ') == true) ||
            (stock.industry?.toLowerCase().contains('tiêu dùng') == true) ||
            (stock.industry?.toLowerCase().contains('thực phẩm') == true) ||
            _retailSet.contains(stock.symbol.toUpperCase());
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'gain':
          return b.changePercent.compareTo(a.changePercent);
        case 'loss':
          return a.changePercent.compareTo(b.changePercent);
        case 'price_high':
          return b.currentPrice.compareTo(a.currentPrice);
        case 'price_low':
          return a.currentPrice.compareTo(b.currentPrice);
        case 'alpha':
          return a.symbol.compareTo(b.symbol);
        case 'volume':
        default:
          return b.totalVolume.compareTo(a.totalVolume);
      }
    });

    return filtered;
  }

  // --- 6. Category Filter Chips ---
  Widget _buildCategoryChips(List<StockModel> stocks) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final cat in _categories)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = cat),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: cat == _selectedCategory
                        ? AppColors.primary
                        : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cat == _selectedCategory
                          ? AppColors.primary
                          : AppColors.darkCardBorder,
                      width: 0.8,
                    ),
                    boxShadow: cat == _selectedCategory
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat,
                        style: TextStyle(
                          color: cat == _selectedCategory
                              ? const Color(0xFF032617)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: cat == _selectedCategory
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cat == _selectedCategory
                              ? const Color(0xFF032617).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_countForCategory(cat, stocks)}',
                          style: TextStyle(
                            color: cat == _selectedCategory
                                ? const Color(0xFF032617)
                                : AppColors.darkTextSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 7. Price Board Header & Sort ---
  Widget _buildPriceBoardHeader(int count) {
    final sortMeta =
        _sortOptions[_selectedSort] ?? ('Top Khối lượng', Icons.bar_chart_rounded);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Flexible(
                    child: Text(
                      'BẢNG GIÁ TRỰC TUYẾN',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '$count mã',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Real working PopupMenuButton with all sort options
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn sắp xếp',
              color: AppColors.darkCard,
              elevation: 10,
              offset: const Offset(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.darkCardBorder),
              ),
              initialValue: _selectedSort,
              onSelected: (val) => setState(() => _selectedSort = val),
              itemBuilder: (context) => _sortOptions.entries.map((entry) {
                final isSelected = entry.key == _selectedSort;
                return PopupMenuItem<String>(
                  value: entry.key,
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        entry.value.$2,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.darkTextSecondary,
                        size: 15,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value.$1,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                    ],
                  ),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sortMeta.$2, color: AppColors.primary, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      sortMeta.$1,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Columns header with aligned flex
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.darkCard.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'MÃ / DOANH NGHIỆP',
                  style: TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    'XU HƯỚNG',
                    style: TextStyle(
                      color: AppColors.darkTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'GIÁ KHỚP / +/-',
                    style: TextStyle(
                      color: AppColors.darkTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 8. Stocks Table ---
  Widget _buildStockTable(List<StockModel> filtered) {
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
        ),
        alignment: Alignment.center,
        child: Text(
          'Không có mã cổ phiếu nào thuộc nhóm "$_selectedCategory"',
          style: const TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
      ),
      child: Column(
        children: filtered.asMap().entries.map((entry) {
          final index = entry.key;
          final stock = entry.value;
          final isLast = index == filtered.length - 1;

          final priceColor = _getPriceColor(stock.priceState);
          final points = _getSparklinePoints(stock);

          String badge;
          Color badgeBg;
          Color badgeText;
          if (stock.priceState == PriceState.ceiling) {
            badge = 'TRẦN';
            badgeBg = const Color(0xFF8B5CF6);
            badgeText = Colors.white;
          } else if (stock.priceState == PriceState.floor) {
            badge = 'SÀN';
            badgeBg = const Color(0xFF06B6D4);
            badgeText = Colors.black;
          } else {
            badge = stock.exchange;
            badgeBg = const Color(0xFF1E293B);
            badgeText = AppColors.darkTextSecondary;
          }

          final priceFormatted = (stock.currentPrice / 1000).toStringAsFixed(2);
          final changeAmountFormatted =
              (stock.changeAmount / 1000).toStringAsFixed(2);
          final changeFormatted =
              '${stock.changeAmount >= 0 ? '+' : ''}$changeAmountFormatted (${stock.changeAmount >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%)';
          final volumeFormatted = stock.totalVolume >= 1000000
              ? '${(stock.totalVolume / 1000000).toStringAsFixed(2)}M'
              : stock.totalVolume >= 1000
                  ? '${(stock.totalVolume / 1000).toStringAsFixed(1)}K'
                  : stock.totalVolume.toString();

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => DashboardDialogs.showStockActionSheet(context, stock),
              borderRadius: BorderRadius.vertical(
                top: index == 0 ? const Radius.circular(16) : Radius.zero,
                bottom: isLast ? const Radius.circular(16) : Radius.zero,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05),
                            width: 0.8,
                          ),
                        ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Column 1: Symbol & Company info (flex: 4)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                stock.symbol,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: stock.priceState ==
                                                PriceState.ceiling ||
                                            stock.priceState ==
                                                PriceState.floor
                                        ? Colors.transparent
                                        : AppColors.darkCardBorder,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  badge,
                                  style: TextStyle(
                                    color: badgeText,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            stock.companyName,
                            style: const TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                size: 12,
                                color: AppColors.darkTextMuted
                                    .withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'KL: $volumeFormatted',
                                style: const TextStyle(
                                  color: AppColors.darkTextMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Column 2: Sparkline Trend (flex: 3)
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: SparklineChart(
                          data: points,
                          color: priceColor,
                          width: 72,
                          height: 28,
                        ),
                      ),
                    ),

                    // Column 3: Price & Change badge (flex: 4)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            priceFormatted,
                            style: TextStyle(
                              color: priceColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: priceColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: priceColor.withValues(alpha: 0.35),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              changeFormatted,
                              style: TextStyle(
                                color: priceColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getPriceColor(PriceState state) {
    switch (state) {
      case PriceState.ceiling:
        return AppColors.priceCeiling;
      case PriceState.floor:
        return AppColors.priceFloor;
      case PriceState.up:
        return AppColors.priceUp;
      case PriceState.down:
        return AppColors.priceDown;
      case PriceState.reference:
        return AppColors.priceRef;
    }
  }

  List<double> _getSparklinePoints(StockModel stock) {
    switch (stock.priceState) {
      case PriceState.ceiling:
        return const [0.3, 0.45, 0.6, 0.75, 0.85, 0.95, 1.0];
      case PriceState.floor:
        return const [0.95, 0.8, 0.6, 0.45, 0.3, 0.15, 0.05];
      case PriceState.up:
        return const [0.25, 0.35, 0.3, 0.5, 0.65, 0.75, 0.85];
      case PriceState.down:
        return const [0.85, 0.75, 0.7, 0.55, 0.45, 0.35, 0.25];
      case PriceState.reference:
        return const [0.5, 0.52, 0.48, 0.51, 0.49, 0.5, 0.5];
    }
  }

  static const List<StockModel> _defaultStocks = [
    StockModel(
      id: 1,
      symbol: 'MWG',
      companyName: 'CTCP Thế Giới Di Động',
      exchange: 'HOSE',
      industry: 'Bán lẻ',
      currentPrice: 64500,
      referencePrice: 60300,
      ceilingPrice: 64500,
      floorPrice: 56100,
      totalVolume: 8900000,
    ),
    StockModel(
      id: 2,
      symbol: 'FPT',
      companyName: 'CTCP FPT',
      exchange: 'HOSE',
      industry: 'Công nghệ',
      currentPrice: 135200,
      referencePrice: 130400,
      ceilingPrice: 139500,
      floorPrice: 121300,
      totalVolume: 4200000,
    ),
    StockModel(
      id: 3,
      symbol: 'SSI',
      companyName: 'CTCP Chứng khoán SSI',
      exchange: 'HOSE',
      industry: 'Chứng khoán',
      currentPrice: 34600,
      referencePrice: 33400,
      ceilingPrice: 35700,
      floorPrice: 31100,
      totalVolume: 12100000,
    ),
    StockModel(
      id: 4,
      symbol: 'HPG',
      companyName: 'CTCP Tập đoàn Hòa Phát',
      exchange: 'HOSE',
      industry: 'Thép',
      currentPrice: 28900,
      referencePrice: 29300,
      ceilingPrice: 31300,
      floorPrice: 27200,
      totalVolume: 15700000,
    ),
  ];
}
