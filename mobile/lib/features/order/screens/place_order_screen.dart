import 'dart:ui' show FontFeature;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../data/models/stock_model.dart';
import '../../market/data/market_fixtures.dart';
import '../../market/widgets/market_components.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key, this.symbol, this.side});
  final String? symbol;
  final String? side;
  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _api = StockmateApi();
  late String _symbol;
  late bool _isBuy;
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  List<StockModel> _stocks = AppConfig.useMock ? marketStocks : [];
  bool _marketLoading = !AppConfig.useMock;
  String? _marketError;
  bool _submitting = false;
  bool _priceEdited = false;
  String? _intentFingerprint;
  String? _intentUuid;
  @override
  void initState() {
    super.initState();
    _symbol = widget.symbol?.toUpperCase() ?? 'FPT';
    _isBuy = widget.side?.toUpperCase() != 'SELL';
    _quantity = TextEditingController(text: '100');
    _price = TextEditingController(
      text: formatBoardPrice(stockFor(_symbol).currentPrice),
    );
    _loadStocks();
  }

  StockModel get _selectedStock => _stocks.firstWhere(
    (stock) => stock.symbol == _symbol,
    orElse: () => _stocks.first,
  );

  Future<void> _loadStocks() async {
    if (AppConfig.useMock) return;
    try {
      final rows = await _api.market();
      final stocks = rows.map(StockModel.fromJson).toList();
      if (!mounted) return;
      if (stocks.isEmpty) {
        setState(() {
          _marketLoading = false;
          _marketError = 'Backend chưa có mã cổ phiếu để đặt lệnh.';
        });
        return;
      }
      setState(() {
        _stocks = stocks;
        _marketLoading = false;
        _marketError = null;
        if (!stocks.any((stock) => stock.symbol == _symbol)) {
          _symbol = stocks.first.symbol;
        }
        if (!_priceEdited) {
          _price.text = formatBoardPrice(
            stocks.firstWhere((stock) => stock.symbol == _symbol).currentPrice,
          );
        }
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _marketLoading = false;
          _marketError = 'Không tải được danh sách mã cổ phiếu.';
        });
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stocks.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: _marketLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _marketError ?? 'Không có dữ liệu cổ phiếu.',
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadStocks,
                      child: const Text('Tải lại'),
                    ),
                  ],
                ),
        ),
      );
    }
    final stock = _selectedStock;
    final quantity = int.tryParse(_quantity.text) ?? 0;
    final price = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;
    final estimate = quantity * price * 1000;
    final priceDong = (price * 1000).round();
    final tick = stock.exchange == 'HOSE' && priceDong < 50000 ? 50 : 100;
    final validQuantity = quantity > 0 && quantity % 100 == 0;
    final validPrice =
        priceDong >= stock.floorPrice &&
        priceDong <= stock.ceilingPrice &&
        priceDong % tick == 0;
    final accent = _isBuy ? AppColors.primary : AppColors.priceDown;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giao dịch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Đặt lệnh giới hạn (LO)',
                        style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/home/orders'),
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.darkCard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sidePicker(),
            const SizedBox(height: 16),
            MarketPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MÃ CỔ PHIẾU',
                    style: TextStyle(
                      color: AppColors.darkTextMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String>(
                    value: _symbol,
                    dropdownColor: AppColors.darkSurface,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    items: _stocks
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.symbol,
                            child: Text(
                              '${item.symbol}  ·  ${item.companyName}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null)
                        setState(() {
                          _symbol = value;
                          _price.text = formatBoardPrice(
                            _stocks
                                .firstWhere((item) => item.symbol == value)
                                .currentPrice,
                          );
                          _priceEdited = false;
                        });
                    },
                  ),
                  if (price > 0 && !validPrice)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Giá phải đúng bước giá và nằm trong biên độ trần/sàn.',
                        style: TextStyle(
                          color: AppColors.priceDown,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Giá khớp gần nhất',
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatBoardPrice(stock.currentPrice),
                        style: TextStyle(
                          color: stock.changeAmount >= 0
                              ? AppColors.priceUp
                              : AppColors.priceDown,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'nghìn ₫',
                        style: TextStyle(
                          color: AppColors.darkTextMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            MarketPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('GIÁ ĐẶT', '× 1.000 ₫'),
                  const SizedBox(height: 8),
                  _numberField(
                    _price,
                    decimal: true,
                    onChanged: (_) => setState(() => _priceEdited = true),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _priceMark(
                        'Trần',
                        formatBoardPrice(stock.ceilingPrice),
                        AppColors.priceCeiling,
                      ),
                      const Spacer(),
                      _priceMark(
                        'TC',
                        formatBoardPrice(stock.referencePrice),
                        AppColors.priceRef,
                      ),
                      const Spacer(),
                      _priceMark(
                        'Sàn',
                        formatBoardPrice(stock.floorPrice),
                        AppColors.priceFloor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            MarketPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('KHỐI LƯỢNG', 'Bội số 100 cổ phiếu'),
                  const SizedBox(height: 8),
                  _numberField(_quantity, onChanged: (_) => setState(() {})),
                  if (_quantity.text.isNotEmpty &&
                      quantity > 0 &&
                      !validQuantity)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Khối lượng phải là bội số của 100 cổ phiếu.',
                        style: TextStyle(
                          color: AppColors.priceDown,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [100, 500, 1000, 5000]
                        .map(
                          (value) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: InkWell(
                                onTap: () => setState(
                                  () => _quantity.text = value.toString(),
                                ),
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurface,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: AppColors.darkCardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    value >= 1000
                                        ? '${value ~/ 1000}k'
                                        : '$value',
                                    style: const TextStyle(
                                      color: AppColors.darkTextSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            MarketPanel(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Giá trị tạm tính',
                        style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_money(estimate)} ₫',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  const Row(
                    children: [
                      Text(
                        'Phí giao dịch dự kiến',
                        style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '0,15%',
                        style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: validQuantity && validPrice && !_submitting
                  ? () => _reviewOrder(stock.symbol, quantity, price, estimate)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: _isBuy
                    ? const Color(0xFF06251C)
                    : Colors.white,
                disabledBackgroundColor: AppColors.darkCard,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _submitting
                    ? 'Đang gửi lệnh…'
                    : 'Xem lại lệnh ${_isBuy ? 'mua' : 'bán'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lệnh được kiểm tra giá, sức mua và khối lượng trước khi gửi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidePicker() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.darkCardBorder),
    ),
    child: Row(children: [_sideButton('MUA', true), _sideButton('BÁN', false)]),
  );
  Widget _sideButton(String text, bool buy) {
    final selected = buy == _isBuy;
    final color = buy ? AppColors.primary : AppColors.priceDown;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _isBuy = buy),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: .16) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: .55)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? color : AppColors.darkTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, String trailing) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.darkTextMuted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: .7,
        ),
      ),
      const Spacer(),
      Text(
        trailing,
        style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 9),
      ),
    ],
  );
  Widget _numberField(
    TextEditingController controller, {
    bool decimal = false,
    ValueChanged<String>? onChanged,
  }) => TextField(
    controller: controller,
    onChanged: onChanged,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp(decimal ? r'[0-9,.]' : r'[0-9]'),
      ),
    ],
    style: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    decoration: const InputDecoration(
      filled: false,
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isDense: true,
    ),
  );
  Widget _priceMark(String title, String price, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 9),
      ),
      const SizedBox(height: 3),
      Text(
        price,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Future<void> _reviewOrder(
    String symbol,
    int quantity,
    double price,
    double estimate,
  ) async {
    final place = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xác nhận thông tin lệnh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _reviewLine('Loại lệnh', '${_isBuy ? 'Mua' : 'Bán'} $symbol'),
              _reviewLine(
                'Giá / khối lượng',
                '${price.toStringAsFixed(1)} × 1.000 ₫  ·  $quantity cp',
              ),
              _reviewLine('Giá trị dự kiến', '${_money(estimate)} ₫'),
              const SizedBox(height: 16),
              const Text(
                'Lệnh LO sẽ được gửi lên tài khoản đầu tư đang chọn.',
                style: TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF06251C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Xác nhận đặt lệnh',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (place == true && mounted && !_submitting) {
      setState(() => _submitting = true);
      try {
        if (!AppConfig.useMock) {
          final accountId = await _api.firstAccountId();
          await _api.placeOrder(accountId, {
            'client_order_id': _orderIntentId(symbol, _isBuy, quantity, price),
            'stock_symbol': symbol,
            'order_type': _isBuy ? 'BUY' : 'SELL',
            'order_kind': 'LO',
            'quantity': quantity,
            'order_price': (price * 1000).toStringAsFixed(2),
          });
        }
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã gửi lệnh. Sổ lệnh sẽ được cập nhật từ máy chủ.',
              ),
            ),
          );
      } catch (error) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không đặt được lệnh: $error')),
          );
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  String _orderIntentId(String symbol, bool isBuy, int quantity, double price) {
    final fingerprint =
        '$symbol|${isBuy ? 'BUY' : 'SELL'}|$quantity|${(price * 1000).toStringAsFixed(2)}';
    if (_intentFingerprint != fingerprint || _intentUuid == null) {
      _intentFingerprint = fingerprint;
      _intentUuid = _newUuid();
    }
    return _intentUuid!;
  }

  Widget _reviewLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  String _money(double value) => value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}
