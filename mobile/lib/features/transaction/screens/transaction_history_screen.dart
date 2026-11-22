import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../market/widgets/market_components.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});
  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  final _api = StockmateApi();
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  final _transactions = <_TradePreview>[
    const _TradePreview(
      symbol: 'FPT',
      side: 'BUY',
      qty: 200,
      price: '134.20',
      total: '26.840.000',
      fee: '40.260',
      time: '14:32 · 14/11/2026',
      settlement: 'T+2 · 18/11/2026',
    ),
    const _TradePreview(
      symbol: 'SSI',
      side: 'SELL',
      qty: 300,
      price: '34.10',
      total: '10.230.000',
      fee: '15.345',
      time: '10:06 · 14/11/2026',
      settlement: 'Đã thanh toán',
    ),
    const _TradePreview(
      symbol: 'HPG',
      side: 'BUY',
      qty: 500,
      price: '28.70',
      total: '14.350.000',
      fee: '21.525',
      time: '14:21 · 13/11/2026',
      settlement: 'T+2 · 17/11/2026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (!AppConfig.useMock) _transactions.clear();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (AppConfig.useMock) {
      setState(() => _loading = false);
      return;
    }
    try {
      final accountId = await _api.firstAccountId();
      final rows = await _api.transactions(accountId);
      if (!mounted) return;
      setState(() {
        _transactions
          ..clear()
          ..addAll(
            rows.map((row) {
              final date = DateTime.tryParse(
                '${row['transaction_date']}',
              )?.toLocal();
              final settle = row['settlement_date']?.toString();
              double amount(key) => double.tryParse('${row[key]}') ?? 0;
              return _TradePreview(
                symbol: '${row['stock_symbol']}',
                side: row['transaction_type'] == 'BUY' ? 'BUY' : 'SELL',
                qty: (row['quantity'] as num).toInt(),
                price: (amount('price') / 1000).toStringAsFixed(2),
                total: amount('total_amount').toStringAsFixed(0),
                fee: amount('transaction_fee').toStringAsFixed(0),
                time: date == null
                    ? ''
                    : '${date.day}/${date.month}/${date.year} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                settlement: settle ?? 'Đang chờ thanh toán',
              );
            }),
          );
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _transactions.clear();
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final shown = _transactions
        .where((item) => _filter == 'all' || item.side == _filter)
        .toList();
    final displayedTotal = _transactions.fold<int>(
      0,
      (sum, item) =>
          sum +
          (int.tryParse(item.total.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0),
    );
    final filterOptions = [
      ('all', l10n.all),
      ('BUY', l10n.isVietnamese ? 'Lệnh mua' : 'Buy Orders'),
      ('SELL', l10n.isVietnamese ? 'Lệnh bán' : 'Sell Orders'),
    ];
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadTransactions,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
          children: [
            Row(
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.transactionHistoryTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.transactionHistorySubtitle,
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!_loading && _error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.isVietnamese ? 'Không tải được lịch sử: $_error' : 'Failed to load history: $_error',
                  style: const TextStyle(color: AppColors.priceDown),
                ),
              ),
            const SizedBox(height: 20),
            MarketPanel(
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalTradeValue,
                          style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${NumberFormat('#,##0', 'vi_VN').format(displayedTotal)} ₫',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_transactions.length} ${l10n.isVietnamese ? 'GD' : 'Trades'}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
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
            const SizedBox(height: 18),
            SectionTitle(l10n.isVietnamese ? 'Giao dịch gần nhất' : 'Recent Transactions'),
            const SizedBox(height: 10),
            ...shown.map(
              (trade) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MarketPanel(
                  padding: const EdgeInsets.all(15),
                  child: _tradeCard(trade, l10n),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.transactionsFooterNotice,
              style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _tradeCard(_TradePreview trade, AppLocalizations l10n) {
    final buy = trade.side == 'BUY';
    final color = buy ? AppColors.primary : AppColors.priceDown;
    String settlementText = trade.settlement;
    if (trade.settlement == 'Đã thanh toán') {
      settlementText = l10n.settledStatus;
    } else if (trade.settlement == 'Đang chờ thanh toán') {
      settlementText = l10n.pendingSettlement;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SymbolBadge(trade.symbol, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trade.symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${trade.time}  ·  LO',
                    style: const TextStyle(
                      color: AppColors.darkTextMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                buy ? l10n.orderBuy : l10n.orderSell,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _data(l10n.quantityLabel.toUpperCase(), '${trade.qty} cp'),
            const Spacer(),
            _data(l10n.currentMatching.toUpperCase(), '${trade.price} ${l10n.thousandDongUnit}'),
            const Spacer(),
            _data(l10n.isVietnamese ? 'GIÁ TRỊ' : 'VALUE', '${trade.total} ₫'),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: AppColors.darkCardBorder, height: 1),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              l10n.isVietnamese ? 'Phí giao dịch' : 'Trading Fee',
              style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
            ),
            const Spacer(),
            Text(
              '${trade.fee} ₫',
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(
              Icons.event_available_outlined,
              size: 13,
              color: AppColors.darkTextMuted,
            ),
            const SizedBox(width: 4),
            Text(
              settlementText,
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _data(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.darkTextMuted,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _TradePreview {
  const _TradePreview({
    required this.symbol,
    required this.side,
    required this.qty,
    required this.price,
    required this.total,
    required this.fee,
    required this.time,
    required this.settlement,
  });
  final String symbol, side, price, total, fee, time, settlement;
  final int qty;
}
