import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sparkline_chart.dart';
import '../../../core/widgets/stockmate_brand.dart';
import '../providers/dashboard_provider.dart';

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
    'HOSE',
    'HNX',
    'Ngân hàng',
    'Bất động sản',
    'Chứng khoán',
    'Thép',
  ];

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkSurface,
          onRefresh: () async => ref.refresh(dashboardProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header Bar
                _buildTopHeader(),
                const SizedBox(height: 14),

                // 2. Virtual Balance Bar
                _buildVirtualBalanceBar(),
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
                _buildCategoryChips(),
                const SizedBox(height: 18),

                // 7. Online Price Board Header & Sort
                _buildPriceBoardHeader(),
                const SizedBox(height: 12),

                // 8. Stocks List
                dashboardAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Lỗi tải dữ liệu: $err', style: const TextStyle(color: AppColors.priceDown)),
                    ),
                  ),
                  data: (data) => _buildStockTable(),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Top Header Bar ---
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Logo + LIVE Badge
        const StockMateBrand(
          iconSize: 28,
          fontSize: 19,
          showLiveBadge: true,
        ),

        // Right Actions: Search, Notification with dot, Avatar
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
              onPressed: () {},
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            const SizedBox(width: 4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // User Avatar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.network(
                  'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF1E293B),
                    child: const Icon(Icons.person, color: Colors.white70, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. Virtual Balance Bar ---
  Widget _buildVirtualBalanceBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.credit_card_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tài khoản Giả lập: ',
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: '1,000,000,000 đ',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Thị Trường',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
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
          style: TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 11,
          ),
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

    return Container(
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
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
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
    );
  }

  // --- 4. Market Breadth Card ---
  Widget _buildMarketBreadthCard() {
    return Container(
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
              Row(
                children: const [
                  Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 0.8),
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
            child: SizedBox(
              height: 7,
              child: Row(
                children: const [
                  Expanded(flex: 12, child: ColoredBox(color: AppColors.priceCeiling)),
                  SizedBox(width: 2),
                  Expanded(flex: 245, child: ColoredBox(color: AppColors.primary)),
                  SizedBox(width: 2),
                  Expanded(flex: 68, child: ColoredBox(color: Color(0xFF06B6D4))),
                  SizedBox(width: 2),
                  Expanded(flex: 132, child: ColoredBox(color: Color(0xFFF87171))),
                  SizedBox(width: 2),
                  Expanded(flex: 3, child: ColoredBox(color: Color(0xFF38BDF8))),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // --- 5. Hot News / Highlight Card ---
  Widget _buildHotNewsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.stars_rounded, color: Color(0xFFC084FC), size: 16),
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
                const SizedBox(height: 6),
                const Text(
                  'Dòng tiền lan tỏa nhóm Bán Lẻ & Công Nghệ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
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
                  child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Category Filter Chips ---
  Widget _buildCategoryChips() {
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cat == _selectedCategory ? AppColors.primary : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cat == _selectedCategory ? AppColors.primary : AppColors.darkCardBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: cat == _selectedCategory ? const Color(0xFF032617) : Colors.white,
                      fontSize: 12,
                      fontWeight: cat == _selectedCategory ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 7. Price Board Header & Sort ---
  Widget _buildPriceBoardHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BẢNG GIÁ TRỰC TUYẾN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              children: [
                // Top Khối lượng pill
                InkWell(
                  onTap: () => setState(() => _selectedSort = 'volume'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedSort == 'volume' ? AppColors.primary.withValues(alpha: 0.5) : AppColors.darkCardBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Top Khối lượng',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Top Tăng pill
                InkWell(
                  onTap: () => setState(() => _selectedSort = 'gain'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedSort == 'gain' ? AppColors.primary : AppColors.darkCardBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'Top Tăng',
                      style: TextStyle(
                        color: _selectedSort == 'gain' ? AppColors.primary : AppColors.darkTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Columns header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'MÃ / CÔNG TY',
              style: TextStyle(
                color: AppColors.darkTextMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'XU HƯỚNG',
              style: TextStyle(
                color: AppColors.darkTextMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'KHỚP / THAY ĐỔI',
              style: TextStyle(
                color: AppColors.darkTextMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 8. Stocks Table ---
  Widget _buildStockTable() {
    const stocks = [
      _StockViewItem(
        symbol: 'MWG',
        badge: 'TRẦN',
        badgeBg: Color(0xFF8B5CF6),
        badgeText: Colors.white,
        companyName: 'Thế Giới Di Động',
        volume: '8.9M',
        price: '64.5',
        change: '+4.2 +6.97%',
        trendColor: AppColors.priceCeiling,
        points: [0.3, 0.4, 0.45, 0.65, 0.7, 0.85, 0.95],
      ),
      _StockViewItem(
        symbol: 'FPT',
        badge: 'HOSE',
        badgeBg: Color(0xFF1E293B),
        badgeText: AppColors.darkTextSecondary,
        companyName: 'Tập đoàn FPT',
        volume: '4.2M',
        price: '135.2',
        change: '+4.8 +3.68%',
        trendColor: AppColors.primary,
        points: [0.25, 0.2, 0.45, 0.4, 0.6, 0.75, 0.85],
      ),
      _StockViewItem(
        symbol: 'SSI',
        badge: 'HOSE',
        badgeBg: Color(0xFF1E293B),
        badgeText: AppColors.darkTextSecondary,
        companyName: 'Chứng khoán SSI',
        volume: '12.1M',
        price: '34.6',
        change: '+1.2 +3.59%',
        trendColor: AppColors.primary,
        points: [0.3, 0.25, 0.38, 0.48, 0.6, 0.7, 0.8],
      ),
      _StockViewItem(
        symbol: 'HPG',
        badge: 'HOSE',
        badgeBg: Color(0xFF1E293B),
        badgeText: AppColors.darkTextSecondary,
        companyName: 'Tập đoàn Hòa Phát',
        volume: '15.7M',
        price: '28.9',
        change: '-0.4 -1.37%',
        trendColor: AppColors.priceDown,
        points: [0.75, 0.7, 0.6, 0.65, 0.45, 0.4, 0.25],
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCardBorder, width: 0.8),
      ),
      child: Column(
        children: stocks.asMap().entries.map((entry) {
          final index = entry.key;
          final stock = entry.value;
          final isLast = index == stocks.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                // Column 1: Symbol & Company info
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: stock.badgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              stock.badge,
                              style: TextStyle(
                                color: stock.badgeText,
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
                      const SizedBox(height: 2),
                      Text(
                        'KL: ${stock.volume}',
                        style: const TextStyle(
                          color: AppColors.darkTextMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Column 2: Sparkline Trend
                Expanded(
                  flex: 3,
                  child: Center(
                    child: SparklineChart(
                      data: stock.points,
                      color: stock.trendColor,
                      width: 64,
                      height: 24,
                    ),
                  ),
                ),

                // Column 3: Price & Change badge
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        stock.price,
                        style: TextStyle(
                          color: stock.trendColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: stock.trendColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stock.change,
                          style: TextStyle(
                            color: stock.trendColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StockViewItem {
  final String symbol;
  final String badge;
  final Color badgeBg;
  final Color badgeText;
  final String companyName;
  final String volume;
  final String price;
  final String change;
  final Color trendColor;
  final List<double> points;

  const _StockViewItem({
    required this.symbol,
    required this.badge,
    required this.badgeBg,
    required this.badgeText,
    required this.companyName,
    required this.volume,
    required this.price,
    required this.change,
    required this.trendColor,
    required this.points,
  });
}
