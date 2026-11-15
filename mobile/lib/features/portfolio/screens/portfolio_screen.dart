import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stockmate_brand.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _api = StockmateApi();
  final _money = NumberFormat('#,##0', 'vi_VN');
  List<Map<String, dynamic>> _accounts = [];
  int? _accountId;
  Map<String, dynamic>? _assets;
  List<Map<String, dynamic>> _holdings = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accounts = await _api.accounts();
      if (accounts.isEmpty)
        throw Exception('Tài khoản chưa có tài khoản đầu tư.');
      _accounts = accounts;
      _accountId ??= await _api.firstAccountId();
      await _loadAccountData();
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error;
        });
    }
  }

  Future<void> _loadAccountData() async {
    final id = _accountId;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([_api.assets(id), _api.portfolio(id)]);
      if (mounted)
        setState(() {
          _assets = Map<String, dynamic>.from(values[0] as Map);
          _holdings = List<Map<String, dynamic>>.from(values[1] as List);
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error;
        });
    }
  }

  String _vnd(dynamic value) {
    final amount = double.tryParse('$value') ?? 0;
    return '${_money.format(amount)} đ';
  }

  @override
  Widget build(BuildContext context) {
    final asset = _assets;
    final pnl = double.tryParse('${asset?['total_profit_loss']}') ?? 0;
    final pnlPercent = double.tryParse('${asset?['profit_loss_percent']}') ?? 0;
    final available =
        (double.tryParse('${asset?['cash_balance']}') ?? 0) -
        (double.tryParse('${asset?['blocked_balance']}') ?? 0);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Danh mục đầu tư'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: StockMateBrand(iconSize: 24, fontSize: 16),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Không tải được tài sản: $_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _loadAccounts,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAccountData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_accounts.length > 1) ...[
                    const Text(
                      'TÀI KHOẢN ĐẦU TƯ',
                      style: TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _accountId,
                      dropdownColor: AppColors.darkSurface,
                      decoration: const InputDecoration(filled: true),
                      items: _accounts
                          .map(
                            (account) => DropdownMenuItem(
                              value: (account['account_id'] as num).toInt(),
                              child: Text(
                                '${account['account_number']} · ${account['account_type']}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _accountId = value);
                        _api.selectAccount(value);
                        _loadAccountData();
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF162232), Color(0xFF131926)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng tài sản ròng',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _vnd(asset?['total_asset_value']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _stat(
                              'Lãi / Lỗ',
                              '${pnl >= 0 ? '+' : ''}${_vnd(pnl)} (${pnlPercent.toStringAsFixed(2)}%)',
                              pnl >= 0
                                  ? AppColors.primary
                                  : AppColors.priceDown,
                            ),
                            _stat('Sức mua', _vnd(available), Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DANH MỤC NẮM GIỮ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .5,
                        ),
                      ),
                      Text(
                        '${_holdings.length} mã',
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_holdings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'Chưa có cổ phiếu trong danh mục',
                          style: TextStyle(color: AppColors.darkTextSecondary),
                        ),
                      ),
                    )
                  else
                    ..._holdings.map(_holdingCard),
                ],
              ),
            ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _holdingCard(Map<String, dynamic> item) {
    final profit = double.tryParse('${item['profit_loss']}') ?? 0;
    final percent = double.tryParse('${item['profit_loss_percent']}') ?? 0;
    final positive = profit >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
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
                      '${item['stock_symbol']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item['company_name']}',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _vnd(profit),
                    style: TextStyle(
                      color: positive ? AppColors.primary : AppColors.priceDown,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: positive ? AppColors.primary : AppColors.priceDown,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.darkCardBorder, height: 22),
          Wrap(
            spacing: 22,
            runSpacing: 10,
            children: [
              _holdingValue('SỐ LƯỢNG', '${item['quantity']} cp'),
              _holdingValue(
                'GIÁ VỐN',
                '${((double.tryParse('${item['average_price']}') ?? 0) / 1000).toStringAsFixed(1)} nghìn',
              ),
              _holdingValue(
                'THỊ GIÁ',
                '${((double.tryParse('${item['market_price']}') ?? 0) / 1000).toStringAsFixed(1)} nghìn',
              ),
              _holdingValue('GIÁ TRỊ', _vnd(item['current_value'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _holdingValue(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.darkTextMuted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
