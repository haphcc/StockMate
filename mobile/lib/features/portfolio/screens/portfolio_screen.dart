import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stockmate_brand.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../providers/account_providers.dart';
import '../../../providers/app_providers.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(assetsProvider);
    ref.invalidate(portfolioProvider);
    await Future.wait([
      ref.read(assetsProvider.future),
      ref.read(portfolioProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final assets = ref.watch(assetsProvider);
    final portfolio = ref.watch(portfolioProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(l10n.portfolioTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: StockMateBrand(iconSize: 24, fontSize: 16),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            assets.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (value) => _AssetCard(asset: value),
            ),
            const SizedBox(height: 24),
            portfolio.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (items) => items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          l10n.noHoldings,
                          style: const TextStyle(color: AppColors.darkTextSecondary),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.holdingsHeader,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.holdingsCount(items.length),
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HoldingItem(item: item),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends ConsumerWidget {
  final AssetModel? asset;
  const _AssetCard({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    if (asset == null) {
      return _ErrorCard(
        message: l10n.isVietnamese
            ? 'Không có tài khoản CASH đang hoạt động.'
            : 'No active CASH account found.',
      );
    }
    final a = asset!;
    final c = a.totalProfitLoss.cents >= 0
        ? AppColors.primary
        : AppColors.priceDown;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162232), Color(0xFF131926)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalNetAssets,
            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            a.totalAssetValue.formatVnd(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(l10n.profitLoss, a.totalProfitLoss.formatVnd(), c),
              _Stat(l10n.buyingPower, a.cashBalance.formatVnd(), Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Text(
        message,
        style: const TextStyle(color: AppColors.priceDown),
      );
}

class _HoldingItem extends StatelessWidget {
  final PortfolioModel item;
  const _HoldingItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isProfitable = item.profitLoss.cents >= 0;
    final colorProfit =
        isProfitable ? AppColors.primary : AppColors.priceDown;
    final percentStr = item.profitLossPercent != null
        ? '${isProfitable ? '+' : ''}${item.profitLossPercent!.decimalString}%'
        : '—';
    final hasAvailable = item.availableQuantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/home/overview/stock/${item.stockSymbol}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header mã cổ phiếu & Lãi/Lỗ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.stockSymbol,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (item.exchange.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              item.exchange,
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isProfitable ? '+' : ''}${item.profitLoss.formatVnd()}',
                          style: TextStyle(
                            color: colorProfit,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          percentStr,
                          style: TextStyle(
                            color: colorProfit,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  item.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 11,
                  ),
                ),
                const Divider(color: AppColors.darkCardBorder, height: 20),

                // Grid thông số chi tiết
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _holdingStat(
                      l10n.isVietnamese ? 'Khối lượng' : 'Quantity',
                      '${item.quantity}',
                      subLabel: '${l10n.isVietnamese ? 'Khả dụng' : 'Available'}: ${item.availableQuantity}',
                    ),
                    _holdingStat(
                      l10n.isVietnamese ? 'Giá vốn' : 'Avg Cost',
                      '${item.averagePrice.decimalString} ₫',
                      subLabel: '${l10n.isVietnamese ? 'TT' : 'Market'}: ${item.marketPrice.decimalString} ₫',
                    ),
                    _holdingStat(
                      l10n.isVietnamese ? 'Giá trị' : 'Market Value',
                      item.currentValue.formatVnd(),
                      alignRight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Hàng nút thao tác Mua thêm / Bán / Biểu đồ
                Row(
                  children: [
                    // Nút Bán
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: hasAvailable
                            ? () => context.go(
                                  '/home/trade?symbol=${item.stockSymbol}&side=SELL',
                                )
                            : null,
                        icon: const Icon(Icons.arrow_downward_rounded, size: 15),
                        label: Text(
                          hasAvailable
                              ? (l10n.isVietnamese
                                  ? 'Bán (${item.availableQuantity})'
                                  : 'Sell (${item.availableQuantity})')
                              : (l10n.isVietnamese ? 'Chờ về' : 'Pending'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.priceDown,
                          side: BorderSide(
                            color: hasAvailable
                                ? AppColors.priceDown.withValues(alpha: 0.6)
                                : AppColors.darkCardBorder,
                          ),
                          disabledForegroundColor: AppColors.darkTextMuted,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nút Mua thêm
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go(
                          '/home/trade?symbol=${item.stockSymbol}&side=BUY',
                        ),
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: Text(l10n.isVietnamese ? 'Mua thêm' : 'Buy More'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: const Color(0xFF06251C),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nút xem chi tiết biểu đồ nến
                    IconButton(
                      onPressed: () => context.push(
                        '/home/overview/stock/${item.stockSymbol}',
                      ),
                      icon: const Icon(
                        Icons.candlestick_chart_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.darkSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                          side: const BorderSide(
                            color: AppColors.darkCardBorder,
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                      ),
                      tooltip: l10n.isVietnamese ? 'Xem biểu đồ nến' : 'Candlestick Chart',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _holdingStat(
    String label,
    String value, {
    String? subLabel,
    bool alignRight = false,
  }) =>
      Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 1),
            Text(
              subLabel,
              style: const TextStyle(
                color: AppColors.darkTextMuted,
                fontSize: 10,
              ),
            ),
          ],
        ],
      );
}
