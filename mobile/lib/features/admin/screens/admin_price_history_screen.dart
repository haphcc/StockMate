import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/admin_candle_model.dart';
import '../data/models/admin_page.dart';
import '../data/models/admin_stock_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_candle_chart.dart';
import '../widgets/admin_widgets.dart';
import 'admin_candle_form_screen.dart';

class AdminPriceHistoryScreen extends ConsumerStatefulWidget {
  const AdminPriceHistoryScreen({super.key});

  @override
  ConsumerState<AdminPriceHistoryScreen> createState() =>
      _AdminPriceHistoryScreenState();
}

class _AdminPriceHistoryScreenState
    extends ConsumerState<AdminPriceHistoryScreen> {
  AdminStockModel? _stock;
  int _page = 1;

  Future<void> _pickStock() async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final page = await repo.listStocks(pageSize: 100);
      if (!mounted) return;
      final picked = await showModalBottomSheet<AdminStockModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.darkSurface,
        builder: (sheetContext) => SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.7,
          child: ListView(
            children: [
              for (final s in page.items)
                ListTile(
                  title: Text(
                    '${s.stockSymbol} · ${s.exchange}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    s.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.darkTextSecondary),
                  ),
                  onTap: () => Navigator.pop(sheetContext, s),
                ),
            ],
          ),
        ),
      );
      if (picked != null && mounted) {
        setState(() {
          _stock = picked;
          _page = 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _openForm({AdminCandleModel? candle}) async {
    final stock = _stock;
    if (stock == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminCandleFormScreen(stock: stock, candle: candle),
      ),
    );
    if (changed == true) ref.invalidate(adminCandlesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final stock = _stock;
    final async = stock == null
        ? null
        : ref.watch(
            adminCandlesProvider(
              AdminCandleQuery(stockSymbol: stock.stockSymbol, page: _page),
            ),
          );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Lịch sử giá'),
        actions: [
          IconButton(
            tooltip: 'Thêm phiên giá',
            icon: const Icon(Icons.post_add_rounded),
            onPressed: stock == null ? null : () => _openForm(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          AdminCard(
            onTap: _pickStock,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    stock == null
                        ? 'Chọn mã cổ phiếu...'
                        : '${stock.stockSymbol} · ${stock.companyName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: stock == null
                          ? AppColors.darkTextMuted
                          : Colors.white,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.darkTextMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (async == null)
            _hint(
              Icons.show_chart_rounded,
              'Chọn mã cổ phiếu để xem lịch sử giá',
            )
          else
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => AdminCard(
                onTap: () => ref.invalidate(adminCandlesProvider),
                child: Text(
                  'Không tải được lịch sử giá: $e\nBấm để thử lại.',
                  style: const TextStyle(color: AppColors.priceDown),
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return _hint(
                    Icons.candlestick_chart_outlined,
                    'Mã này chưa có dữ liệu nến',
                  );
                }
                // Danh sách xếp ngày giảm dần; biểu đồ cần cũ đến mới.
                final ascending = page.items.reversed.toList();
                return Column(
                  children: [
                    AdminCard(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              'Biểu đồ nến · ${ascending.length} phiên '
                              '(trang $_page)',
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          AdminCandleChart(candles: ascending),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final c in page.items) ...[
                      _candleTile(c),
                      const SizedBox(height: 8),
                    ],
                    _pager(page),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _hint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.darkTextMuted),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(color: AppColors.darkTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _candleTile(AdminCandleModel c) {
    final color = c.isUp ? AppColors.priceUp : AppColors.priceDown;
    return AdminCard(
      onTap: () => _openForm(candle: c),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.displayDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mở ${formatNumber(c.openPrice)} · '
                  'Cao ${formatNumber(c.highestPrice)} · '
                  'Thấp ${formatNumber(c.lowestPrice)}',
                  style: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'KL ${formatNumber(c.tradingVolume.toString())}',
                  style: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Đóng',
                style: TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
              ),
              Text(
                formatNumber(c.closePrice),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pager(AdminPage<AdminCandleModel> page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: page.page > 1
              ? () => setState(() => _page = page.page - 1)
              : null,
          child: const Text('Trước'),
        ),
        Text(
          'Trang ${page.page}/${page.totalPages} · ${page.total} phiên',
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
    );
  }
}