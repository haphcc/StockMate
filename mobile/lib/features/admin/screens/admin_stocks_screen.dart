import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_page.dart';
import '../data/models/admin_stock_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_stock_form_screen.dart';

class AdminStocksScreen extends ConsumerStatefulWidget {
  const AdminStocksScreen({super.key});

  @override
  ConsumerState<AdminStocksScreen> createState() => _AdminStocksScreenState();
}

class _AdminStocksScreenState extends ConsumerState<AdminStocksScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _q = '';
  String? _exchange;
  String? _status;
  int _page = 1;

  AdminStockQuery get _query => AdminStockQuery(
        q: _q,
        exchange: _exchange,
        status: _status,
        page: _page,
      );

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _q = value.trim();
        _page = 1;
      });
    });
  }

  Future<void> _openForm({AdminStockModel? stock}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminStockFormScreen(stock: stock),
      ),
    );
    if (changed == true) ref.invalidate(adminStocksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminStocksProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mã cổ phiếu'),
        actions: [
          IconButton(
            tooltip: 'Thêm mã cổ phiếu',
            icon: const Icon(Icons.add_chart_rounded),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Tìm theo mã hoặc tên công ty',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.darkTextMuted,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          AdminFilterChips(
            options: AdminConstants.exchanges,
            selected: _exchange,
            onChanged: (v) => setState(() {
              _exchange = v;
              _page = 1;
            }),
          ),
          AdminFilterChips(
            options: AdminConstants.stockStatuses,
            selected: _status,
            onChanged: (v) => setState(() {
              _status = v;
              _page = 1;
            }),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminStocksProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.candlestick_chart_outlined,
                    message: 'Không tìm thấy mã cổ phiếu nào',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: page.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _stockTile(page.items[i]),
                      ),
                    ),
                    _pager(page),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _trendColor(AdminStockModel s) {
    if (s.trend > 0) return AppColors.priceUp;
    if (s.trend < 0) return AppColors.priceDown;
    return AppColors.priceRef;
  }

  Widget _stockTile(AdminStockModel s) {
    final color = _trendColor(s);
    final sign = s.trend > 0 ? '+' : '';
    return AdminCard(
      onTap: () => _openForm(stock: s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      s.stockSymbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.exchange,
                      style: const TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  s.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trần ${formatNumber(s.ceilingPrice)} · '
                  'TC ${formatNumber(s.referencePrice)} · '
                  'Sàn ${formatNumber(s.floorPrice)}',
                  style: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatNumber(s.currentPrice),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$sign${s.changePercent}%',
                style: TextStyle(color: color, fontSize: 12),
              ),
              const SizedBox(height: 4),
              AdminStatusBadge(code: s.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pager(AdminPage<AdminStockModel> page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: page.page > 1
                ? () => setState(() => _page = page.page - 1)
                : null,
            child: const Text('Trước'),
          ),
          Text(
            'Trang ${page.page}/${page.totalPages} · ${page.total} mã',
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: page.page < page.totalPages
                ? () => setState(() => _page = page.page + 1)
                : null,
            child: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}