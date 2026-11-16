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
  final String? symbol;
  final String? side;
  final String? initialSymbol;
  final bool? isBuy;
  final double? initialPrice;

  const PlaceOrderScreen({
    super.key,
    this.symbol,
    this.side,
    this.initialSymbol,
    this.isBuy,
    this.initialPrice,
  });

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
  List<Map<String, dynamic>> _userAccounts = [];
  int? _selectedAccountId;
  double _cashBalance = 0;
  Map<String, int> _availableSharesBySymbol = {};

  @override
  void initState() {
    super.initState();
    _symbol = widget.symbol?.toUpperCase() ??
        widget.initialSymbol?.toUpperCase() ??
        'FPT';
    _isBuy = widget.isBuy ?? (widget.side?.toUpperCase() != 'SELL');
    _quantity = TextEditingController(text: '100');
    final initialPriceStr = widget.initialPrice != null
        ? (widget.initialPrice! >= 1000
            ? formatBoardPrice(widget.initialPrice!.round())
            : widget.initialPrice!.toStringAsFixed(1))
        : formatBoardPrice(stockFor(_symbol).currentPrice);
    _price = TextEditingController(text: initialPriceStr);
    _loadStocks();
    _loadAccounts();
  }

  Future<void> _loadAccountBalances(int accountId) async {
    if (AppConfig.useMock) return;
    try {
      final assets = await _api.assets(accountId);
      final port = await _api.portfolio(accountId);
      if (!mounted) return;
      final rawCash = double.tryParse('${assets['cash_balance']}') ?? 0;
      final sharesMap = <String, int>{};
      for (final p in port) {
        final sym = '${p['stock_symbol']}'.toUpperCase();
        final avail = (p['available_quantity'] as num?)?.toInt() ?? 0;
        sharesMap[sym] = avail;
      }
      setState(() {
        _cashBalance = rawCash;
        _availableSharesBySymbol = sharesMap;
      });
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant PlaceOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    var changed = false;
    if (widget.symbol != null && widget.symbol!.toUpperCase() != _symbol) {
      _symbol = widget.symbol!.toUpperCase();
      changed = true;
    }
    if (widget.side != null) {
      final newIsBuy = widget.side!.toUpperCase() != 'SELL';
      if (newIsBuy != _isBuy) {
        _isBuy = newIsBuy;
        changed = true;
      }
    }
    if (widget.initialPrice != null) {
      final newPriceStr = widget.initialPrice! >= 1000
          ? formatBoardPrice(widget.initialPrice!.round())
          : widget.initialPrice!.toStringAsFixed(1);
      if (_price.text != newPriceStr) {
        _price.text = newPriceStr;
        _priceEdited = true;
        changed = true;
      }
    } else if (changed && _stocks.any((s) => s.symbol == _symbol)) {
      _price.text = formatBoardPrice(
        _stocks.firstWhere((s) => s.symbol == _symbol).currentPrice,
      );
      _priceEdited = false;
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAccounts() async {
    if (AppConfig.useMock) return;
    try {
      final rows = await _api.accounts();
      if (!mounted) return;
      final savedId = int.tryParse(await _api.storage.read(key: 'selected_account_id') ?? '');
      int? targetId;
      if (savedId != null && rows.any((r) => (r['account_id'] as num).toInt() == savedId)) {
        targetId = savedId;
      } else {
        final cashAcc = rows.firstWhere(
          (r) => r['account_type'] == 'CASH' && r['status'] == 'ACTIVE',
          orElse: () => rows.firstWhere(
            (r) => r['status'] == 'ACTIVE',
            orElse: () => rows.isNotEmpty ? rows.first : <String, dynamic>{},
          ),
        );
        if (cashAcc.isNotEmpty) {
          targetId = (cashAcc['account_id'] as num).toInt();
        }
      }
      setState(() {
        _userAccounts = rows;
        _selectedAccountId = targetId;
      });
      if (targetId != null) {
        await _api.selectAccount(targetId);
        await _loadAccountBalances(targetId);
      }
    } catch (_) {}
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
      if (mounted) {
        setState(() {
          _marketLoading = false;
          _marketError = 'Không tải được danh sách mã cổ phiếu.';
        });
      }
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
    final int tick;
    if (stock.exchange == 'HOSE') {
      if (priceDong < 10000) {
        tick = 10;
      } else if (priceDong < 50000) {
        tick = 50;
      } else {
        tick = 100;
      }
    } else {
      tick = 100;
    }
    final validQuantity = quantity > 0 && quantity % 100 == 0;
    final validPrice = priceDong >= stock.floorPrice &&
        priceDong <= stock.ceilingPrice &&
        priceDong % tick == 0;
    String? priceError;
    if (_price.text.isNotEmpty && price > 0) {
      if (priceDong < stock.floorPrice) {
        priceError = 'Giá thấp hơn sàn (${formatBoardPrice(stock.floorPrice)})';
      } else if (priceDong > stock.ceilingPrice) {
        priceError = 'Giá cao hơn trần (${formatBoardPrice(stock.ceilingPrice)})';
      } else if (priceDong % tick != 0) {
        priceError = 'Bước giá sàn ${stock.exchange} là $tick đ (chạm vào Sàn/TC/Trần bên dưới để chọn nhanh)';
      }
    }
    final feeEstimate = estimate * 0.0015;
    final totalBuyRequired = estimate + feeEstimate;
    final availableShares = _availableSharesBySymbol[_symbol] ?? 0;

    final validCash = !_isBuy || (estimate == 0 || totalBuyRequired <= _cashBalance);
    final validShares = _isBuy || (quantity > 0 && quantity <= availableShares);
    final canSubmit = validQuantity && validPrice && validCash && validShares && !_submitting;

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
                  onPressed: () => context.go('/home/orders'),
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
            if (_userAccounts.length > 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkCardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.darkTextSecondary),
                    const SizedBox(width: 8),
                    const Text('Tài khoản: ', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _selectedAccountId,
                      dropdownColor: AppColors.darkSurface,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      items: _userAccounts.map((acc) {
                        final id = (acc['account_id'] as num).toInt();
                        final type = acc['account_type'] ?? '';
                        final numStr = acc['account_number'] ?? '';
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text('$numStr ($type)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedAccountId = val);
                          _api.selectAccount(val);
                          _loadAccountBalances(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
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
                    initialValue: _symbol,
                    isExpanded: true,
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
                      fontSize: 14,
                    ),
                    selectedItemBuilder: (context) => _stocks
                        .map(
                          (item) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${item.symbol}  ·  ${item.companyName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    items: _stocks
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.symbol,
                            child: Text(
                              '${item.symbol}  ·  ${item.companyName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _symbol = value;
                          _price.text = formatBoardPrice(
                            _stocks
                                .firstWhere((item) => item.symbol == value)
                                .currentPrice,
                          );
                          _priceEdited = false;
                        });
                      }
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
                      const Text(
                        'Giá khớp gần nhất',
                        style: TextStyle(
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
                  if (priceError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        priceError,
                        style: const TextStyle(
                          color: AppColors.priceDown,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _priceMark(
                        'Trần',
                        formatBoardPrice(stock.ceilingPrice),
                        AppColors.priceCeiling,
                        () => setState(() {
                          _price.text = formatBoardPrice(stock.ceilingPrice);
                          _priceEdited = true;
                        }),
                      ),
                      const Spacer(),
                      _priceMark(
                        'TC',
                        formatBoardPrice(stock.referencePrice),
                        AppColors.priceRef,
                        () => setState(() {
                          _price.text = formatBoardPrice(stock.referencePrice);
                          _priceEdited = true;
                        }),
                      ),
                      const Spacer(),
                      _priceMark(
                        'Sàn',
                        formatBoardPrice(stock.floorPrice),
                        AppColors.priceFloor,
                        () => setState(() {
                          _price.text = formatBoardPrice(stock.floorPrice);
                          _priceEdited = true;
                        }),
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
                  _fieldLabel(
                    'KHỐI LƯỢNG',
                    _isBuy
                        ? 'Sức mua: ${_money(_cashBalance)} ₫'
                        : 'Khả dụng: ${_number(availableShares)} cp',
                  ),
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
                  if (_isBuy && estimate > 0 && !validCash)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Số dư tiền không đủ. Cần ${_money(totalBuyRequired)} ₫ (gồm phí), hiện có ${_money(_cashBalance)} ₫.',
                        style: const TextStyle(
                          color: AppColors.priceDown,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!_isBuy && availableShares <= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Tài khoản hiện không có cổ phiếu $_symbol khả dụng trong danh mục để bán.',
                        style: const TextStyle(
                          color: AppColors.priceDown,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!_isBuy && quantity > availableShares && availableShares > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Khối lượng bán ($quantity cp) vượt quá số lượng khả dụng ($availableShares cp).',
                        style: const TextStyle(
                          color: AppColors.priceDown,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...[100, 500, 1000].map(
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
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (_isBuy) {
                              if (price > 0) {
                                final maxLot = ((_cashBalance / (price * 1000 * 1.0015)) ~/ 100) * 100;
                                setState(() => _quantity.text = maxLot > 0 ? '$maxLot' : '100');
                              }
                            } else {
                              final maxLot = (availableShares ~/ 100) * 100;
                              setState(() => _quantity.text = maxLot > 0 ? '$maxLot' : '$availableShares');
                            }
                          },
                          borderRadius: BorderRadius.circular(9),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: _isBuy
                                    ? AppColors.primary.withValues(alpha: 0.6)
                                    : AppColors.priceDown.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              _isBuy ? 'Tối đa' : 'Tất cả',
                              style: TextStyle(
                                color: _isBuy ? AppColors.primary : AppColors.priceDown,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                  Row(
                    children: [
                      const Text(
                        'Phí giao dịch dự kiến',
                        style: TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '0,15% (${_money(feeEstimate)} ₫)',
                        style: const TextStyle(
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
              onPressed: canSubmit
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
                    : !validQuantity
                        ? 'Khối lượng phải là bội số của 100'
                        : !validPrice
                            ? 'Vui lòng kiểm tra lại giá đặt'
                            : _isBuy && !validCash
                                ? 'Số dư tiền không đủ đặt mua'
                                : !_isBuy && availableShares <= 0
                                    ? 'Không có cổ phiếu $_symbol để bán'
                                    : !_isBuy && !validShares
                                        ? 'Khối lượng bán vượt quá khả dụng'
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
        child: Row(
            children: [_sideButton('MUA', true), _sideButton('BÁN', false)]),
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
  }) =>
      TextField(
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

  Widget _priceMark(String title, String price, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
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
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ],
          ),
        ),
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
          final accountId = _selectedAccountId ?? await _api.firstAccountId();
          await _api.placeOrder(accountId, {
            'client_order_id': _orderIntentId(symbol, _isBuy, quantity, price),
            'stock_symbol': symbol,
            'order_type': _isBuy ? 'BUY' : 'SELL',
            'order_kind': 'LO',
            'quantity': quantity,
            'order_price': (price * 1000).toStringAsFixed(2),
          });
          await _loadAccountBalances(accountId);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Đã gửi lệnh thành công! Vào Sổ lệnh để theo dõi trạng thái.',
              ),
              action: SnackBarAction(
                label: 'Xem sổ lệnh',
                textColor: AppColors.primary,
                onPressed: () => context.go('/home/orders'),
              ),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không đặt được lệnh: $error')),
          );
        }
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

  String _number(int value) => value
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}
