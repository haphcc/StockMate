import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_page.dart';
import '../data/models/admin_transaction_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminTransactionsScreen extends ConsumerStatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  ConsumerState<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState
    extends ConsumerState<AdminTransactionsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _symbol = '';
  String? _type;
  int _page = 1;

  AdminTransactionQuery get _query => AdminTransactionQuery(
        stockSymbol: _symbol,
        transactionType: _type,
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
        _symbol = value.trim().toUpperCase();
        _page = 1;
      });
    });
  }

  void _showDetail(AdminTransactionModel t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminInfoRow(label: 'Mã giao dịch', value: '#${t.transactionId}'),
            AdminInfoRow(label: 'Mã lệnh', value: '#${t.orderId}'),
            AdminInfoRow(label: 'Tài khoản', value: t.accountNumber),
            AdminInfoRow(label: 'Cổ phiếu', value: t.stockSymbol),
            AdminInfoRow(
              label: 'Loại',
              value: AdminConstants.label(t.transactionType),
            ),
            AdminInfoRow(
              label: 'Số lượng',
              value: formatNumber(t.quantity.toString()),
            ),
            AdminInfoRow(label: 'Giá khớp', value: formatVnd(t.price)),
            AdminInfoRow(label: 'Giá trị', value: formatVnd(t.totalAmount)),
            AdminInfoRow(label: 'Phí', value: formatVnd(t.transactionFee)),
            AdminInfoRow(label: 'Thuế', value: formatVnd(t.taxAmount)),
            AdminInfoRow(label: 'Thực thu/chi', value: formatVnd(t.netAmount)),
            AdminInfoRow(
              label: 'Ngày khớp',
              value: formatDateTime(t.transactionDate),
            ),
            if (t.settlementDate != null)
              AdminInfoRow(label: 'Ngày thanh toán', value: t.settlementDate!),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminTransactionsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Lịch sử giao dịch'),
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
          AdminFilterChips(
            options: AdminConstants.orderTypes,
            selected: _type,
            onChanged: (v) => setState(() {
              _type = v;
              _page = 1;
            }),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminTransactionsProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.swap_horiz_rounded,
                    message: 'Không tìm thấy giao dịch nào',
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

  Widget _tile(AdminTransactionModel t) {
    final color =
        t.transactionType == 'BUY' ? AppColors.priceUp : AppColors.priceDown;
    return AdminCard(
      onTap: () => _showDetail(t),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      t.stockSymbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AdminConstants.label(t.transactionType),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatNumber(t.quantity.toString())} × '
                  '${formatNumber(t.price)} · ${t.accountNumber}',
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDateTime(t.transactionDate),
                  style: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatVnd(t.netAmount),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pager(AdminPage<AdminTransactionModel> page) {
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
            'Trang ${page.page}/${page.totalPages} · ${page.total} giao dịch',
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