import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../providers/app_providers.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_stock_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminStockFormScreen extends ConsumerStatefulWidget {
  /// null = thêm mã mới, khác null = sửa.
  final AdminStockModel? stock;

  const AdminStockFormScreen({super.key, this.stock});

  @override
  ConsumerState<AdminStockFormScreen> createState() =>
      _AdminStockFormScreenState();
}

class _AdminStockFormScreenState extends ConsumerState<AdminStockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbol = TextEditingController();
  late final TextEditingController _name;
  late final TextEditingController _industry;
  late final TextEditingController _shares;
  late final TextEditingController _current;
  late final TextEditingController _reference;
  late final TextEditingController _ceiling;
  late final TextEditingController _floor;
  late String _exchange;
  late String _status;
  bool _saving = false;

  bool get _isEdit => widget.stock != null;

  @override
  void initState() {
    super.initState();
    final s = widget.stock;
    _name = TextEditingController(text: s?.companyName ?? '');
    _industry = TextEditingController(text: s?.industry ?? '');
    _shares = TextEditingController(text: s?.listedShares.toString() ?? '');
    _current = TextEditingController(text: s?.currentPrice ?? '');
    _reference = TextEditingController(text: s?.referencePrice ?? '');
    _ceiling = TextEditingController(text: s?.ceilingPrice ?? '');
    _floor = TextEditingController(text: s?.floorPrice ?? '');
    _exchange = s?.exchange ?? 'HOSE';
    _status = s?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _symbol.dispose();
    _name.dispose();
    _industry.dispose();
    _shares.dispose();
    _current.dispose();
    _reference.dispose();
    _ceiling.dispose();
    _floor.dispose();
    super.dispose();
  }

  String? _validatePrice(String? v, {required bool isRequired, required bool isVi}) {
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

  /// So sánh theo giá trị số (20000 và 20000.00 coi là như nhau).
  bool _changed(String text, String original) {
    return num.tryParse(text.trim()) != num.tryParse(original);
  }

  Future<void> _submit() async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    if (!_formKey.currentState!.validate()) return;
    final s = widget.stock;

    final priceChanged = s == null ||
        _exchange != s.exchange ||
        _changed(_current.text, s.currentPrice) ||
        _changed(_reference.text, s.referencePrice) ||
        _changed(_ceiling.text, s.ceilingPrice) ||
        _changed(_floor.text, s.floorPrice);
    if (priceChanged) {
      final refPrice = num.tryParse(_reference.text.trim());
      final cur = num.tryParse(_current.text.trim());
      var ceil = num.tryParse(_ceiling.text.trim());
      var floor = num.tryParse(_floor.text.trim());
      if (refPrice != null) {
        final (calcCeil, calcFloor) =
            AdminConstants.computeStockLimits(_exchange, refPrice);
        final refOrExChanged = s != null &&
            (_changed(_reference.text, s.referencePrice) ||
                _exchange != s.exchange);
        if (s == null) {
          ceil ??= calcCeil;
          floor ??= calcFloor;
        } else if (refOrExChanged &&
            !_changed(_ceiling.text, s.ceilingPrice) &&
            !_changed(_floor.text, s.floorPrice)) {
          // Đổi giá tham chiếu hoặc sàn mà không sửa trần/sàn: kiểm tra theo biên độ mới.
          ceil = calcCeil;
          floor = calcFloor;
        }
      }
      final problem = AdminConstants.validateStockPrices(
        reference: refPrice,
        current: cur,
        ceiling: ceil,
        floor: floor,
        isVietnamese: isVi,
      );
      if (problem != null) {
        showAdminSnack(context, problem, error: true);
        return;
      }
    }

    final repo = ref.read(adminRepositoryProvider);
    Map<String, dynamic>? changes;
    if (s != null) {
      changes = <String, dynamic>{
        if (_name.text.trim() != s.companyName)
          'company_name': _name.text.trim(),
        if (_exchange != s.exchange) 'exchange': _exchange,
        if (_industry.text.trim() != (s.industry ?? ''))
          'industry': _industry.text.trim(),
        if (_changed(_shares.text, s.listedShares.toString()))
          'listed_shares': int.parse(_shares.text.trim()),
        if (_changed(_current.text, s.currentPrice))
          'current_price': _current.text.trim(),
        if (_changed(_reference.text, s.referencePrice))
          'reference_price': _reference.text.trim(),
        if (_changed(_ceiling.text, s.ceilingPrice))
          'ceiling_price': _ceiling.text.trim(),
        if (_changed(_floor.text, s.floorPrice))
          'floor_price': _floor.text.trim(),
        if (_status != s.status) 'status': _status,
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
    try {
      if (s != null) {
        await repo.updateStock(s.stockId, changes!);
      } else {
        final industry = _industry.text.trim();
        final shares = _shares.text.trim();
        final ceiling = _ceiling.text.trim();
        final floor = _floor.text.trim();
        await repo.createStock({
          'stock_symbol': _symbol.text.trim().toUpperCase(),
          'company_name': _name.text.trim(),
          'exchange': _exchange,
          if (industry.isNotEmpty) 'industry': industry,
          'listed_shares': shares.isEmpty ? 0 : int.parse(shares),
          'current_price': _current.text.trim(),
          'reference_price': _reference.text.trim(),
          if (ceiling.isNotEmpty) 'ceiling_price': ceiling,
          if (floor.isNotEmpty) 'floor_price': floor,
          'status': _status,
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
    final s = widget.stock!;
    final ok = await showAdminConfirm(
      context,
      title: isVi ? 'Xóa mã cổ phiếu' : 'Delete Stock Symbol',
      message: isVi
          ? 'Xóa vĩnh viễn mã ${s.stockSymbol} cùng lịch sử giá và danh '
              'sách theo dõi liên quan? Hành động này không thể hoàn tác.'
          : 'Permanently delete symbol ${s.stockSymbol} along with its price '
              'history and related watchlists? This action cannot be undone.',
      confirmText: isVi ? 'Xóa vĩnh viễn' : 'Delete Permanently',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).deleteStock(s.stockId);
      if (!mounted) return;
      showAdminSnack(
        context,
        isVi ? 'Đã xóa mã ${s.stockSymbol}' : 'Deleted symbol ${s.stockSymbol}',
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
    final s = widget.stock;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit
              ? (isVi ? 'Sửa ${s!.stockSymbol}' : 'Edit ${s!.stockSymbol}')
              : (isVi ? 'Thêm mã cổ phiếu' : 'Add Stock Symbol'),
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
                      label: isVi ? 'Mã' : 'Symbol',
                      value: s!.stockSymbol,
                    ),
                    AdminInfoRow(
                      label: isVi ? 'Khối lượng GD' : 'Trading Volume',
                      value: formatNumber(s.totalVolume.toString()),
                    ),
                  ],
                ),
              )
            else
              AppTextField(
                labelText: isVi
                    ? 'Mã cổ phiếu (3 đến 10 ký tự)'
                    : 'Stock symbol (3 to 10 characters)',
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
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Tên công ty' : 'Company Name',
              controller: _name,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.length < 2) {
                  return isVi
                      ? 'Tên tối thiểu 2 ký tự'
                      : 'Name must be at least 2 characters';
                }
                if (value.length > 200) {
                  return isVi
                      ? 'Tên tối đa 200 ký tự'
                      : 'Name maximum 200 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _sectionLabel(isVi ? 'Sàn giao dịch' : 'Exchange'),
            _choices(
              AdminConstants.exchanges,
              _exchange,
              (v) => setState(() => _exchange = v),
              isVi,
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Ngành (tùy chọn)' : 'Industry (optional)',
              controller: _industry,
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? (isVi ? 'Số cổ phiếu niêm yết' : 'Listed shares')
                  : (isVi
                      ? 'Số cổ phiếu niêm yết (để trống = 0)'
                      : 'Listed shares (leave empty = 0)'),
              controller: _shares,
              keyboardType: TextInputType.number,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) {
                  return _isEdit
                      ? (isVi ? 'Không được để trống' : 'Cannot be empty')
                      : null;
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return isVi
                      ? 'Chỉ nhập số nguyên không âm'
                      : 'Enter non-negative integer only';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Giá hiện tại' : 'Current Price',
              controller: _current,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Giá tham chiếu' : 'Reference Price',
              controller: _reference,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? (isVi ? 'Giá trần' : 'Ceiling Price')
                  : (isVi
                      ? 'Giá trần (để trống = tự tính theo biên độ)'
                      : 'Ceiling price (leave empty = auto)'),
              controller: _ceiling,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _validatePrice(v, isRequired: _isEdit, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? (isVi ? 'Giá sàn' : 'Floor Price')
                  : (isVi
                      ? 'Giá sàn (để trống = tự tính theo biên độ)'
                      : 'Floor price (leave empty = auto)'),
              controller: _floor,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _validatePrice(v, isRequired: _isEdit, isVi: isVi),
            ),
            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  isVi
                      ? 'Nếu chỉ đổi giá tham chiếu và không sửa trần, sàn, hệ thống '
                          'sẽ tự tính lại trần và sàn theo biên độ của sàn.'
                      : 'If only reference price is changed, ceiling and floor will be '
                          'recalculated based on exchange limits.',
                  style: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _sectionLabel(isVi ? 'Trạng thái' : 'Status'),
            _choices(
              AdminConstants.stockStatuses,
              _status,
              (v) => setState(() => _status = v),
              isVi,
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _isEdit
                  ? (isVi ? 'Lưu thay đổi' : 'Save Changes')
                  : (isVi ? 'Thêm mã cổ phiếu' : 'Add Stock Symbol'),
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
                  isVi ? 'Xóa mã cổ phiếu' : 'Delete Stock Symbol',
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