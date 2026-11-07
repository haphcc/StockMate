import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_customer_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminCustomerFormScreen extends ConsumerStatefulWidget {
  /// null = tạo mới, khác null = sửa.
  final AdminCustomerModel? customer;

  /// true khi đang sửa chính tài khoản đang đăng nhập (không cho đổi role, trạng thái).
  final bool isSelf;

  const AdminCustomerFormScreen({
    super.key,
    this.customer,
    this.isSelf = false,
  });

  @override
  ConsumerState<AdminCustomerFormScreen> createState() =>
      _AdminCustomerFormScreenState();
}

class _AdminCustomerFormScreenState
    extends ConsumerState<AdminCustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final _password = TextEditingController();
  final _cash = TextEditingController();
  late String _role;
  late String _status;
  bool _saving = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c?.fullName ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _phone = TextEditingController(text: c?.phoneNumber ?? '');
    _role = c?.role ?? 'CUSTOMER';
    _status = c?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _cash.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateCustomer(widget.customer!.customerId, {
          'full_name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone_number': _phone.text.trim(),
          if (!widget.isSelf) 'role': _role,
          if (!widget.isSelf) 'status': _status,
        });
      } else {
        final cash = _cash.text.trim();
        await repo.createCustomer({
          'full_name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone_number': _phone.text.trim(),
          'password': _password.text,
          'role': _role,
          'status': _status,
          if (cash.isNotEmpty) 'initial_cash_balance': cash,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEdit ? 'Sửa khách hàng' : 'Thêm khách hàng'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppTextField(
              labelText: 'Họ và tên',
              controller: _name,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.length < 2) return 'Họ tên tối thiểu 2 ký tự';
                if (value.length > 100) return 'Họ tên tối đa 100 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Số điện thoại',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: (v) {
                final value = (v ?? '').trim();
                if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(value)) {
                  return 'Số điện thoại gồm 9 đến 15 chữ số';
                }
                return null;
              },
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              AppTextField(
                labelText: 'Mật khẩu',
                controller: _password,
                obscureText: true,
                validator: (v) {
                  if ((v ?? '').length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                labelText: 'Số dư tiền mặt ban đầu (tùy chọn)',
                controller: _cash,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return null;
                  if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
                    return 'Nhập số không âm, ví dụ 1000000';
                  }
                  return null;
                },
              ),
            ],
            if (!widget.isSelf) ...[
              const SizedBox(height: 20),
              _sectionLabel('Vai trò'),
              _choices(
                AdminConstants.customerRoles,
                _role,
                (v) => setState(() => _role = v),
              ),
              const SizedBox(height: 16),
              _sectionLabel('Trạng thái'),
              _choices(
                AdminConstants.customerStatuses,
                _status,
                (v) => setState(() => _status = v),
              ),
            ],
            const SizedBox(height: 28),
            GradientButton(
              text: _isEdit ? 'Lưu thay đổi' : 'Tạo khách hàng',
              isLoading: _saving,
              onPressed: _submit,
            ),
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