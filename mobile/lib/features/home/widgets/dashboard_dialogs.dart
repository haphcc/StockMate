import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/price_colors.dart';
import '../../../data/models/stock_model.dart';

abstract final class DashboardDialogs {
  /// Opens a stock action sheet allowing the user to view quick details and trade immediately.
  static void showStockActionSheet(BuildContext context, StockModel stock) {
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
                  _statItem('Tham chiếu', refFormatted, AppColors.priceRef),
                  _statItem('Trần', ceilFormatted, AppColors.priceCeiling),
                  _statItem('Sàn', floorFormatted, AppColors.priceFloor),
                  _statItem('Khối lượng', volumeFormatted, Colors.white),
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
                      context.push('/home/trade?symbol=${stock.symbol}&side=buy&price=$priceFormatted');
                    },
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    label: Text('MUA ${stock.symbol}'),
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
                      context.push('/home/trade?symbol=${stock.symbol}&side=sell&price=$priceFormatted');
                    },
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: Text('BÁN ${stock.symbol}'),
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
                label: const Text('Xem biểu đồ nến & chi tiết'),
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
            const Text(
              'Trạng thái: Khớp lệnh liên tục (Thị trường mở cửa)',
              style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: const Column(
                children: [
                  _DetailRow(label: 'Tổng giá trị giao dịch', value: '18,245.8 tỷ VNĐ'),
                  SizedBox(height: 8),
                  _DetailRow(label: 'Tổng khối lượng', value: '782.4 triệu CP'),
                  SizedBox(height: 8),
                  _DetailRow(label: 'Khối ngoại mua ròng', value: '+426.5 tỷ VNĐ'),
                  SizedBox(height: 8),
                  _DetailRow(label: 'Số mã Tăng / Giảm / Đứng', value: '245 / 132 / 68'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  /// Opens the Market Breadth detailed overview dialog.
  static void showMarketBreadthDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkCardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Độ rộng toàn thị trường',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tỷ lệ phân bổ trạng thái các mã cổ phiếu đang giao dịch trên cả 3 sàn (HOSE, HNX, UPCOM):',
              style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: const Column(
                children: [
                  _DetailRow(label: 'Mã kịch trần', value: '12 mã (2.6%)', valueColor: AppColors.priceCeiling),
                  SizedBox(height: 8),
                  _DetailRow(label: 'Mã tăng giá', value: '245 mã (53.3%)', valueColor: AppColors.primary),
                  SizedBox(height: 8),
                  _DetailRow(label: 'Mã tham chiếu', value: '68 mã (14.8%)', valueColor: Color(0xFF06B6D4)),
                  SizedBox(height: 8),
                  _DetailRow(label: 'Mã giảm giá', value: '132 mã (28.7%)', valueColor: Color(0xFFF87171)),
                  SizedBox(height: 8),
                  _DetailRow(label: 'Mã chạm sàn', value: '3 mã (0.6%)', valueColor: Color(0xFF38BDF8)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nhận định: Phe mua chiếm ưu thế áp đảo với hơn 55% mã tăng giá, dòng tiền tập trung mạnh tại nhóm vốn hóa lớn và trung bình.',
              style: TextStyle(color: AppColors.primary, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  /// Opens the Hot News detailed article dialog.
  static void showHotNewsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkCardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Color(0xFFC084FC)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Điểm nóng thị trường',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dòng tiền lan tỏa mạnh mẽ tại nhóm Bán Lẻ & Công Nghệ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ngày hôm nay, chỉ số VN-Index ghi nhận đà bứt phá mạnh mẽ vượt ngưỡng kháng cự tâm lý. Nhóm cổ phiếu công nghệ thông tin (FPT, ELC) và bán lẻ (MWG, FRT, DGW) dẫn dắt chỉ số tăng điểm với thanh khoản đột biến.',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13, height: 1.45),
              ),
              SizedBox(height: 12),
              Text(
                'Điểm nổi bật phiên giao dịch:',
                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '• Khối ngoại mua ròng hơn 420 tỷ đồng, tập trung mạnh nhất vào SSI (+150 tỷ), MWG (+95 tỷ) và FPT (+80 tỷ).\n• Nhóm ngành Thép (HPG, HSG) giữ vững vùng tham chiếu, sẵn sàng cho nhịp tích lũy mới.\n• Khuyến nghị: Nhà đầu tư duy trì tỷ trọng danh mục ở mức an toàn 60-70% cổ phiếu.',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppColors.primary)),
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
