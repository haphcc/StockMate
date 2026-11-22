import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../market/widgets/market_components.dart';

class OrderBookScreen extends ConsumerStatefulWidget {
  const OrderBookScreen({super.key});
  @override
  ConsumerState<OrderBookScreen> createState() => _OrderBookScreenState();
}

class _OrderBookScreenState extends ConsumerState<OrderBookScreen> {
  final _api = StockmateApi();
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  final _orders = <_OrderPreview>[
    _OrderPreview(
      id: 'SM-24816',
      symbol: 'FPT',
      side: 'BUY',
      price: '134.0',
      quantity: 500,
      filled: 200,
      time: '14:32',
      status: 'PARTIAL',
    ),
    _OrderPreview(
      id: 'SM-24811',
      symbol: 'MWG',
      side: 'SELL',
      price: '64.0',
      quantity: 1000,
      filled: 0,
      time: '14:18',
      status: 'PENDING',
    ),
    _OrderPreview(
      id: 'SM-24790',
      symbol: 'SSI',
      side: 'BUY',
      price: '33.8',
      quantity: 300,
      filled: 300,
      time: '10:06',
      status: 'COMPLETED',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (!AppConfig.useMock) _orders.clear();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (AppConfig.useMock) {
      setState(() => _loading = false);
      return;
    }
    try {
      final accountId = await _api.firstAccountId();
      final rows = await _api.orders(accountId);
      if (!mounted) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(
            rows.map((row) {
              final date = DateTime.tryParse('${row['order_date']}')?.toLocal();
              final rawStatus = '${row['status']}';
              final rawPrice = double.tryParse('${row['order_price']}') ?? 0;
              return _OrderPreview(
                id: '${row['order_id']}',
                symbol: '${row['stock_symbol']}',
                side: row['order_type'] == 'BUY' ? 'BUY' : 'SELL',
                price: (rawPrice / 1000).toStringAsFixed(1),
                quantity: (row['quantity'] as num).toInt(),
                filled: (row['filled_quantity'] as num).toInt(),
                time: date == null
                    ? ''
                    : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                status: rawStatus,
              );
            }),
          );
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _orders.clear();
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  String _getStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'PENDING':
        return l10n.statusPending;
      case 'PARTIAL':
        return l10n.statusPartial;
      case 'COMPLETED':
        return l10n.statusCompleted;
      case 'CANCELLED':
        return l10n.statusCancelled;
      case 'REJECTED':
        return l10n.statusRejected;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final shown = _orders
        .where(
          (order) =>
              _filter == 'all' ||
              (_filter == 'open'
                  ? order.status == 'PENDING' || order.status == 'PARTIAL'
                  : (_filter == 'completed'
                      ? order.status == 'COMPLETED'
                      : (_filter == 'cancelled'
                          ? order.status == 'CANCELLED'
                          : true))),
        )
        .toList();
    final filterOptions = [
      ('all', l10n.all),
      ('open', l10n.filterOpenOrders),
      ('completed', l10n.statusCompleted),
      ('cancelled', l10n.statusCancelled),
    ];
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadOrders,
          child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.orderBookTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.orderBookSubtitle,
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/home/orders/transactions'),
                  icon: const Icon(Icons.history_rounded, color: Colors.white),
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
                  l10n.isVietnamese ? 'Không tải được sổ lệnh: $_error' : 'Failed to load order book: $_error',
                  style: const TextStyle(color: AppColors.priceDown),
                ),
              ),
            const SizedBox(height: 20),
            MarketPanel(
              child: Row(
                children: [
                  _miniStat(
                    l10n.openOrdersStat,
                    '${_orders.where((order) => order.status == 'PENDING' || order.status == 'PARTIAL').length}',
                    AppColors.priceRef,
                  ),
                  const Spacer(),
                  Container(
                    width: 1,
                    height: 34,
                    color: AppColors.darkCardBorder,
                  ),
                  const Spacer(),
                  _miniStat(
                    l10n.filledTodayStat,
                    '${_orders.where((order) => order.status == 'COMPLETED').length}',
                    AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionTitle(l10n.myOrders),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/home/orders/transactions'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: Text(l10n.viewHistoryBtn),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 4),
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
            const SizedBox(height: 14),
            if (shown.isEmpty)
              MarketPanel(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Center(
                    child: Text(
                      l10n.noOrdersInStatus,
                      style: const TextStyle(color: AppColors.darkTextSecondary),
                    ),
                  ),
                ),
              )
            else
              ...shown.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MarketPanel(
                    padding: const EdgeInsets.all(15),
                    child: _orderTile(order, l10n),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.ordersFooterNotice,
              style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _miniStat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 10,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _orderTile(_OrderPreview order, AppLocalizations l10n) {
    final buy = order.side == 'BUY';
    final tint = buy ? AppColors.primary : AppColors.priceDown;
    final stateColor = order.status == 'COMPLETED'
        ? AppColors.primary
        : (order.status == 'CANCELLED' || order.status == 'REJECTED')
        ? AppColors.darkTextMuted
        : AppColors.priceRef;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                buy ? l10n.orderBuy : l10n.orderSell,
                style: TextStyle(
                  color: tint,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              order.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              _getStatusLabel(order.status, l10n),
              style: TextStyle(
                color: stateColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.orderIdToday(order.id, order.time),
          style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _orderValue(l10n.priceLabel.toUpperCase(), '${order.price} ${l10n.thousandDongUnit}'),
            const Spacer(),
            _orderValue(l10n.quantityLabel.toUpperCase(), '${_number(order.quantity)} cp'),
            const Spacer(),
            _orderValue(l10n.filledQty, '${_number(order.filled)} cp'),
          ],
        ),
        if (order.quantity > 0) ...[
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: order.filled / order.quantity,
              minHeight: 4,
              backgroundColor: AppColors.darkSurface,
              color: tint,
            ),
          ),
        ],
        if (order.status == 'PENDING' || order.status == 'PARTIAL') ...[
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                try {
                  if (!AppConfig.useMock) {
                    await _api.cancelOrder(int.parse(order.id));
                  }
                  if (mounted) await _loadOrders();
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.isVietnamese ? 'Không hủy được lệnh: $error' : 'Failed to cancel order: $error')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.priceDown,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(l10n.btnCancelOrder),
            ),
          ),
        ],
      ],
    );
  }

  Widget _orderValue(String label, String value) => Column(
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
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
  String _number(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}

class _OrderPreview {
  _OrderPreview({
    required this.id,
    required this.symbol,
    required this.side,
    required this.price,
    required this.quantity,
    required this.filled,
    required this.time,
    required this.status,
  });
  final String id, symbol, side, price, time;
  final int quantity, filled;
  String status;
}
