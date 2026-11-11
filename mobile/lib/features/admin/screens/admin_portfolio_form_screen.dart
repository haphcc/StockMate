import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
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

  String? _validateInt(String? v, {required bool isRequired}) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return isRequired ? 'Không được để trống' : null;
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Chỉ nhập số nguyên không âm';
    return null;
  }

  String? _validatePrice(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Không được để trống';
    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
      return 'Nhập số không âm, tối đa 2 chữ số thập phân';
    }
    return null;
  }

  Future<void> _pickAccount() async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final page = await repo.listAccounts(pageSize: 100);
      if (!mounted) return;
      final picked = await showModalBottomSheet<AdminAccountModel>(
        context: context,
        backgroundColor: AppColors.darkSurface,
        builder: (sheetContext) => ListView(
          children: [
            for (final a in page.items)
              ListTile(
                title: Text(
                  '${a.accountNumber} · ${AdminConstants.label(a.accountType)}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  a.customerName,
                  style: const TextStyle(color: AppColors.darkTextSecondary),
                ),
                onTap: () => Navigator.pop(sheetContext, a),
              ),
          ],
        ),
      );
      if (picked != null && mounted) setState(() => _account = picked);
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _submit() async {
    if (!_isEdit && _account == null) {
      showAdminSnack(context, 'Hãy chọn tài khoản', error: true);
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
        'Số khả dụng cộng số phong tỏa không được vượt số lượng.',
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
        showAdminSnack(context, 'Chưa có thay đổi nào.');
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
    final p = widget.portfolio!;
    final ok = await showAdminConfirm(
      context,
      title: 'Xóa dòng nắm giữ',
      message: 'Xóa vĩnh viễn dòng ${p.stockSymbol} của ${p.customerName}? '
          'Số cổ phiếu này sẽ biến mất khỏi danh mục của tài khoản.',
      confirmText: 'Xóa vĩnh viễn',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).deletePortfolio(p.portfolioId);
      if (!mounted) return;
      showAdminSnack(context, 'Đã xóa dòng nắm giữ');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.portfolio;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEdit ? 'Sửa ${p!.stockSymbol}' : 'Thêm dòng nắm giữ'),
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
                    AdminInfoRow(label: 'Khách hàng', value: p!.customerName),
                    AdminInfoRow(label: 'Tài khoản', value: p.accountNumber),
                    AdminInfoRow(
                      label: 'Cổ phiếu',
                      value: '${p.stockSymbol} · ${p.companyName}',
                    ),
                    AdminInfoRow(
                      label: 'Giá trị hiện tại',
                      value: formatVnd(p.currentValue),
                    ),
                    AdminInfoRow(
                      label: 'Lãi/lỗ',
                      value: '${formatVnd(p.profitLoss)} '
                          '(${p.profitLossPercent}%)',
                    ),
                  ],
                ),
              )
            else ...[
              _sectionLabel('Tài khoản'),
              AdminCard(
                onTap: _saving ? null : _pickAccount,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _account == null
                            ? 'Chọn tài khoản...'
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
                labelText: 'Mã cổ phiếu',
                controller: _symbol,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (!RegExp(r'^[A-Za-z0-9]{3,10}$').hasMatch(value)) {
                    return 'Mã gồm 3 đến 10 chữ cái hoặc số';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Số lượng',
              controller: _quantity,
              keyboardType: TextInputType.number,
              validator: (v) => _validateInt(v, isRequired: true),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Số khả dụng',
              controller: _available,
              keyboardType: TextInputType.number,
              validator: (v) => _validateInt(v, isRequired: true),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? 'Số bị phong tỏa'
                  : 'Số bị phong tỏa (để trống = 0)',
              controller: _blocked,
              keyboardType: TextInputType.number,
              validator: (v) => _validateInt(v, isRequired: _isEdit),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Giá vốn trung bình',
              controller: _average,
              keyboardType: TextInputType.number,
              validator: _validatePrice,
            ),
            const SizedBox(height: 8),
            const Text(
              'Khả dụng cộng phong tỏa không được vượt số lượng.',
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _isEdit ? 'Lưu thay đổi' : 'Thêm dòng nắm giữ',
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
                  'Xóa dòng nắm giữ',
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
}