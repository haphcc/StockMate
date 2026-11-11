import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_account_model.dart';
import '../data/models/admin_customer_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_customer_form_screen.dart';
import 'admin_account_form_screen.dart';
import 'admin_notification_compose_screen.dart';

class AdminCustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;

  const AdminCustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<AdminCustomerDetailScreen> createState() =>
      _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState
    extends ConsumerState<AdminCustomerDetailScreen> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(adminCustomerDetailProvider(widget.customerId));
    ref.invalidate(adminCustomersProvider);
  }

  /// Chạy một thao tác, hiện thông báo thành công hoặc lỗi, rồi tải lại dữ liệu.
  Future<void> _run(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _refresh();
      showAdminSnack(context, successMessage);
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(AdminCustomerModel c, bool isSelf) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminCustomerFormScreen(customer: c, isSelf: isSelf),
      ),
    );
    if (changed == true) _refresh();
  }

  Future<void> _toggleLock(AdminCustomerModel c) async {
    final lock = c.status == 'ACTIVE';
    final ok = await showAdminConfirm(
      context,
      title: lock ? 'Khóa khách hàng' : 'Kích hoạt khách hàng',
      message: lock
          ? 'Khóa ${c.fullName}? Khách hàng sẽ không đăng nhập được.'
          : 'Kích hoạt lại ${c.fullName}?',
      confirmText: lock ? 'Khóa' : 'Kích hoạt',
      danger: lock,
    );
    if (!ok) return;
    await _run(
      () => ref.read(adminRepositoryProvider).updateCustomer(
        c.customerId,
        {'status': lock ? 'LOCKED' : 'ACTIVE'},
      ),
      lock ? 'Đã khóa khách hàng' : 'Đã kích hoạt khách hàng',
    );
  }

  Future<void> _changeRole(AdminCustomerModel c) async {
    var selected = c.role;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: const Text(
            'Đổi vai trò',
            style: TextStyle(color: Colors.white),
          ),
          content: Wrap(
            spacing: 8,
            children: [
              for (final role in AdminConstants.customerRoles)
                ChoiceChip(
                  label: Text(AdminConstants.label(role)),
                  selected: selected == role,
                  showCheckmark: false,
                  onSelected: (_) => setLocal(() => selected = role),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result == c.role) return;
    await _run(
      () => ref.read(adminRepositoryProvider).updateCustomer(
        c.customerId,
        {'role': result},
      ),
      'Đã đổi vai trò',
    );
  }

  Future<void> _resetPassword(AdminCustomerModel c) async {
    // Controller sống ngắn, không dispose ngay để tránh lỗi khi hộp thoại đang đóng.
    final controller = TextEditingController();
    String? error;
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: const Text(
            'Đặt lại mật khẩu',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text;
                if (value.length < 6) {
                  setLocal(() => error = 'Tối thiểu 6 ký tự');
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Đặt lại'),
            ),
          ],
        ),
      ),
    );
    if (password == null) return;
    await _run(
      () => ref.read(adminRepositoryProvider).updateCustomer(
        c.customerId,
        {'password': password},
      ),
      'Đã đặt lại mật khẩu',
    );
  }

  Future<void> _delete(AdminCustomerModel c) async {
    final ok = await showAdminConfirm(
      context,
      title: 'Xóa khách hàng',
      message: 'Xóa vĩnh viễn ${c.fullName} cùng toàn bộ tài khoản, lệnh, '
          'giao dịch và dữ liệu liên quan? Hành động này không thể hoàn tác.',
      confirmText: 'Xóa vĩnh viễn',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).deleteCustomer(c.customerId);
      ref.invalidate(adminCustomersProvider);
      if (!mounted) return;
      showAdminSnack(context, 'Đã xóa khách hàng');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

    Future<void> _notify(AdminCustomerModel c) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminNotificationComposeScreen(presetCustomer: c),
      ),
    );
  }

    Future<void> _openAccount(AdminCustomerModel c) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminAccountFormScreen(presetCustomer: c),
      ),
    );
    if (created == true) _refresh();
  }

  Future<void> _editAccount(AdminAccountModel a) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminAccountFormScreen(account: a),
      ),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminCustomerDetailProvider(widget.customerId));
    final selfEmail = ref.watch(authProvider).value?.email.toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Chi tiết khách hàng'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: _refresh,
        ),
        data: (c) => _buildBody(c, c.email.toLowerCase() == selfEmail),
      ),
    );
  }

  Widget _buildBody(AdminCustomerModel c, bool isSelf) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                c.fullName.trim().isEmpty ? '?' : c.fullName.trim()[0],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      AdminStatusBadge(code: c.status),
                      AdminStatusBadge(code: c.role),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminCard(
          child: Column(
            children: [
              AdminInfoRow(label: 'Email', value: c.email),
              AdminInfoRow(label: 'Số điện thoại', value: c.phoneNumber),
              if (c.dateOfBirth != null)
                AdminInfoRow(label: 'Ngày sinh', value: c.dateOfBirth!),
              if (c.idCardNumber != null)
                AdminInfoRow(label: 'CCCD', value: c.idCardNumber!),
              if (c.address != null)
                AdminInfoRow(label: 'Địa chỉ', value: c.address!),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tài khoản đầu tư (${c.accounts.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (c.accounts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Khách hàng chưa có tài khoản đầu tư.',
              style: TextStyle(color: AppColors.darkTextMuted),
            ),
          )
        else
          for (final account in c.accounts) ...[
            _accountTile(account),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        if (isSelf)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Đây là tài khoản bạn đang đăng nhập: không thể đổi vai trò, '
              'khóa hoặc xóa.',
              style: TextStyle(color: AppColors.priceRef, fontSize: 12),
            ),
          ),
        _actionTile(
          icon: Icons.edit_rounded,
          label: 'Sửa thông tin',
          onTap: () => _edit(c, isSelf),
        ),
        _actionTile(
          icon: Icons.add_card_rounded,
          label: 'Mở tài khoản đầu tư',
          onTap: () => _openAccount(c),
        ),
        _actionTile(
          icon: Icons.notifications_active_rounded,
          label: 'Gửi thông báo',
          onTap: () => _notify(c),
        ),
        _actionTile(
          icon: Icons.lock_reset_rounded,
          label: 'Đặt lại mật khẩu',
          onTap: () => _resetPassword(c),
        ),
        _actionTile(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Đổi vai trò',
          enabled: !isSelf,
          onTap: () => _changeRole(c),
        ),
        _actionTile(
          icon: c.status == 'ACTIVE'
              ? Icons.lock_rounded
              : Icons.lock_open_rounded,
          label: c.status == 'ACTIVE' ? 'Khóa tài khoản' : 'Kích hoạt',
          enabled: !isSelf,
          onTap: () => _toggleLock(c),
        ),
        _actionTile(
          icon: Icons.delete_forever_rounded,
          label: 'Xóa khách hàng',
          danger: true,
          enabled: !isSelf,
          onTap: () => _delete(c),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _accountTile(AdminAccountModel a) {
    return AdminCard(
      onTap: () => _editAccount(a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.accountNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                AdminConstants.label(a.accountType),
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              AdminStatusBadge(code: a.status),
            ],
          ),
          const SizedBox(height: 6),
          AdminInfoRow(label: 'Tiền mặt', value: formatVnd(a.cashBalance)),
          AdminInfoRow(
            label: 'Tổng tài sản',
            value: formatVnd(a.totalAssetValue),
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
    bool enabled = true,
  }) {
    final color = danger ? AppColors.priceDown : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: enabled && !_busy ? 1 : 0.4,
        child: AdminCard(
          onTap: enabled && !_busy ? onTap : null,
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
      ),
    );
  }
}