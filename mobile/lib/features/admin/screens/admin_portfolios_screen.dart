import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../data/models/admin_page.dart';
import '../data/models/admin_portfolio_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_portfolio_form_screen.dart';

class AdminPortfoliosScreen extends ConsumerStatefulWidget {
  const AdminPortfoliosScreen({super.key});

  @override
  ConsumerState<AdminPortfoliosScreen> createState() =>
      _AdminPortfoliosScreenState();
}

class _AdminPortfoliosScreenState extends ConsumerState<AdminPortfoliosScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _symbol = '';
  int _page = 1;

  AdminPortfolioQuery get _query =>
      AdminPortfolioQuery(stockSymbol: _symbol, page: _page);

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
        _symbol = value.trim().toUpperCase();
        _page = 1;
      });
    });
  }

  Future<void> _openForm({AdminPortfolioModel? portfolio}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminPortfolioFormScreen(portfolio: portfolio),
      ),
    );
    if (changed == true) ref.invalidate(adminPortfoliosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminPortfoliosProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Danh mục nắm giữ'),
        actions: [
          IconButton(
            tooltip: 'Thêm dòng nắm giữ',
            icon: const Icon(Icons.add_circle_outline_rounded),
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
              hintText: 'Nhập đúng mã cổ phiếu (ví dụ ACB)',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.darkTextMuted,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminPortfoliosProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.pie_chart_outline_rounded,
                    message: 'Không có dòng nắm giữ nào',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: page.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _tile(page.items[i]),
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

  Widget _tile(AdminPortfolioModel p) {
    final color = p.trend > 0
        ? AppColors.priceUp
        : (p.trend < 0 ? AppColors.priceDown : AppColors.priceRef);
    final sign = p.trend > 0 ? '+' : '';
    return AdminCard(
      onTap: () => _openForm(portfolio: p),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.stockSymbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.customerName} · ${p.accountNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SL ${formatNumber(p.quantity.toString())} '
                  '(khả dụng ${formatNumber(p.availableQuantity.toString())} · '
                  'phong tỏa ${formatNumber(p.blockedQuantity.toString())}) · '
                  'Giá vốn ${formatNumber(p.averagePrice)}',
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
                formatVnd(p.currentValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$sign${p.profitLossPercent}%',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pager(AdminPage<AdminPortfolioModel> page) {
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
            'Trang ${page.page}/${page.totalPages} · ${page.total} dòng',
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