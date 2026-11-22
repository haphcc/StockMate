import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../data/models/stock_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sparkline_chart.dart';
import '../../../providers/app_providers.dart';
import '../../market/data/market_fixtures.dart';
import '../../market/widgets/market_components.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});
  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  final _symbols = <String>[];
  final _quotes = <String, StockModel>{};
  final _api = StockmateApi();
  List<StockModel> _availableStocks = [];
  bool _loading = true;
  String? _loadError;
  String _filter = 'all';

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

  Future<List<StockModel>> _getAvailableStocks() async {
    if (_availableStocks.isNotEmpty) return _availableStocks;
    if (AppConfig.useMock) {
      _availableStocks = List.from(marketStocks);
      return _availableStocks;
    }
    try {
      final rows = await _api.market();
      if (rows.isNotEmpty) {
        _availableStocks = rows.map((r) => StockModel.fromJson(r)).toList();
      } else {
        _availableStocks = List.from(marketStocks);
      }
    } catch (_) {
      _availableStocks = List.from(marketStocks);
    }
    return _availableStocks;
  }

  Future<void> _removeWatch(String symbol) async {
    try {
      if (!AppConfig.useMock) {
        await _api.removeWatch(symbol);
      }
      if (mounted) {
        setState(() {
          _symbols.remove(symbol);
          _quotes.remove(symbol);
        });
        final l10n = ref.read(l10nProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.removedFromWatchlist(symbol))),
        );
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
    final l10n = ref.watch(l10nProvider);
    final allTrackedStocks = _symbols
        .map((symbol) => _quotes[symbol] ?? stockFor(symbol))
        .toList();

    double avgChangePercent = 0.0;
    if (allTrackedStocks.isNotEmpty) {
      final sum = allTrackedStocks.fold<double>(
        0.0,
        (acc, item) => acc + item.changePercent,
      );
      avgChangePercent = sum / allTrackedStocks.length;
    }

    Color summaryColor = AppColors.priceRef;
    String summaryPercentText = '0.00%';
    if (avgChangePercent > 0.001) {
      summaryColor = AppColors.priceUp;
      summaryPercentText = '+${avgChangePercent.toStringAsFixed(2)}%';
    } else if (avgChangePercent < -0.001) {
      summaryColor = AppColors.priceDown;
      summaryPercentText = '${avgChangePercent.toStringAsFixed(2)}%';
    }

    final stocks = allTrackedStocks
        .where(
          (stock) =>
              _filter == 'all' ||
              (_filter == 'gain'
                  ? stock.changeAmount > 0
                  : (_filter == 'loss' ? stock.changeAmount < 0 : true)),
        )
        .toList();
    final filterOptions = [
      ('all', l10n.all),
      ('gain', l10n.gainers),
      ('loss', l10n.losers),
    ];
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.watchlistTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.watchlistSubtitle,
                              style: const TextStyle(
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
                          '${_symbols.length} ${l10n.symbolsCount(_symbols.length)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.today,
                          style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          summaryPercentText,
                          style: TextStyle(
                            color: summaryColor,
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
                      children: filterOptions
                          .map(
                            (opt) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChipPill(
                                label: opt.$2,
                                selected: _filter == opt.$1,
                                onTap: () => setState(() => _filter = opt.$1),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (stocks.isEmpty)
                    MarketPanel(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            l10n.emptyWatchlistGroup,
                            style: const TextStyle(
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
                        l10n.isVietnamese ? 'Không tải được danh sách: $_loadError' : 'Failed to load watchlist: $_loadError',
                        style: const TextStyle(color: AppColors.priceDown),
                      ),
                    )
                  else
                    ...stocks.map((stock) {
                      final Color color;
                      final bool isUp;
                      final List<double>? sparkData;

                      if (stock.changeAmount > 0) {
                        color = AppColors.priceUp;
                        isUp = true;
                        sparkData = null;
                      } else if (stock.changeAmount < 0) {
                        color = AppColors.priceDown;
                        isUp = false;
                        sparkData = null;
                      } else {
                        color = AppColors.priceRef;
                        isUp = true;
                        sparkData = const [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
                      }

                      final changeSign = stock.changeAmount > 0 ? '+' : '';
                      final changePercentStr =
                          '$changeSign${stock.changePercent.toStringAsFixed(2)}%';

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
                                  isUp: isUp,
                                  data: sparkData,
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
                                      changePercentStr,
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
                                  itemBuilder: (menuContext) => [
                                    PopupMenuItem(
                                      value: 'trade',
                                      child: Text(l10n.actionTradeBuy),
                                    ),
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Text(l10n.actionUnwatch),
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
                  Text(
                    l10n.unitThousandDong,
                    style: const TextStyle(
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
    final l10n = ref.read(l10nProvider);
    final available = await _getAvailableStocks();
    if (!mounted) return;

    final controller = TextEditingController();
    String? selectedDropdownSymbol;

    final symbol = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentText = controller.text.trim().toUpperCase();
          final alreadyInWatchlist = _symbols.contains(currentText);

          return AlertDialog(
            backgroundColor: AppColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.darkCardBorder),
            ),
            title: Text(
              l10n.addStockToWatchlist,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quickSelectFromListed,
                    style: const TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: available.any((s) => s.symbol == selectedDropdownSymbol)
                            ? selectedDropdownSymbol
                            : null,
                        hint: Text(
                          l10n.selectStockPlaceholder,
                          style: const TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: 13,
                          ),
                        ),
                        dropdownColor: AppColors.darkCard,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.darkTextSecondary,
                        ),
                        items: available.map((stock) {
                          final inList = _symbols.contains(stock.symbol);
                          return DropdownMenuItem<String>(
                            value: stock.symbol,
                            child: Row(
                              children: [
                                Text(
                                  stock.symbol,
                                  style: TextStyle(
                                    color: inList
                                        ? AppColors.darkTextMuted
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stock.companyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.darkTextSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (inList)
                                  Text(
                                    l10n.addedLabel,
                                    style: const TextStyle(
                                      color: AppColors.priceRef,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedDropdownSymbol = val;
                              controller.text = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.darkCardBorder),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          l10n.orEnterSymbol,
                          style: const TextStyle(
                            color: AppColors.darkTextMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.darkCardBorder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: false,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (text) {
                      setDialogState(() {
                        final upper = text.trim().toUpperCase();
                        if (available.any((s) => s.symbol == upper)) {
                          selectedDropdownSymbol = upper;
                        } else {
                          selectedDropdownSymbol = null;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: l10n.enterStockHint,
                      hintStyle: const TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: AppColors.darkTextSecondary,
                                size: 16,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  controller.clear();
                                  selectedDropdownSymbol = null;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.darkBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.darkCardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  if (alreadyInWatchlist && currentText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.priceRef,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.alreadyInWatchlist,
                          style: const TextStyle(
                            color: AppColors.priceRef,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  l10n.btnLater,
                  style: const TextStyle(color: AppColors.darkTextSecondary),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF06251C),
                  disabledBackgroundColor: AppColors.darkCardBorder,
                ),
                onPressed: (currentText.isEmpty || alreadyInWatchlist)
                    ? null
                    : () => Navigator.pop(dialogCtx, currentText),
                child: Text(
                  l10n.btnAdd,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addedToWatchlist(symbol))),
        );
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
