import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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
    final controller = TextEditingController();
    final side = _order.orderType == 'BUY' ? 'mua' : 'bán';
    // Controller sống ngắn, không dispose ngay để tránh lỗi khi hộp thoại đang đóng.
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Hủy lệnh', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hủy lệnh $side ${_order.stockSymbol} của ${_order.customerName}? '
              'Lệnh sẽ chuyển sang trạng thái Đã hủy.',
              style: const TextStyle(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 255,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Lý do hủy (tùy chọn)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text(
              'Hủy lệnh',
              style: TextStyle(color: AppColors.priceDown),
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
      showAdminSnack(context, 'Đã hủy lệnh');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _delete() async {
    final ok = await showAdminConfirm(
      context,
      title: 'Xóa lệnh',
      message: 'Xóa vĩnh viễn lệnh #${_order.orderId} '
          '(${_order.stockSymbol}, ${_order.customerName})? '
          'Hành động này không thể hoàn tác.',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).deleteOrder(_order.orderId);
      if (!mounted) return;
      showAdminSnack(context, 'Đã xóa lệnh');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    final isMarket = o.orderKind == 'MP' || num.tryParse(o.orderPrice) == 0;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Lệnh #${o.orderId}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AdminConstants.label(o.orderType)} ${o.stockSymbol}',
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
                AdminInfoRow(label: 'Khách hàng', value: o.customerName),
                AdminInfoRow(label: 'Tài khoản', value: o.accountNumber),
                AdminInfoRow(
                  label: 'Hình thức',
                  value: AdminConstants.label(o.orderKind),
                ),
                AdminInfoRow(
                  label: 'Giá đặt',
                  value: isMarket ? 'Giá thị trường' : formatVnd(o.orderPrice),
                ),
                AdminInfoRow(
                  label: 'Số lượng',
                  value: formatNumber(o.quantity.toString()),
                ),
                AdminInfoRow(
                  label: 'Đã khớp',
                  value: formatNumber(o.filledQuantity.toString()),
                ),
                AdminInfoRow(
                  label: 'Còn lại',
                  value: formatNumber(o.remainingQuantity.toString()),
                ),
                AdminInfoRow(
                  label: 'Ngày đặt',
                  value: formatDateTime(o.orderDate),
                ),
                if (o.matchedAt != null)
                  AdminInfoRow(
                    label: 'Thời điểm khớp',
                    value: formatDateTime(o.matchedAt!),
                  ),
                if (o.rejectReason != null && o.rejectReason!.isNotEmpty)
                  AdminInfoRow(label: 'Lý do', value: o.rejectReason!),
                AdminInfoRow(label: 'Mã tham chiếu', value: o.clientOrderId),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (o.canCancel)
            _actionTile(
              icon: Icons.cancel_rounded,
              label: 'Hủy lệnh',
              danger: true,
              onTap: _cancel,
            ),
          if (o.canDelete)
            _actionTile(
              icon: Icons.delete_forever_rounded,
              label: 'Xóa lệnh',
              danger: true,
              onTap: _delete,
            ),
          if (!o.canCancel && !o.canDelete)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Lệnh đã khớp nên không thể can thiệp.',
                style: TextStyle(color: AppColors.darkTextMuted),
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