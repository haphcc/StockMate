import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../providers/app_providers.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_account_model.dart';
import '../data/models/admin_customer_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminAccountFormScreen extends ConsumerStatefulWidget {
  /// null = mở tài khoản mới, khác null = sửa.
  final AdminAccountModel? account;

  /// Khách hàng chọn sẵn khi mở mới (từ màn hình chi tiết khách hàng).
  final AdminCustomerModel? presetCustomer;

  const AdminAccountFormScreen({
    super.key,
    this.account,
    this.presetCustomer,
  });

  @override
  ConsumerState<AdminAccountFormScreen> createState() =>
      _AdminAccountFormScreenState();
}

class _AdminAccountFormScreenState
    extends ConsumerState<AdminAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  late final TextEditingController _cash;
  late final TextEditingController _blocked;
  late final TextEditingController _asset;
  late final TextEditingController _margin;
  late String _type;
  late String _status;
  AdminCustomerModel? _customer;
  bool _saving = false;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _customer = widget.presetCustomer;
    _cash = TextEditingController(text: a?.cashBalance ?? '');
    _blocked = TextEditingController(text: a?.blockedBalance ?? '');
    _asset = TextEditingController(text: a?.totalAssetValue ?? '');
    _margin = TextEditingController(text: a?.marginLimit ?? '');
    _type = a?.accountType ?? 'CASH';
    _status = a?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _number.dispose();
    _cash.dispose();
    _blocked.dispose();
    _asset.dispose();
    _margin.dispose();
    super.dispose();
  }

  String? _validateMoney(String? v, {required bool isRequired, required bool isVi}) {
    final value = (v ?? '').trim();
    if (value.isEmpty) {
      return isRequired
          ? (isVi ? 'Không được để trống' : 'Cannot be empty')
          : null;
    }
    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
      return isVi
          ? 'Nhập số không âm, tối đa 2 chữ số thập phân'
          : 'Enter non-negative number, up to 2 decimal places';
    }
    return null;
  }

  Future<void> _pickCustomer() async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final page = await repo.listCustomers(pageSize: 100);
      if (!mounted) return;
      final picked = await showModalBottomSheet<AdminCustomerModel>(
        context: context,
        backgroundColor: AppColors.darkSurface,
        builder: (sheetContext) => ListView(
          children: [
            for (final c in page.items)
              ListTile(
                title: Text(
                  c.fullName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  c.email,
                  style: const TextStyle(color: AppColors.darkTextSecondary),
                ),
                onTap: () => Navigator.pop(sheetContext, c),
              ),
          ],
        ),
      );
      if (picked != null && mounted) setState(() => _customer = picked);
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _submit() async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    if (!_isEdit && _customer == null) {
      showAdminSnack(
        context,
        isVi ? 'Hãy chọn khách hàng' : 'Please select a customer',
        error: true,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_isEdit) {
      final cash = num.tryParse(_cash.text.trim()) ?? 0;
      final blocked = num.tryParse(_blocked.text.trim()) ?? 0;
      final asset = num.tryParse(_asset.text.trim()) ?? 0;
      if (asset < cash + blocked) {
        showAdminSnack(
          context,
          isVi
              ? 'Tổng giá trị tài sản không được nhỏ hơn tiền mặt cộng tiền phong tỏa.'
              : 'Total asset value cannot be less than cash plus blocked balance.',
          error: true,
        );
        return;
      }
    }
    setState(() => _saving = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateAccount(widget.account!.accountId, {
          'account_type': _type,
          'cash_balance': _cash.text.trim(),
          'blocked_balance': _blocked.text.trim(),
          'total_asset_value': _asset.text.trim(),
          'margin_limit': _type == 'MARGIN' ? _margin.text.trim() : '0.00',
          'status': _status,
        });
      } else {
        final number = _number.text.trim();
        final cash = _cash.text.trim();
        final margin = _margin.text.trim();
        await repo.createAccount({
          'customer_id': _customer!.customerId,
          'account_type': _type,
          'status': _status,
          if (number.isNotEmpty) 'account_number': number,
          if (cash.isNotEmpty) 'cash_balance': cash,
          if (_type == 'MARGIN' && margin.isNotEmpty) 'margin_limit': margin,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _delete() async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    final a = widget.account!;
    final ok = await showAdminConfirm(
      context,
      title: isVi ? 'Xóa tài khoản' : 'Delete Account',
      message: isVi
          ? 'Xóa vĩnh viễn tài khoản ${a.accountNumber} cùng toàn bộ lệnh '
              'và danh mục liên quan? Hành động này không thể hoàn tác.'
          : 'Permanently delete account ${a.accountNumber} along with all orders '
              'and related portfolios? This action cannot be undone.',
      confirmText: isVi ? 'Xóa vĩnh viễn' : 'Delete Permanently',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).deleteAccount(a.accountId);
      if (!mounted) return;
      showAdminSnack(
        context,
        isVi ? 'Đã xóa tài khoản' : 'Account deleted successfully',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final isVi = l10n.isVietnamese;
    final a = widget.account;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit
              ? (isVi ? 'Sửa tài khoản' : 'Edit Account')
              : (isVi ? 'Mở tài khoản đầu tư' : 'Open Investment Account'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_isEdit)
              AdminCard(
                child: Column(
                  children: [
                    AdminInfoRow(
                      label: isVi ? 'Số tài khoản' : 'Account Number',
                      value: a!.accountNumber,
                    ),
                    AdminInfoRow(
                      label: isVi ? 'Khách hàng' : 'Customer',
                      value: a.customerName,
                    ),
                    AdminInfoRow(label: 'Email', value: a.customerEmail),
                  ],
                ),
              )
            else ...[
              _sectionLabel(isVi ? 'Khách hàng' : 'Customer'),
              AdminCard(
                onTap: _saving ? null : _pickCustomer,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _customer == null
                            ? (isVi ? 'Chọn khách hàng...' : 'Select customer...')
                            : '${_customer!.fullName} · ${_customer!.email}',
                        style: TextStyle(
                          color: _customer == null
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
              const SizedBox(height: 16),
              AppTextField(
                labelText: isVi
                    ? 'Số tài khoản (để trống để tự sinh)'
                    : 'Account number (leave empty to auto-generate)',
                controller: _number,
              ),
            ],
            const SizedBox(height: 20),
            _sectionLabel(isVi ? 'Loại tài khoản' : 'Account Type'),
            _choices(
              AdminConstants.accountTypes,
              _type,
              (v) => setState(() => _type = v),
              isVi,
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? (isVi ? 'Số dư tiền mặt' : 'Cash balance')
                  : (isVi ? 'Số dư tiền mặt ban đầu' : 'Initial cash balance'),
              controller: _cash,
              keyboardType: TextInputType.number,
              validator: (v) => _validateMoney(v, isRequired: _isEdit, isVi: isVi),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 16),
              AppTextField(
                labelText: isVi ? 'Số dư bị phong tỏa' : 'Blocked balance',
                controller: _blocked,
                keyboardType: TextInputType.number,
                validator: (v) => _validateMoney(v, isRequired: true, isVi: isVi),
              ),
              const SizedBox(height: 16),
              AppTextField(
                labelText: isVi ? 'Tổng giá trị tài sản' : 'Total asset value',
                controller: _asset,
                keyboardType: TextInputType.number,
                validator: (v) => _validateMoney(v, isRequired: true, isVi: isVi),
              ),
            ],
            if (_type == 'MARGIN') ...[
              const SizedBox(height: 16),
              AppTextField(
                labelText: isVi ? 'Hạn mức ký quỹ' : 'Margin limit',
                controller: _margin,
                keyboardType: TextInputType.number,
                validator: (v) => _validateMoney(v, isRequired: _isEdit, isVi: isVi),
              ),
            ],
            const SizedBox(height: 20),
            _sectionLabel(isVi ? 'Trạng thái' : 'Status'),
            _choices(
              AdminConstants.accountStatuses,
              _status,
              (v) => setState(() => _status = v),
              isVi,
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _isEdit
                  ? (isVi ? 'Lưu thay đổi' : 'Save Changes')
                  : (isVi ? 'Mở tài khoản' : 'Open Account'),
              isLoading: _saving,
              onPressed: _submit,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.priceDown,
                ),
                label: Text(
                  isVi ? 'Xóa tài khoản' : 'Delete Account',
                  style: const TextStyle(color: AppColors.priceDown),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _choices(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
    bool isVi,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(AdminConstants.label(option, isVi)),
            selected: selected == option,
            showCheckmark: false,
            onSelected: (_) => onSelected(option),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.darkCard,
            side: const BorderSide(color: AppColors.darkBorder),
            labelStyle: TextStyle(
              color: selected == option
                  ? const Color(0xFF052B19)
                  : AppColors.darkTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}