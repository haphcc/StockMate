import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
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

  String? _validateMoney(String? v, {required bool isRequired}) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return isRequired ? 'Không được để trống' : null;
    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
      return 'Nhập số không âm, tối đa 2 chữ số thập phân';
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
    if (!_isEdit && _customer == null) {
      showAdminSnack(context, 'Hãy chọn khách hàng', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
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
    final a = widget.account!;
    final ok = await showAdminConfirm(
      context,
      title: 'Xóa tài khoản',
      message: 'Xóa vĩnh viễn tài khoản ${a.accountNumber} cùng toàn bộ lệnh '
          'và danh mục liên quan? Hành động này không thể hoàn tác.',
      confirmText: 'Xóa vĩnh viễn',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).deleteAccount(a.accountId);
      if (!mounted) return;
      showAdminSnack(context, 'Đã xóa tài khoản');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEdit ? 'Sửa tài khoản' : 'Mở tài khoản đầu tư'),
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
                    AdminInfoRow(label: 'Số tài khoản', value: a!.accountNumber),
                    AdminInfoRow(label: 'Khách hàng', value: a.customerName),
                    AdminInfoRow(label: 'Email', value: a.customerEmail),
                  ],
                ),
              )
            else ...[
              _sectionLabel('Khách hàng'),
              AdminCard(
                onTap: _saving ? null : _pickCustomer,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _customer == null
                            ? 'Chọn khách hàng...'
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
                labelText: 'Số tài khoản (để trống để tự sinh)',
                controller: _number,
              ),
            ],
            const SizedBox(height: 20),
            _sectionLabel('Loại tài khoản'),
            _choices(
              AdminConstants.accountTypes,
              _type,
              (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit ? 'Số dư tiền mặt' : 'Số dư tiền mặt ban đầu',
              controller: _cash,
              keyboardType: TextInputType.number,
              validator: (v) => _validateMoney(v, isRequired: _isEdit),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 16),
              AppTextField(
                labelText: 'Số dư bị phong tỏa',
                controller: _blocked,
                keyboardType: TextInputType.number,
                validator: (v) => _validateMoney(v, isRequired: true),
              ),
              const SizedBox(height: 16),
              AppTextField(
                labelText: 'Tổng giá trị tài sản',
                controller: _asset,
                keyboardType: TextInputType.number,
                validator: (v) => _validateMoney(v, isRequired: true),
              ),
            ],
            if (_type == 'MARGIN') ...[
              const SizedBox(height: 16),
              AppTextField(
                labelText: 'Hạn mức ký quỹ',
                controller: _margin,
                keyboardType: TextInputType.number,
                validator: (v) => _validateMoney(v, isRequired: _isEdit),
              ),
            ],
            const SizedBox(height: 20),
            _sectionLabel('Trạng thái'),
            _choices(
              AdminConstants.accountStatuses,
              _status,
              (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _isEdit ? 'Lưu thay đổi' : 'Mở tài khoản',
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
                label: const Text(
                  'Xóa tài khoản',
                  style: TextStyle(color: AppColors.priceDown),
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
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(AdminConstants.label(option)),
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