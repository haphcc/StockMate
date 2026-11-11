import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_order_model.dart';
import '../data/models/admin_page.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _symbol = '';
  String? _status;
  String? _type;
  int _page = 1;

  AdminOrderQuery get _query => AdminOrderQuery(
        stockSymbol: _symbol,
        status: _status,
        orderType: _type,
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

  Future<void> _openDetail(AdminOrderModel order) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminOrderDetailScreen(order: order),
      ),
    );
    ref.invalidate(adminOrdersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminOrdersProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Sổ lệnh'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Nhập đúng mã cổ phiếu (ví dụ VCB)',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.darkTextMuted,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          AdminFilterChips(
            options: AdminConstants.orderStatuses,
            selected: _status,
            onChanged: (v) => setState(() {
              _status = v;
              _page = 1;
            }),
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
                onRetry: () => ref.invalidate(adminOrdersProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'Không tìm thấy lệnh nào',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: page.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _orderTile(page.items[i]),
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

  Widget _orderTile(AdminOrderModel o) {
    final color =
        o.orderType == 'BUY' ? AppColors.priceUp : AppColors.priceDown;
    final isMarket = o.orderKind == 'MP' || num.tryParse(o.orderPrice) == 0;
    final price = isMarket ? 'Giá thị trường' : formatNumber(o.orderPrice);
    return AdminCard(
      onTap: () => _openDetail(o),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      o.stockSymbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AdminConstants.label(o.orderType),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AdminConstants.label(o.orderKind),
                      style: const TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${o.customerName} · ${o.accountNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khớp ${formatNumber(o.filledQuantity.toString())}/'
                  '${formatNumber(o.quantity.toString())} · $price · '
                  '${formatDateTime(o.orderDate)}',
                  style: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AdminStatusBadge(code: o.status),
        ],
      ),
    );
  }

  Widget _pager(AdminPage<AdminOrderModel> page) {
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
            'Trang ${page.page}/${page.totalPages} · ${page.total} lệnh',
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