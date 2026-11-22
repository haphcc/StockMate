import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../market/widgets/market_components.dart';

class OrderBookScreen extends StatefulWidget {
  const OrderBookScreen({super.key});
  @override
  State<OrderBookScreen> createState() => _OrderBookScreenState();
}

class _OrderBookScreenState extends State<OrderBookScreen> {
  final _api = StockmateApi();
  bool _loading = true;
  String? _error;
  String _filter = 'Tất cả';
  final _orders = <_OrderPreview>[
    _OrderPreview(
      id: 'SM-24816',
      symbol: 'FPT',
      side: 'MUA',
      price: '134.0',
      quantity: 500,
      filled: 200,
      time: '14:32',
      status: 'Khớp một phần',
    ),
    _OrderPreview(
      id: 'SM-24811',
      symbol: 'MWG',
      side: 'BÁN',
      price: '64.0',
      quantity: 1_000,
      filled: 0,
      time: '14:18',
      status: 'Chờ khớp',
    ),
    _OrderPreview(
      id: 'SM-24790',
      symbol: 'SSI',
      side: 'MUA',
      price: '33.8',
      quantity: 300,
      filled: 300,
      time: '10:06',
      status: 'Đã khớp',
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
              final status = switch ('${row['status']}') {
                'PENDING' => 'Chờ khớp',
                'PARTIAL' => 'Khớp một phần',
                'COMPLETED' => 'Đã khớp',
                'CANCELLED' => 'Đã hủy',
                'REJECTED' => 'Bị từ chối',
                _ => '${row['status']}',
              };
              final rawPrice = double.tryParse('${row['order_price']}') ?? 0;
              return _OrderPreview(
                id: '${row['order_id']}',
                symbol: '${row['stock_symbol']}',
                side: row['order_type'] == 'BUY' ? 'MUA' : 'BÁN',
                price: (rawPrice / 1000).toStringAsFixed(1),
                quantity: (row['quantity'] as num).toInt(),
                filled: (row['filled_quantity'] as num).toInt(),
                time: date == null
                    ? ''
                    : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                status: status,
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

  @override
  Widget build(BuildContext context) {
    final shown = _orders
        .where(
          (order) =>
              _filter == 'Tất cả' ||
              (_filter == 'Đang mở'
                  ? order.status == 'Chờ khớp' ||
                        order.status == 'Khớp một phần'
                  : order.status == _filter),
        )
        .toList();
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sổ lệnh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Theo dõi các lệnh đã đặt',
                        style: TextStyle(
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
                  'Không tải được sổ lệnh: $_error',
                  style: const TextStyle(color: AppColors.priceDown),
                ),
              ),
            const SizedBox(height: 20),
            MarketPanel(
              child: Row(
                children: [
                  _miniStat(
                    'Lệnh đang mở',
                    '${_orders.where((order) => order.status == 'Chờ khớp' || order.status == 'Khớp một phần').length}',
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
                    'Đã khớp hôm nay',
                    '${_orders.where((order) => order.status == 'Đã khớp').length}',
                    AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle('Lệnh của tôi'),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/home/orders/transactions'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('Lịch sử giao dịch'),
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
                children: ['Tất cả', 'Đang mở', 'Đã khớp', 'Đã hủy']
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
            const SizedBox(height: 14),
            if (shown.isEmpty)
              const MarketPanel(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Center(
                    child: Text(
                      'Không có lệnh trong trạng thái này.',
                      style: TextStyle(color: AppColors.darkTextSecondary),
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
                    child: _orderTile(order),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Lệnh của tài khoản đang chọn · cập nhật từ máy chủ',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
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

  Widget _orderTile(_OrderPreview order) {
    final buy = order.side == 'MUA';
    final tint = buy ? AppColors.primary : AppColors.priceDown;
    final stateColor = order.status == 'Đã khớp'
        ? AppColors.primary
        : order.status == 'Đã hủy'
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
                order.side,
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
              order.status,
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
          '${order.id}  ·  Hôm nay, ${order.time}',
          style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _orderValue('GIÁ ĐẶT', '${order.price} nghìn'),
            const Spacer(),
            _orderValue('KHỐI LƯỢNG', '${_number(order.quantity)} cp'),
            const Spacer(),
            _orderValue('ĐÃ KHỚP', '${_number(order.filled)} cp'),
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
        if (order.status == 'Chờ khớp' || order.status == 'Khớp một phần') ...[
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
                      SnackBar(content: Text('Không hủy được lệnh: $error')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.priceDown,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Hủy lệnh'),
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
