import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/price_colors.dart';
import '../../../data/models/stock_model.dart';
import '../../../providers/app_providers.dart';
import 'package:go_router/go_router.dart';

class StockSearchDialog extends ConsumerStatefulWidget {
  const StockSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const StockSearchDialog(),
    );
  }

  @override
  ConsumerState<StockSearchDialog> createState() => _StockSearchDialogState();
}

class _StockSearchDialogState extends ConsumerState<StockSearchDialog> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<StockModel> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStocks('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchStocks(query);
    });
  }

  Future<void> _fetchStocks(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(marketRepositoryProvider);
      final items = await repo.getMarketBoard(
        exchange: 'ALL',
        q: query.trim().isEmpty ? null : query.trim(),
      );
      if (!mounted) return;
      setState(() {
        _results = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải danh sách cổ phiếu.';
      });
    }
  }

  Color _getPriceColor(PriceState state) {
    switch (state) {
      case PriceState.ceiling:
        return AppColors.priceCeiling;
      case PriceState.floor:
        return AppColors.priceFloor;
      case PriceState.up:
        return AppColors.priceUp;
      case PriceState.down:
        return AppColors.priceDown;
      case PriceState.reference:
        return AppColors.priceRef;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          children: [
            // Header Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkCardBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onChanged: _onQueryChanged,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm mã chứng khoán, tên công ty...',
                          hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppColors.darkTextSecondary, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchStocks('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.darkTextSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.darkCardBorder, height: 1),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.priceDown),
                          ),
                        )
                      : _results.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy mã cổ phiếu nào.',
                                style: TextStyle(color: AppColors.darkTextSecondary),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _results.length,
                              separatorBuilder: (_, _) => const Divider(
                                color: AppColors.darkCardBorder,
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final stock = _results[index];
                                final priceColor = _getPriceColor(stock.priceState);

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  title: Row(
                                    children: [
                                      Text(
                                        stock.symbol,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.darkBackground,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.darkCardBorder),
                                        ),
                                        child: Text(
                                          stock.exchange,
                                          style: const TextStyle(
                                            color: AppColors.darkTextSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      stock.companyName,
                                      style: const TextStyle(
                                        color: AppColors.darkTextSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        (stock.currentPrice / 1000).toStringAsFixed(1),
                                        style: TextStyle(
                                          color: priceColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${stock.changeAmount >= 0 ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          color: priceColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.push('/home/overview/stock/${stock.symbol}');
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
