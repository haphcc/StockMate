import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/price_colors.dart';
import '../../../data/models/stock_model.dart';
import '../../../l10n/app_localizations.dart';

abstract final class DashboardDialogs {
  /// Opens a stock action sheet allowing the user to view quick details and trade immediately.
  static void showStockActionSheet(BuildContext context, StockModel stock) {
    final l10n = AppLocalizations.of(context);
    Color priceColor;
    switch (stock.priceState) {
      case PriceState.ceiling:
        priceColor = AppColors.priceCeiling;
      case PriceState.floor:
        priceColor = AppColors.priceFloor;
      case PriceState.up:
        priceColor = AppColors.priceUp;
      case PriceState.down:
        priceColor = AppColors.priceDown;
      case PriceState.reference:
        priceColor = AppColors.priceRef;
    }

    final priceFormatted = (stock.currentPrice / 1000).toStringAsFixed(1);
    final refFormatted = (stock.referencePrice / 1000).toStringAsFixed(1);
    final ceilFormatted = (stock.ceilingPrice / 1000).toStringAsFixed(1);
    final floorFormatted = (stock.floorPrice / 1000).toStringAsFixed(1);
    final volumeFormatted = stock.totalVolume >= 1000000
        ? '${(stock.totalVolume / 1000000).toStringAsFixed(1)}M'
        : stock.totalVolume >= 1000
            ? '${(stock.totalVolume / 1000).toStringAsFixed(1)}K'
            : stock.totalVolume.toString();

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppColors.darkCardBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        stock.symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.darkCardBorder),
                        ),
                        child: Text(
                          stock.exchange,
                          style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$priceFormatted đ',
                        style: TextStyle(
                          color: priceColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${stock.changeAmount >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: priceColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stock.companyName,
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Price Details Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(l10n.statRef, refFormatted, AppColors.priceRef),
                    _statItem(l10n.statCeil, ceilFormatted, AppColors.priceCeiling),
                    _statItem(l10n.statFloor, floorFormatted, AppColors.priceFloor),
                    _statItem(l10n.statVolume, volumeFormatted, Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Trade Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        context.go('/home/trade?symbol=${stock.symbol}&side=buy&price=$priceFormatted');
                      },
                      icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                      label: Text('${l10n.buyAction} ${stock.symbol}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        context.go('/home/trade?symbol=${stock.symbol}&side=sell&price=$priceFormatted');
                      },
                      icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                      label: Text('${l10n.sellAction} ${stock.symbol}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.priceDown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    context.push('/home/overview/stock/${stock.symbol}');
                  },
                  icon: const Icon(Icons.candlestick_chart_rounded, size: 18),
                  label: Text(l10n.isVietnamese ? 'Xem biểu đồ nến & chi tiết' : 'Candlestick Chart & Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.darkCardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Opens the details dialog for an Index (VN-INDEX, VN30, HNX-INDEX).
  static void showIndexDetailDialog(
    BuildContext context, {
    required String title,
    required String points,
    required String change,
    required bool isPositive,
  }) {
    final l10n = AppLocalizations.of(context);
    final color = isPositive ? AppColors.primary : AppColors.priceDown;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkCardBorder),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                change,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              points,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.isVietnamese
                  ? 'Trạng thái: Khớp lệnh liên tục (Thị trường mở cửa)'
                  : 'Status: Continuous Matching (Market Open)',
              style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: l10n.isVietnamese ? 'Tổng giá trị giao dịch' : 'Total Turnover',
                    value: l10n.isVietnamese ? '18,245.8 tỷ VNĐ' : '18,245.8B VND',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: l10n.isVietnamese ? 'Tổng khối lượng' : 'Total Volume',
                    value: l10n.isVietnamese ? '782.4 triệu CP' : '782.4M shares',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: l10n.isVietnamese ? 'Khối ngoại mua ròng' : 'Foreign Net Buy',
                    value: l10n.isVietnamese ? '+426.5 tỷ VNĐ' : '+426.5B VND',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: l10n.isVietnamese ? 'Số mã Tăng / Giảm / Đứng' : 'Gainers / Losers / Flat',
                    value: '245 / 132 / 68',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.isVietnamese ? 'Đóng' : 'Close', style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  /// Opens the Market Breadth detailed overview dialog.
  static void showMarketBreadthDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkCardBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              l10n.isVietnamese ? 'Độ rộng toàn thị trường' : 'Market Breadth Overview',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.isVietnamese
                  ? 'Tỷ lệ phân bổ trạng thái các mã cổ phiếu đang giao dịch trên cả 3 sàn (HOSE, HNX, UPCOM):'
                  : 'Status distribution of active stocks traded across all 3 exchanges (HOSE, HNX, UPCOM):',
              style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: l10n.isVietnamese ? 'Mã kịch trần' : 'Ceiling',
                    value: l10n.isVietnamese ? '12 mã (2.6%)' : '12 symbols (2.6%)',
                    valueColor: AppColors.priceCeiling,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: l10n.isVietnamese ? 'Mã tăng giá' : 'Gainers',
                    value: l10n.isVietnamese ? '245 mã (53.3%)' : '245 symbols (53.3%)',
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: l10n.isVietnamese ? 'Mã tham chiếu' : 'Reference',
                    value: l10n.isVietnamese ? '68 mã (14.8%)' : '68 symbols (14.8%)',
                    valueColor: const Color(0xFF06B6D4),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: l10n.isVietnamese ? 'Mã giảm giá' : 'Losers',
                    value: l10n.isVietnamese ? '132 mã (28.7%)' : '132 symbols (28.7%)',
                    valueColor: const Color(0xFFF87171),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: l10n.isVietnamese ? 'Mã chạm sàn' : 'Floor',
                    value: l10n.isVietnamese ? '3 mã (0.6%)' : '3 symbols (0.6%)',
                    valueColor: const Color(0xFF38BDF8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.isVietnamese
                  ? 'Nhận định: Phe mua chiếm ưu thế áp đảo với hơn 55% mã tăng giá, dòng tiền tập trung mạnh tại nhóm vốn hóa lớn và trung bình.'
                  : 'Insight: Buyers dominate with over 55% advancing stocks, strong liquidity concentrated in large & mid-cap sectors.',
              style: const TextStyle(color: AppColors.primary, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.isVietnamese ? 'Đóng' : 'Close', style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  /// Opens the Hot News detailed article dialog.
  static void showHotNewsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkCardBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFC084FC)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.isVietnamese ? 'Điểm nóng thị trường' : 'Market Highlights',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.hotNewsHeadline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.isVietnamese
                    ? 'Ngày hôm nay, chỉ số VN-Index ghi nhận đà bứt phá mạnh mẽ vượt ngưỡng kháng cự tâm lý. Nhóm cổ phiếu công nghệ thông tin (FPT, ELC) và bán lẻ (MWG, FRT, DGW) dẫn dắt chỉ số tăng điểm với thanh khoản đột biến.'
                    : 'Today, the VN-Index achieved a strong breakthrough past psychological resistance. Tech (FPT, ELC) and Retail (MWG, FRT, DGW) led gains with surging liquidity.',
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.isVietnamese ? 'Điểm nổi bật phiên giao dịch:' : 'Trading Session Highlights:',
                style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.isVietnamese
                    ? '• Khối ngoại mua ròng hơn 420 tỷ đồng, tập trung mạnh nhất vào SSI (+150 tỷ), MWG (+95 tỷ) và FPT (+80 tỷ).\n• Nhóm ngành Thép (HPG, HSG) giữ vững vùng tham chiếu, sẵn sàng cho nhịp tích lũy mới.\n• Khuyến nghị: Nhà đầu tư duy trì tỷ trọng danh mục ở mức an toàn 60-70% cổ phiếu.'
                    : '• Foreign net buy exceeded 420B VND, led by SSI (+150B), MWG (+95B) and FPT (+80B).\n• Steel sector (HPG, HSG) held firm at reference, priming for accumulation.\n• Strategy: Maintain equity allocation at a safe 60-70%.',
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.isVietnamese ? 'Đóng' : 'Close', style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
