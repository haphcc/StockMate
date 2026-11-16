import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../data/models/stock_model.dart';
import '../../../core/theme/app_colors.dart';
import '../data/market_fixtures.dart';
import '../widgets/market_components.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key, required this.symbol});
  final String symbol;
  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  String _range = '1M';
  bool _saved = false;
  StockModel? _stock;
  final _api = StockmateApi();
  List<Map<String, dynamic>> _candles = [];
  String? _chartError;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStock();
    _loadCandles();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    if (AppConfig.useMock) return;
    try {
      final entries = await _api.watchlist();
      final saved = entries.any(
        (entry) =>
            (entry['stock'] as Map)['stock_symbol'] ==
            widget.symbol.toUpperCase(),
      );
      if (mounted) setState(() => _saved = saved);
    } catch (_) {
      // Quote/chart remain usable if watchlist lookup is temporarily unavailable.
    }
  }

  Future<void> _toggleSaved() async {
    final next = !_saved;
    try {
      if (!AppConfig.useMock) {
        if (next) {
          await _api.addWatch(widget.symbol);
        } else {
          await _api.removeWatch(widget.symbol);
        }
      }
      if (mounted) setState(() => _saved = next);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không cập nhật được danh sách theo dõi: $error'),
          ),
        );
      }
    }
  }

  Future<void> _loadCandles() async {
    if (AppConfig.useMock) return;
    try {
      final rows = await _api.chart(widget.symbol, _range);
      if (mounted) {
        setState(() {
          _candles = rows;
          _chartError = rows.isEmpty
              ? 'Chưa có dữ liệu nến cho khoảng này.'
              : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _candles = [];
          _chartError = 'Không tải được dữ liệu nến.';
        });
      }
    }
  }

  Future<void> _loadStock() async {
    try {
      final stock = AppConfig.useMock
          ? stockFor(widget.symbol)
          : StockModel.fromJson(await StockmateApi().stock(widget.symbol));
      if (mounted) {
        setState(() {
          _stock = stock;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = _stock;
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (stock == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Text(
            'Không tải được mã ${widget.symbol}: $_error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final up = stock.changeAmount >= 0;
    final color = up ? AppColors.priceUp : AppColors.priceDown;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.darkCard,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${stock.symbol}  ·  ${stock.exchange}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stock.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.darkTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleSaved,
                      icon: Icon(
                        _saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _saved ? AppColors.primary : Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.darkCard,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          context.push('/home/overview/notifications'),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.darkCard,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              sliver: SliverList.list(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatBoardPrice(stock.currentPrice),
                        style: TextStyle(
                          color: color,
                          fontSize: 37,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 6, bottom: 8),
                        child: Text(
                          '× 1.000 ₫',
                          style: TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stock.changeAmount > 0 ? '+' : ''}${(stock.changeAmount / 1000).toStringAsFixed(1)}  (${stock.changePercent > 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _chartSection(stock),
                  const SizedBox(height: 20),
                  const SectionTitle('Thông tin giao dịch'),
                  const SizedBox(height: 10),
                  MarketPanel(
                    child: Column(
                      children: [
                        _priceLine(
                          'Mở cửa',
                          formatBoardPrice(stock.referencePrice),
                          AppColors.priceRef,
                        ),
                        _priceLine(
                          'Cao nhất',
                          formatBoardPrice(stock.ceilingPrice),
                          AppColors.priceCeiling,
                        ),
                        _priceLine(
                          'Thấp nhất',
                          formatBoardPrice(stock.floorPrice),
                          AppColors.priceFloor,
                        ),
                        _priceLine(
                          'Khối lượng',
                          formatVolume(stock.totalVolume),
                          Colors.white,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle('Giá trong phiên'),
                  const SizedBox(height: 10),
                  MarketPanel(
                    child: Column(
                      children: [
                        _depthHeader(),
                        const SizedBox(height: 10),
                        const Text(
                          'Backend hiện chưa cung cấp dữ liệu độ sâu lệnh mua/bán.',
                          style: TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go(
                    '/home/trade?symbol=${stock.symbol}&side=SELL',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.priceDown,
                    side: const BorderSide(color: AppColors.priceDown),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Bán'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.go('/home/trade?symbol=${stock.symbol}&side=BUY'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Đặt lệnh mua'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF06251C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chartSection(StockModel stock) {
    String dateAt(double fraction) {
      if (_candles.isEmpty) return '—';
      final index = ((_candles.length - 1) * fraction).round();
      final date = DateTime.tryParse('${_candles[index]['recorded_date']}');
      return date == null ? '' : '${date.day}/${date.month}';
    }

    return MarketPanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Biểu đồ nến',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Icon(
                Icons.tune_rounded,
                color: AppColors.darkTextMuted,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['1M', '3M', '6M']
                .map(
                  (range) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: FilterChipPill(
                      label: range,
                      selected: _range == range,
                      onTap: () {
                        setState(() => _range = range);
                        _loadCandles();
                      },
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 195,
            width: double.infinity,
            child: CustomPaint(
              painter: _CandlesPainter(
                seed: widget.symbol.hashCode,
                positive: stock.changeAmount >= 0,
                candles: _candles,
                preview: AppConfig.useMock || _candles.isEmpty,
              ),
            ),
          ),
          if (_chartError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _chartError!,
                style: const TextStyle(
                  color: AppColors.darkTextMuted,
                  fontSize: 10,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [0.0, 0.5, 1.0]
                .map(
                  (fraction) => Text(
                    dateAt(fraction),
                    style: const TextStyle(
                      color: AppColors.darkTextMuted,
                      fontSize: 9,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _priceLine(
    String label,
    String value,
    Color color, {
    bool last = false,
  }) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 14),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );

  Widget _depthHeader() => const Row(
    children: [
      Expanded(
        child: Text(
          'BÊN MUA',
          style: TextStyle(
            color: AppColors.darkTextMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Expanded(
        child: Text(
          'BÊN BÁN',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.darkTextMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _CandlesPainter extends CustomPainter {
  _CandlesPainter({
    required this.seed,
    required this.positive,
    required this.candles,
    required this.preview,
  });
  final int seed;
  final bool positive;
  final List<Map<String, dynamic>> candles;
  final bool preview;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.darkCardBorder
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = i * (size.height - 30) / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (candles.isEmpty && !preview) return;
    if (candles.isNotEmpty) {
      final rows = candles;
      double value(Map<String, dynamic> row, String key) =>
          double.tryParse('${row[key]}') ?? 0;
      final lows = rows.map((r) => value(r, 'lowest_price')).toList();
      final highs = rows.map((r) => value(r, 'highest_price')).toList();
      final min = lows.reduce(math.min);
      final max = highs.reduce(math.max);
      final span = math.max(max - min, 1);
      final gap = size.width / rows.length;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final open = value(row, 'open_price');
        final close = value(row, 'close_price');
        final high = value(row, 'highest_price');
        final low = value(row, 'lowest_price');
        final color = close >= open ? AppColors.priceUp : AppColors.priceDown;
        final x = gap * i + gap * .5;
        double y(double v) => 8 + ((max - v) / span) * (size.height - 42);
        canvas.drawLine(
          Offset(x, y(high)),
          Offset(x, y(low)),
          Paint()
            ..color = color.withValues(alpha: .8)
            ..strokeWidth = 1.2,
        );
        final body = Rect.fromLTRB(
          x - gap * .28,
          y(open),
          x + gap * .28,
          y(close),
        );
        canvas.drawRect(
          body.top == body.bottom ? body.inflate(1) : body,
          Paint()..color = color,
        );
        final volume = (row['trading_volume'] as num?)?.toDouble() ?? 0;
        final maxVolume = rows
            .map((r) => (r['trading_volume'] as num?)?.toDouble() ?? 0)
            .fold<double>(1, math.max);
        final volumeHeight = 8 + volume / maxVolume * 18;
        canvas.drawRect(
          Rect.fromLTWH(
            x - gap * .27,
            size.height - volumeHeight,
            gap * .54,
            volumeHeight,
          ),
          Paint()..color = color.withValues(alpha: .25),
        );
      }
      return;
    }
    var value = 0.47;
    final random = math.Random(seed);
    const count = 34;
    final gap = size.width / count;
    for (var i = 0; i < count; i++) {
      final drift = positive ? .006 : -.004;
      final open = value;
      value = (value + (random.nextDouble() - .48) * .11 + drift).clamp(
        .16,
        .86,
      );
      final close = value;
      final high = math.max(open, close) + random.nextDouble() * .07;
      final low = math.min(open, close) - random.nextDouble() * .06;
      final color = close >= open ? AppColors.priceUp : AppColors.priceDown;
      final x = gap * i + gap * .5;
      double y(double v) => 8 + (1 - v) * (size.height - 42);
      final wick = Paint()
        ..color = color.withValues(alpha: .8)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(x, y(high)), Offset(x, y(low)), wick);
      final body = Rect.fromLTRB(
        x - gap * .28,
        y(open),
        x + gap * .28,
        y(close),
      );
      canvas.drawRect(
        body.top == body.bottom ? body.inflate(1) : body,
        Paint()..color = color,
      );
      final volHeight = 8 + random.nextDouble() * 18;
      canvas.drawRect(
        Rect.fromLTWH(
          x - gap * .27,
          size.height - volHeight,
          gap * .54,
          volHeight,
        ),
        Paint()..color = color.withValues(alpha: .25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandlesPainter old) =>
      old.seed != seed ||
      old.positive != positive ||
      old.preview != preview ||
      !identical(old.candles, candles);
}
