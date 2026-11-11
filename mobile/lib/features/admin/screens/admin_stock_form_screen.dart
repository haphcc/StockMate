import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
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

  String? _validatePrice(String? v, {required bool isRequired}) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return isRequired ? 'Không được để trống' : null;
    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
      return 'Nhập số không âm, tối đa 2 chữ số thập phân';
    }
    return null;
  }

  /// So sánh theo giá trị số (20000 và 20000.00 coi là như nhau).
  bool _changed(String text, String original) {
    return num.tryParse(text.trim()) != num.tryParse(original);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final s = widget.stock;

    final priceChanged = s == null ||
        _exchange != s.exchange ||
        _changed(_current.text, s.currentPrice) ||
        _changed(_reference.text, s.referencePrice) ||
        _changed(_ceiling.text, s.ceilingPrice) ||
        _changed(_floor.text, s.floorPrice);
    if (priceChanged) {
      final ref = num.tryParse(_reference.text.trim());
      final cur = num.tryParse(_current.text.trim());
      var ceil = num.tryParse(_ceiling.text.trim());
      var floor = num.tryParse(_floor.text.trim());
      if (ref != null) {
        final (calcCeil, calcFloor) =
            AdminConstants.computeStockLimits(_exchange, ref);
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
        reference: ref,
        current: cur,
        ceiling: ceil,
        floor: floor,
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
        showAdminSnack(context, 'Chưa có thay đổi nào.');
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
    final s = widget.stock!;
    final ok = await showAdminConfirm(
      context,
      title: 'Xóa mã cổ phiếu',
      message: 'Xóa vĩnh viễn mã ${s.stockSymbol} cùng lịch sử giá và danh '
          'sách theo dõi liên quan? Hành động này không thể hoàn tác.',
      confirmText: 'Xóa vĩnh viễn',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).deleteStock(s.stockId);
      if (!mounted) return;
      showAdminSnack(context, 'Đã xóa mã ${s.stockSymbol}');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stock;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEdit ? 'Sửa ${s!.stockSymbol}' : 'Thêm mã cổ phiếu'),
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
                    AdminInfoRow(label: 'Mã', value: s!.stockSymbol),
                    AdminInfoRow(
                      label: 'Khối lượng GD',
                      value: formatNumber(s.totalVolume.toString()),
                    ),
                  ],
                ),
              )
            else
              AppTextField(
                labelText: 'Mã cổ phiếu (3 đến 10 ký tự)',
                controller: _symbol,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (!RegExp(r'^[A-Za-z0-9]{3,10}$').hasMatch(value)) {
                    return 'Mã gồm 3 đến 10 chữ cái hoặc số';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Tên công ty',
              controller: _name,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.length < 2) return 'Tên tối thiểu 2 ký tự';
                if (value.length > 200) return 'Tên tối đa 200 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _sectionLabel('Sàn giao dịch'),
            _choices(
              AdminConstants.exchanges,
              _exchange,
              (v) => setState(() => _exchange = v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Ngành (tùy chọn)',
              controller: _industry,
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? 'Số cổ phiếu niêm yết'
                  : 'Số cổ phiếu niêm yết (để trống = 0)',
              controller: _shares,
              keyboardType: TextInputType.number,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return _isEdit ? 'Không được để trống' : null;
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Chỉ nhập số nguyên không âm';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Giá hiện tại',
              controller: _current,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Giá tham chiếu',
              controller: _reference,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText:
                  _isEdit ? 'Giá trần' : 'Giá trần (để trống = tự tính theo biên độ)',
              controller: _ceiling,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: _isEdit),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText:
                  _isEdit ? 'Giá sàn' : 'Giá sàn (để trống = tự tính theo biên độ)',
              controller: _floor,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: _isEdit),
            ),
            if (_isEdit)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Nếu chỉ đổi giá tham chiếu và không sửa trần, sàn, hệ thống '
                  'sẽ tự tính lại trần và sàn theo biên độ của sàn.',
                  style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            _sectionLabel('Trạng thái'),
            _choices(
              AdminConstants.stockStatuses,
              _status,
              (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _isEdit ? 'Lưu thay đổi' : 'Thêm mã cổ phiếu',
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
                  'Xóa mã cổ phiếu',
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