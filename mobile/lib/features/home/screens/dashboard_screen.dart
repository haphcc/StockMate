import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sparkline_chart.dart';
import '../../market/data/market_fixtures.dart';
import '../../market/widgets/market_components.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _exchange = 'HOSE';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(dashboardProvider);
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              MarketHeader(
                onNotifications: () =>
                    context.push('/home/overview/notifications'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thị trường',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Thứ Hai, 14 tháng 11  ·  Đóng cửa',
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _indexCard(),
                    const SizedBox(height: 24),
                    const SectionTitle('Bảng giá'),
                    const SizedBox(height: 12),
                    _exchangeFilters(),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toUpperCase()),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tìm mã hoặc tên công ty',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.darkTextMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.darkCardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.darkCardBorder,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    board.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(36),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (error, _) => _loadError(error.toString()),
                      data: (data) {
                        final all = data.marketBoard.isEmpty
                            ? marketStocks
                            : data.marketBoard;
                        final stocks = all
                            .where(
                              (stock) =>
                                  (_exchange == 'Tất cả' ||
                                      stock.exchange == _exchange) &&
                                  (_query.isEmpty ||
                                      stock.symbol.contains(_query) ||
                                      stock.companyName.toUpperCase().contains(
                                        _query,
                                      )),
                            )
                            .toList();
                        return MarketPanel(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                          child: Column(
                            children: [
                              _tableHeader(),
                              const Divider(
                                color: AppColors.darkCardBorder,
                                height: 22,
                              ),
                              if (stocks.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Không tìm thấy mã phù hợp',
                                    style: TextStyle(
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                )
                              else
                                ...stocks.map(
                                  (stock) => _stockRow(
                                    stock.symbol,
                                    stock.companyName,
                                    formatBoardPrice(stock.currentPrice),
                                    stock.changeAmount,
                                    stock.changePercent,
                                    formatVolume(stock.totalVolume),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Dữ liệu mô phỏng · Cập nhật 15:00',
                      style: TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 11,
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
  }

  Widget _indexCard() => MarketPanel(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'VN-INDEX',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
              ),
            ),
            const Spacer(),
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
              'ĐANG GIAO DỊCH',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '1,284.50',
              style: TextStyle(
                color: Colors.white,
                fontSize: 31,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                '+12.35  (+0.97%)',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SparklineChart(
          width: double.infinity,
          height: 54,
          color: AppColors.primary,
          data: [
            0.35,
            .39,
            .31,
            .48,
            .43,
            .56,
            .51,
            .63,
            .58,
            .71,
            .68,
            .84,
            .78,
            .92,
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            _Breadth(label: 'Tăng', count: '182', color: AppColors.priceUp),
            SizedBox(width: 16),
            _Breadth(label: 'Đứng', count: '74', color: AppColors.priceRef),
            SizedBox(width: 16),
            _Breadth(label: 'Giảm', count: '96', color: AppColors.priceDown),
            Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.darkTextMuted,
              size: 18,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _exchangeFilters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: ['HOSE', 'HNX', 'UPCOM', 'Tất cả']
          .map(
            (label) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChipPill(
                label: label,
                selected: _exchange == label,
                onTap: () => setState(() => _exchange = label),
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _tableHeader() => const Row(
    children: [
      Expanded(
        flex: 5,
        child: Text(
          'MÃ CK / KHỐI LƯỢNG',
          style: TextStyle(
            color: AppColors.darkTextMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: Text(
          'GIÁ / THAY ĐỔI',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.darkTextMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
      ),
    ],
  );

  Widget _stockRow(
    String symbol,
    String name,
    String price,
    int change,
    double percent,
    String volume,
  ) {
    final color = change > 0
        ? AppColors.priceUp
        : change < 0
        ? AppColors.priceDown
        : AppColors.priceRef;
    return InkWell(
      onTap: () => context.push('/home/overview/stock/$symbol'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SymbolBadge(symbol, size: 40),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$name  ·  $volume cp',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${change > 0 ? '+' : ''}${(change / 1000).toStringAsFixed(1)}  ${percent > 0 ? '+' : ''}${percent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadError(String message) => MarketPanel(
    child: Row(
      children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.darkTextMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Chưa tải được bảng giá. $message',
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Breadth extends StatelessWidget {
  const _Breadth({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final String count;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        '$label $count',
        style: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 10,
        ),
      ),
    ],
  );
}
