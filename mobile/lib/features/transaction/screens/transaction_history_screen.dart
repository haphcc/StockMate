import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../market/widgets/market_components.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});
  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _api = StockmateApi();
  bool _loading = true;
  String? _error;
  String _filter = 'Tất cả';
  final _transactions = <_TradePreview>[
    _TradePreview(
      symbol: 'FPT',
      side: 'MUA',
      qty: 200,
      price: '134.20',
      total: '26.840.000',
      fee: '40.260',
      time: '14:32 · 14/11/2026',
      settlement: 'T+2 · 18/11/2026',
    ),
    _TradePreview(
      symbol: 'SSI',
      side: 'BÁN',
      qty: 300,
      price: '34.10',
      total: '10.230.000',
      fee: '15.345',
      time: '10:06 · 14/11/2026',
      settlement: 'Đã thanh toán',
    ),
    _TradePreview(
      symbol: 'HPG',
      side: 'MUA',
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
              final amount = (key) => double.tryParse('${row[key]}') ?? 0;
              return _TradePreview(
                symbol: '${row['stock_symbol']}',
                side: row['transaction_type'] == 'BUY' ? 'MUA' : 'BÁN',
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
      if (mounted)
        setState(() {
          _transactions.clear();
          _loading = false;
          _error = error.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _transactions
        .where((item) => _filter == 'Tất cả' || item.side == _filter)
        .toList();
    final displayedTotal = _transactions.fold<int>(
      0,
      (sum, item) =>
          sum +
          (int.tryParse(item.total.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0),
    );
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch sử giao dịch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Các giao dịch đã khớp',
                        style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.darkCard,
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
                  'Không tải được lịch sử: $_error',
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
                          'Tổng giá trị trong danh sách',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${NumberFormat('#,##0', 'vi_VN').format(displayedTotal)} ₫',
                          style: TextStyle(
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
                      '${_transactions.length} GD',
                      style: TextStyle(
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
                children: ['Tất cả', 'MUA', 'BÁN']
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipPill(
                          label: filter == 'Tất cả'
                              ? filter
                              : filter == 'MUA'
                              ? 'Lệnh mua'
                              : 'Lệnh bán',
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('Giao dịch gần nhất'),
            const SizedBox(height: 10),
            ...shown.map(
              (trade) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MarketPanel(
                  padding: const EdgeInsets.all(15),
                  child: _tradeCard(trade),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lịch sử giao dịch từ tài khoản đang chọn',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tradeCard(_TradePreview trade) {
    final buy = trade.side == 'MUA';
    final color = buy ? AppColors.primary : AppColors.priceDown;
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
                trade.side,
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
            _data('KHỐI LƯỢNG', '${trade.qty} cp'),
            const Spacer(),
            _data('GIÁ KHỚP', '${trade.price} nghìn'),
            const Spacer(),
            _data('GIÁ TRỊ', '${trade.total} ₫'),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: AppColors.darkCardBorder, height: 1),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              'Phí giao dịch',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
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
              trade.settlement,
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
