import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/admin_candle_model.dart';
import 'admin_widgets.dart';

/// Biểu đồ nến tự vẽ. `candles` xếp theo ngày tăng dần (cũ đến mới).
class AdminCandleChart extends StatelessWidget {
  final List<AdminCandleModel> candles;
  final double height;

  const AdminCandleChart({
    super.key,
    required this.candles,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _CandlePainter(candles)),
    );
  }
}

class _CandlePainter extends CustomPainter {
  final List<AdminCandleModel> candles;

  _CandlePainter(this.candles);

  static const double _left = 54;
  static const double _right = 8;
  static const double _top = 8;
  static const double _bottom = 22;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    final chartW = size.width - _left - _right;
    final chartH = size.height - _top - _bottom;
    if (chartW <= 0 || chartH <= 0) return;

    double minP = double.infinity;
    double maxP = -double.infinity;
    for (final c in candles) {
      final values = [c.openPrice, c.closePrice, c.highestPrice, c.lowestPrice]
          .map((v) => double.tryParse(v) ?? 0);
      for (final v in values) {
        if (v < minP) minP = v;
        if (v > maxP) maxP = v;
      }
    }
    var range = maxP - minP;
    if (range <= 0) range = 1;
    // Chừa 5% mỗi phía để nến không dính mép.
    final lo = minP - range * 0.05;
    final hi = maxP + range * 0.05;
    final span = hi - lo;

    double yOf(double price) => _top + chartH * (1 - (price - lo) / span);

    // Lưới ngang và nhãn giá.
    final gridPaint = Paint()
      ..color = AppColors.darkBorder
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 4; i++) {
      final price = lo + span * i / 4;
      final y = yOf(price);
      canvas.drawLine(
        Offset(_left, y),
        Offset(size.width - _right, y),
        gridPaint,
      );
      _drawText(
        canvas,
        formatNumber(price.round().toString()),
        Offset(0, y - 6),
        width: _left - 4,
        align: TextAlign.right,
      );
    }

    // Các cây nến.
    final slot = chartW / candles.length;
    final bodyWidth = (slot * 0.6).clamp(1.0, 14.0).toDouble();
    for (var i = 0; i < candles.length; i++) {
      final c = candles[i];
      final open = double.tryParse(c.openPrice) ?? 0;
      final close = double.tryParse(c.closePrice) ?? 0;
      final high = double.tryParse(c.highestPrice) ?? 0;
      final low = double.tryParse(c.lowestPrice) ?? 0;
      final paint = Paint()
        ..color = c.isUp ? AppColors.priceUp : AppColors.priceDown
        ..strokeWidth = 1;
      final x = _left + slot * (i + 0.5);
      canvas.drawLine(Offset(x, yOf(high)), Offset(x, yOf(low)), paint);
      final top = yOf(open > close ? open : close);
      var bottom = yOf(open < close ? open : close);
      if (bottom - top < 1) bottom = top + 1;
      canvas.drawRect(
        Rect.fromLTRB(x - bodyWidth / 2, top, x + bodyWidth / 2, bottom),
        paint,
      );
    }

    // Nhãn ngày đầu và cuối.
    _drawText(
      canvas,
      _shortDate(candles.first.recordedDate),
      Offset(_left, size.height - 16),
    );
    _drawText(
      canvas,
      _shortDate(candles.last.recordedDate),
      Offset(size.width - _right - 60, size.height - 16),
      align: TextAlign.right,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double width = 60,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout(minWidth: width, maxWidth: width);
    painter.paint(canvas, offset);
  }

  String _shortDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}';
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.candles != candles;
}