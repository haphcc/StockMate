import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_order_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final AdminOrderModel order;

  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  late AdminOrderModel _order;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _cancel() async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    final controller = TextEditingController();
    final side = _order.orderType == 'BUY'
        ? (isVi ? 'mua' : 'buy')
        : (isVi ? 'bán' : 'sell');
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          isVi ? 'Hủy lệnh' : 'Cancel Order',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isVi
                  ? 'Hủy lệnh $side ${_order.stockSymbol} của ${_order.customerName}? '
                      'Lệnh sẽ chuyển sang trạng thái Đã hủy.'
                  : 'Cancel $side order ${_order.stockSymbol} of ${_order.customerName}? '
                      'The order will be changed to Cancelled.',
              style: const TextStyle(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 255,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isVi
                    ? 'Lý do hủy (tùy chọn)'
                    : 'Cancellation reason (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isVi ? 'Đóng' : 'Close'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(
              isVi ? 'Hủy lệnh' : 'Cancel Order',
              style: const TextStyle(color: AppColors.priceDown),
            ),
          ),
        ],
      ),
    );
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      final updated = await ref.read(adminRepositoryProvider).updateOrder(
        _order.orderId,
        {
          'status': 'CANCELLED',
          if (reason.isNotEmpty) 'reject_reason': reason,
        },
      );
      if (!mounted) return;
      setState(() {
        _order = updated;
        _busy = false;
      });
      showAdminSnack(
        context,
        isVi ? 'Đã hủy lệnh' : 'Order cancelled successfully',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _delete() async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    final ok = await showAdminConfirm(
      context,
      title: isVi ? 'Xóa lệnh' : 'Delete Order',
      message: isVi
          ? 'Xóa vĩnh viễn lệnh #${_order.orderId} '
              '(${_order.stockSymbol}, ${_order.customerName})? '
              'Hành động này không thể hoàn tác.'
          : 'Permanently delete order #${_order.orderId} '
              '(${_order.stockSymbol}, ${_order.customerName})? '
              'This action cannot be undone.',
      confirmText: isVi ? 'Xóa' : 'Delete',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).deleteOrder(_order.orderId);
      if (!mounted) return;
      showAdminSnack(
        context,
        isVi ? 'Đã xóa lệnh' : 'Order deleted successfully',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final isVi = l10n.isVietnamese;
    final o = _order;
    final isMarket = o.orderKind == 'MP' || num.tryParse(o.orderPrice) == 0;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(isVi ? 'Lệnh #${o.orderId}' : 'Order #${o.orderId}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AdminConstants.label(o.orderType, isVi)} ${o.stockSymbol}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AdminStatusBadge(code: o.status),
            ],
          ),
          const SizedBox(height: 16),
          AdminCard(
            child: Column(
              children: [
                AdminInfoRow(
                  label: isVi ? 'Khách hàng' : 'Customer',
                  value: o.customerName,
                ),
                AdminInfoRow(
                  label: isVi ? 'Tài khoản' : 'Account',
                  value: o.accountNumber,
                ),
                AdminInfoRow(
                  label: isVi ? 'Hình thức' : 'Order Type',
                  value: AdminConstants.label(o.orderKind, isVi),
                ),
                AdminInfoRow(
                  label: isVi ? 'Giá đặt' : 'Order Price',
                  value: isMarket
                      ? (isVi ? 'Giá thị trường' : 'Market Price')
                      : formatVnd(o.orderPrice),
                ),
                AdminInfoRow(
                  label: isVi ? 'Số lượng' : 'Quantity',
                  value: formatNumber(o.quantity.toString()),
                ),
                AdminInfoRow(
                  label: isVi ? 'Đã khớp' : 'Filled Quantity',
                  value: formatNumber(o.filledQuantity.toString()),
                ),
                AdminInfoRow(
                  label: isVi ? 'Còn lại' : 'Remaining Quantity',
                  value: formatNumber(o.remainingQuantity.toString()),
                ),
                AdminInfoRow(
                  label: isVi ? 'Ngày đặt' : 'Order Date',
                  value: formatDateTime(o.orderDate),
                ),
                if (o.matchedAt != null)
                  AdminInfoRow(
                    label: isVi ? 'Thời điểm khớp' : 'Matched At',
                    value: formatDateTime(o.matchedAt!),
                  ),
                if (o.rejectReason != null && o.rejectReason!.isNotEmpty)
                  AdminInfoRow(
                    label: isVi ? 'Lý do' : 'Reason',
                    value: o.rejectReason!,
                  ),
                AdminInfoRow(
                  label: isVi ? 'Mã tham chiếu' : 'Client Order ID',
                  value: o.clientOrderId,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (o.canCancel)
            _actionTile(
              icon: Icons.cancel_rounded,
              label: isVi ? 'Hủy lệnh' : 'Cancel Order',
              danger: true,
              onTap: _cancel,
            ),
          if (o.canDelete)
            _actionTile(
              icon: Icons.delete_forever_rounded,
              label: isVi ? 'Xóa lệnh' : 'Delete Order',
              danger: true,
              onTap: _delete,
            ),
          if (!o.canCancel && !o.canDelete)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isVi
                    ? 'Lệnh đã khớp nên không thể can thiệp.'
                    : 'The order is filled and cannot be modified.',
                style: const TextStyle(color: AppColors.darkTextMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.priceDown : Colors.white;
    return Opacity(
      opacity: _busy ? 0.4 : 1,
      child: AdminCard(
        onTap: _busy ? null : onTap,
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}