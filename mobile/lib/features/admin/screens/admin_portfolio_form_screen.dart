import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../providers/app_providers.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_account_model.dart';
import '../data/models/admin_portfolio_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminPortfolioFormScreen extends ConsumerStatefulWidget {
  /// null = thêm dòng mới, khác null = sửa.
  final AdminPortfolioModel? portfolio;

  const AdminPortfolioFormScreen({super.key, this.portfolio});

  @override
  ConsumerState<AdminPortfolioFormScreen> createState() =>
      _AdminPortfolioFormScreenState();
}

class _AdminPortfolioFormScreenState
    extends ConsumerState<AdminPortfolioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbol = TextEditingController();
  late final TextEditingController _quantity;
  late final TextEditingController _available;
  late final TextEditingController _blocked;
  late final TextEditingController _average;
  AdminAccountModel? _account;
  bool _saving = false;

  bool get _isEdit => widget.portfolio != null;

  @override
  void initState() {
    super.initState();
    final p = widget.portfolio;
    _quantity = TextEditingController(text: p?.quantity.toString() ?? '');
    _available =
        TextEditingController(text: p?.availableQuantity.toString() ?? '');
    _blocked = TextEditingController(text: p?.blockedQuantity.toString() ?? '');
    _average = TextEditingController(text: p?.averagePrice ?? '');
  }

  @override
  void dispose() {
    _symbol.dispose();
    _quantity.dispose();
    _available.dispose();
    _blocked.dispose();
    _average.dispose();
    super.dispose();
  }

  String? _validateInt(String? v, {required bool isRequired, required bool isVi}) {
    final value = (v ?? '').trim();
    if (value.isEmpty) {
      return isRequired
          ? (isVi ? 'Không được để trống' : 'Cannot be empty')
          : null;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return isVi
          ? 'Chỉ nhập số nguyên không âm'
          : 'Enter non-negative integer only';
    }
    return null;
  }

  String? _validatePrice(String? v, {required bool isVi}) {
    final value = (v ?? '').trim();
    if (value.isEmpty) {
      return isVi ? 'Không được để trống' : 'Cannot be empty';
    }
    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
      return isVi
          ? 'Nhập số không âm, tối đa 2 chữ số thập phân'
          : 'Enter non-negative number, up to 2 decimal places';
    }
    return null;
  }

  Future<void> _pickAccount() async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    final repo = ref.read(adminRepositoryProvider);
    final picked = await showAdminSearchPicker<AdminAccountModel>(
      context,
      title: isVi ? 'Chọn tài khoản đầu tư' : 'Select Investment Account',
      searchHint: isVi
          ? 'Tìm số tài khoản, tên hoặc email...'
          : 'Search account number, name, or email...',
      loadItems: (q) async =>
          (await repo.listAccounts(q: q.isEmpty ? null : q, pageSize: 50))
              .items,
      itemTitle: (a) =>
          '${a.accountNumber} · ${AdminConstants.label(a.accountType, isVi)}',
      itemSubtitle: (a) => a.customerName,
    );
    if (picked != null && mounted) setState(() => _account = picked);
  }

  Future<void> _submit() async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    if (!_isEdit && _account == null) {
      showAdminSnack(
        context,
        isVi ? 'Hãy chọn tài khoản' : 'Please select an account',
        error: true,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantity.text.trim());
    final available = int.parse(_available.text.trim());
    final blockedText = _blocked.text.trim();
    final blocked = blockedText.isEmpty ? 0 : int.parse(blockedText);
    if (available + blocked > quantity) {
      showAdminSnack(
        context,
        isVi
            ? 'Số khả dụng cộng số phong tỏa không được vượt số lượng.'
            : 'Available quantity plus blocked quantity cannot exceed total quantity.',
        error: true,
      );
      return;
    }

    final p = widget.portfolio;
    Map<String, dynamic>? changes;
    if (p != null) {
      changes = <String, dynamic>{
        if (quantity != p.quantity) 'quantity': quantity,
        if (available != p.availableQuantity) 'available_quantity': available,
        if (blocked != p.blockedQuantity) 'blocked_quantity': blocked,
        if (num.tryParse(_average.text.trim()) != num.tryParse(p.averagePrice))
          'average_price': _average.text.trim(),
      };
      if (changes.isEmpty) {
        showAdminSnack(
          context,
          isVi ? 'Chưa có thay đổi nào.' : 'No changes made.',
        );
        return;
      }
    }

    setState(() => _saving = true);
    final repo = ref.read(adminRepositoryProvider);
    try {
      if (p != null) {
        await repo.updatePortfolio(p.portfolioId, changes!);
      } else {
        await repo.createPortfolio({
          'account_id': _account!.accountId,
          'stock_symbol': _symbol.text.trim().toUpperCase(),
          'quantity': quantity,
          'available_quantity': available,
          'blocked_quantity': blocked,
          'average_price': _average.text.trim(),
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
    final p = widget.portfolio!;
    final ok = await showAdminConfirm(
      context,
      title: isVi ? 'Xóa dòng nắm giữ' : 'Delete Holding',
      message: isVi
          ? 'Xóa vĩnh viễn dòng ${p.stockSymbol} của ${p.customerName}? '
              'Số cổ phiếu này sẽ biến mất khỏi danh mục của tài khoản.'
          : 'Permanently delete holding ${p.stockSymbol} of ${p.customerName}? '
              'This stock will be removed from the account portfolio.',
      confirmText: isVi ? 'Xóa vĩnh viễn' : 'Delete Permanently',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).deletePortfolio(p.portfolioId);
      if (!mounted) return;
      showAdminSnack(
        context,
        isVi ? 'Đã xóa dòng nắm giữ' : 'Holding deleted successfully',
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
    final p = widget.portfolio;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit
              ? (isVi ? 'Sửa ${p!.stockSymbol}' : 'Edit ${p!.stockSymbol}')
              : (isVi ? 'Thêm dòng nắm giữ' : 'Add Holding'),
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
                      label: isVi ? 'Khách hàng' : 'Customer',
                      value: p!.customerName,
                    ),
                    AdminInfoRow(
                      label: isVi ? 'Tài khoản' : 'Account',
                      value: p.accountNumber,
                    ),
                    AdminInfoRow(
                      label: isVi ? 'Cổ phiếu' : 'Stock Symbol',
                      value: '${p.stockSymbol} · ${p.companyName}',
                    ),
                    AdminInfoRow(
                      label: isVi ? 'Giá trị hiện tại' : 'Current Value',
                      value: formatVnd(p.currentValue),
                    ),
                    AdminInfoRow(
                      label: isVi ? 'Lãi/lỗ' : 'Profit/Loss',
                      value: '${formatVnd(p.profitLoss)} '
                          '(${p.profitLossPercent}%)',
                    ),
                  ],
                ),
              )
            else ...[
              _sectionLabel(isVi ? 'Tài khoản' : 'Account'),
              AdminCard(
                onTap: _saving ? null : _pickAccount,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _account == null
                            ? (isVi ? 'Chọn tài khoản...' : 'Select account...')
                            : '${_account!.accountNumber} · '
                                '${_account!.customerName}',
                        style: TextStyle(
                          color: _account == null
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
                labelText: isVi ? 'Mã cổ phiếu' : 'Stock Symbol',
                controller: _symbol,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (!RegExp(r'^[A-Za-z0-9]{3,10}$').hasMatch(value)) {
                    return isVi
                        ? 'Mã gồm 3 đến 10 chữ cái hoặc số'
                        : 'Symbol must be 3 to 10 letters or digits';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Số lượng' : 'Quantity',
              controller: _quantity,
              keyboardType: TextInputType.number,
              validator: (v) => _validateInt(v, isRequired: true, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Số khả dụng' : 'Available Quantity',
              controller: _available,
              keyboardType: TextInputType.number,
              validator: (v) => _validateInt(v, isRequired: true, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? (isVi ? 'Số bị phong tỏa' : 'Blocked quantity')
                  : (isVi
                      ? 'Số bị phong tỏa (để trống = 0)'
                      : 'Blocked quantity (leave empty = 0)'),
              controller: _blocked,
              keyboardType: TextInputType.number,
              validator: (v) => _validateInt(v, isRequired: _isEdit, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Giá vốn trung bình' : 'Average Cost Price',
              controller: _average,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isVi: isVi),
            ),
            const SizedBox(height: 8),
            Text(
              isVi
                  ? 'Khả dụng cộng phong tỏa không được vượt số lượng.'
                  : 'Available quantity plus blocked quantity cannot exceed total quantity.',
              style: const TextStyle(
                color: AppColors.darkTextMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _isEdit
                  ? (isVi ? 'Lưu thay đổi' : 'Save Changes')
                  : (isVi ? 'Thêm dòng nắm giữ' : 'Add Holding'),
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
                  isVi ? 'Xóa dòng nắm giữ' : 'Delete Holding',
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
}