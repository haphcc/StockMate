import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../data/models/stock_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sparkline_chart.dart';
import '../../market/data/market_fixtures.dart';
import '../../market/widgets/market_components.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});
  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _symbols = <String>[];
  final _quotes = <String, StockModel>{};
  final _api = StockmateApi();
  bool _loading = true;
  String? _loadError;
  String _filter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    if (AppConfig.useMock) {
      setState(() {
        _symbols
          ..clear()
          ..addAll(['FPT', 'MWG', 'SSI', 'HPG']);
        _quotes
          ..clear()
          ..addEntries(_symbols.map((s) => MapEntry(s, stockFor(s))));
        _loading = false;
      });
      return;
    }
    try {
      final rows = await _api.watchlist();
      if (!mounted) return;
      final quoteRows = rows
          .map(
            (row) => StockModel.fromJson(
              Map<String, dynamic>.from(row['stock'] as Map),
            ),
          )
          .toList();
      setState(() {
        _symbols
          ..clear()
          ..addAll(quoteRows.map((stock) => stock.symbol));
        _quotes
          ..clear()
          ..addEntries(quoteRows.map((stock) => MapEntry(stock.symbol, stock)));
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = error.toString();
        });
      }
    }
  }

  Future<void> _removeWatch(String symbol) async {
    try {
      if (!AppConfig.useMock) {
        await _api.removeWatch(symbol);
      }
      if (mounted) {
        setState(() => _symbols.remove(symbol));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stocks = _symbols
        .map((symbol) => _quotes[symbol] ?? stockFor(symbol))
        .where(
          (stock) =>
              _filter == 'Tất cả' ||
              (_filter == 'Tăng'
                  ? stock.changeAmount > 0
                  : stock.changeAmount < 0),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadWatchlist,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
          children: [
            MarketHeader(
              onNotifications: () =>
                  context.push('/home/overview/notifications'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Danh sách theo dõi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Các mã bạn đang quan tâm',
                              style: TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showAddDialog,
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF06251C),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          fixedSize: const Size(44, 44),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  MarketPanel(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.priceRef,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_symbols.length} mã',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Hôm nay',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '+1.42%',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Tất cả', 'Tăng', 'Giảm']
                          .map(
                            (filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChipPill(
                                label: filter,
                                selected: _filter == filter,
                                onTap: () => setState(() => _filter = filter),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (stocks.isEmpty)
                    const MarketPanel(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Chưa có mã nào trong nhóm này.',
                            style: TextStyle(
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Không tải được danh sách: $_loadError',
                        style: const TextStyle(color: AppColors.priceDown),
                      ),
                    )
                  else
                    ...stocks.map((stock) {
                      final color = stock.changeAmount >= 0
                          ? AppColors.priceUp
                          : AppColors.priceDown;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MarketPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: InkWell(
                            onTap: () => context.push(
                              '/home/overview/stock/${stock.symbol}',
                            ),
                            child: Row(
                              children: [
                                SymbolBadge(stock.symbol, size: 42),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stock.symbol,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        stock.companyName,
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
                                SparklineChart(
                                  width: 42,
                                  height: 22,
                                  color: color,
                                  isUp: stock.changeAmount >= 0,
                                ),
                                const SizedBox(width: 9),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatBoardPrice(stock.currentPrice),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${stock.changePercent > 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: AppColors.darkTextMuted,
                                    size: 19,
                                  ),
                                  color: AppColors.darkSurface,
                                  onSelected: (value) {
                                    if (value == 'trade') {
                                      context.go(
                                        '/home/trade?symbol=${stock.symbol}&side=BUY',
                                      );
                                    } else if (value == 'remove') {
                                      _removeWatch(stock.symbol);
                                    }
                                  },
                                  itemBuilder: (menuContext) => const [
                                    PopupMenuItem(
                                      value: 'trade',
                                      child: Text('Đặt lệnh mua'),
                                    ),
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Text('Bỏ theo dõi'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  const Text(
                    'Đơn vị: nghìn đồng',
                    style: TextStyle(
                      color: AppColors.darkTextMuted,
                      fontSize: 10,
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

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final symbol = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Thêm mã theo dõi',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Ví dụ: VNM'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim().toUpperCase()),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (symbol == null || symbol.isEmpty) return;
    try {
      StockModel stock;
      if (!AppConfig.useMock) {
        await _api.addWatch(symbol);
        stock = StockModel.fromJson(await _api.stock(symbol));
      } else {
        stock = stockFor(symbol);
      }
      if (mounted) {
        setState(() {
          if (!_symbols.contains(symbol)) _symbols.insert(0, symbol);
          _quotes[symbol] = stock;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
