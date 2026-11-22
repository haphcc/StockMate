import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../../../providers/app_providers.dart';
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
    final isVi = ref.read(l10nProvider).isVietnamese;
    final lock = c.status == 'ACTIVE';
    final ok = await showAdminConfirm(
      context,
      title: lock
          ? (isVi ? 'Khóa khách hàng' : 'Lock Customer')
          : (isVi ? 'Kích hoạt khách hàng' : 'Activate Customer'),
      message: lock
          ? (isVi
              ? 'Khóa ${c.fullName}? Khách hàng sẽ không đăng nhập được.'
              : 'Lock ${c.fullName}? Customer will not be able to log in.')
          : (isVi
              ? 'Kích hoạt lại ${c.fullName}?'
              : 'Reactivate ${c.fullName}?'),
      confirmText: lock
          ? (isVi ? 'Khóa' : 'Lock')
          : (isVi ? 'Kích hoạt' : 'Activate'),
      danger: lock,
    );
    if (!ok) return;
    await _run(
      () => ref.read(adminRepositoryProvider).updateCustomer(
        c.customerId,
        {'status': lock ? 'LOCKED' : 'ACTIVE'},
      ),
      lock
          ? (isVi ? 'Đã khóa khách hàng' : 'Customer locked')
          : (isVi ? 'Đã kích hoạt khách hàng' : 'Customer activated'),
    );
  }

  Future<void> _changeRole(AdminCustomerModel c) async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    var selected = c.role;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: Text(
            isVi ? 'Đổi vai trò' : 'Change Role',
            style: const TextStyle(color: Colors.white),
          ),
          content: Wrap(
            spacing: 8,
            children: [
              for (final role in AdminConstants.customerRoles)
                ChoiceChip(
                  label: Text(AdminConstants.label(role, isVi)),
                  selected: selected == role,
                  showCheckmark: false,
                  onSelected: (_) => setLocal(() => selected = role),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isVi ? 'Hủy' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: Text(isVi ? 'Lưu' : 'Save'),
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
      isVi ? 'Đã đổi vai trò' : 'Role changed successfully',
    );
  }

  Future<void> _resetPassword(AdminCustomerModel c) async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    // Controller sống ngắn, không dispose ngay để tránh lỗi khi hộp thoại đang đóng.
    final controller = TextEditingController();
    String? error;
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: Text(
            isVi ? 'Đặt lại mật khẩu' : 'Reset Password',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: isVi
                  ? 'Mật khẩu mới (tối thiểu 6 ký tự)'
                  : 'New password (min 6 characters)',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isVi ? 'Hủy' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text;
                if (value.length < 6) {
                  setLocal(() => error = isVi
                      ? 'Tối thiểu 6 ký tự'
                      : 'Minimum 6 characters');
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: Text(isVi ? 'Đặt lại' : 'Reset'),
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
      isVi ? 'Đã đặt lại mật khẩu' : 'Password reset successfully',
    );
  }

  Future<void> _delete(AdminCustomerModel c) async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    final ok = await showAdminConfirm(
      context,
      title: isVi ? 'Xóa khách hàng' : 'Delete Customer',
      message: isVi
          ? 'Xóa vĩnh viễn ${c.fullName} cùng toàn bộ tài khoản, lệnh, '
              'giao dịch và dữ liệu liên quan? Hành động này không thể hoàn tác.'
          : 'Permanently delete ${c.fullName} along with all accounts, orders, '
              'transactions and related data? This action cannot be undone.',
      confirmText: isVi ? 'Xóa vĩnh viễn' : 'Delete Permanently',
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).deleteCustomer(c.customerId);
      ref.invalidate(adminCustomersProvider);
      if (!mounted) return;
      showAdminSnack(
        context,
        isVi ? 'Đã xóa khách hàng' : 'Customer deleted successfully',
      );
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
    final l10n = ref.watch(l10nProvider);
    final isVi = l10n.isVietnamese;
    final async = ref.watch(adminCustomerDetailProvider(widget.customerId));
    final selfEmail = ref.watch(authProvider).value?.email.toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(isVi ? 'Chi tiết khách hàng' : 'Customer Details'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: _refresh,
        ),
        data: (c) => _buildBody(c, c.email.toLowerCase() == selfEmail, isVi),
      ),
    );
  }

  Widget _buildBody(AdminCustomerModel c, bool isSelf, bool isVi) {
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
                    runSpacing: 6,
                    children: [
                      AdminStatusBadge(code: c.status),
                      AdminStatusBadge(code: c.role),
                      if (c.isGoogleAccount)
                        const AdminStatusBadge(code: 'GOOGLE'),
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
              AdminInfoRow(
                label: isVi ? 'Đăng nhập' : 'Login Method',
                value: c.isGoogleAccount
                    ? (isVi ? 'Tài khoản Google' : 'Google Account')
                    : (isVi ? 'Email / Mật khẩu' : 'Email / Password'),
              ),
              AdminInfoRow(
                label: isVi ? 'Số điện thoại' : 'Phone Number',
                value: c.displayPhoneNumber,
              ),
              if (c.dateOfBirth != null)
                AdminInfoRow(
                  label: isVi ? 'Ngày sinh' : 'Date of Birth',
                  value: c.dateOfBirth!,
                ),
              if (c.idCardNumber != null)
                AdminInfoRow(
                  label: isVi ? 'CCCD' : 'ID Card Number',
                  value: c.idCardNumber!,
                ),
              if (c.address != null)
                AdminInfoRow(
                  label: isVi ? 'Địa chỉ' : 'Address',
                  value: c.address!,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${isVi ? 'Tài khoản đầu tư' : 'Investment Accounts'} (${c.accounts.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (c.accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              isVi
                  ? 'Khách hàng chưa có tài khoản đầu tư.'
                  : 'Customer has no investment accounts yet.',
              style: const TextStyle(color: AppColors.darkTextMuted),
            ),
          )
        else
          for (final account in c.accounts) ...[
            _accountTile(account, isVi),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        if (isSelf)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              isVi
                  ? 'Đây là tài khoản bạn đang đăng nhập: không thể đổi vai trò, khóa hoặc xóa.'
                  : 'This is your active account: role change, locking, or deletion is disabled.',
              style: const TextStyle(color: AppColors.priceRef, fontSize: 12),
            ),
          ),
        _actionTile(
          icon: Icons.edit_rounded,
          label: isVi ? 'Sửa thông tin' : 'Edit Information',
          onTap: () => _edit(c, isSelf),
        ),
        _actionTile(
          icon: Icons.add_card_rounded,
          label: isVi ? 'Mở tài khoản đầu tư' : 'Open Investment Account',
          onTap: () => _openAccount(c),
        ),
        _actionTile(
          icon: Icons.notifications_active_rounded,
          label: isVi ? 'Gửi thông báo' : 'Send Notification',
          onTap: () => _notify(c),
        ),
        _actionTile(
          icon: Icons.lock_reset_rounded,
          label: isVi ? 'Đặt lại mật khẩu' : 'Reset Password',
          onTap: () => _resetPassword(c),
        ),
        _actionTile(
          icon: Icons.admin_panel_settings_rounded,
          label: isVi ? 'Đổi vai trò' : 'Change Role',
          enabled: !isSelf,
          onTap: () => _changeRole(c),
        ),
        _actionTile(
          icon: c.status == 'ACTIVE'
              ? Icons.lock_rounded
              : Icons.lock_open_rounded,
          label: c.status == 'ACTIVE'
              ? (isVi ? 'Khóa tài khoản' : 'Lock Account')
              : (isVi ? 'Kích hoạt' : 'Activate'),
          enabled: !isSelf,
          onTap: () => _toggleLock(c),
        ),
        _actionTile(
          icon: Icons.delete_forever_rounded,
          label: isVi ? 'Xóa khách hàng' : 'Delete Customer',
          danger: true,
          enabled: !isSelf,
          onTap: () => _delete(c),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _accountTile(AdminAccountModel a, bool isVi) {
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
                AdminConstants.label(a.accountType, isVi),
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
          AdminInfoRow(
            label: isVi ? 'Tiền mặt' : 'Cash',
            value: formatVnd(a.cashBalance),
          ),
          AdminInfoRow(
            label: isVi ? 'Tổng tài sản' : 'Total Assets',
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