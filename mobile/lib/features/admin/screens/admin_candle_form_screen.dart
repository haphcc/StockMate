import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../providers/app_providers.dart';
import '../data/models/admin_candle_model.dart';
import '../data/models/admin_stock_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminCandleFormScreen extends ConsumerStatefulWidget {
  final AdminStockModel stock;

  /// null = thêm phiên mới, khác null = sửa.
  final AdminCandleModel? candle;

  const AdminCandleFormScreen({super.key, required this.stock, this.candle});

  @override
  ConsumerState<AdminCandleFormScreen> createState() =>
      _AdminCandleFormScreenState();
}

class _AdminCandleFormScreenState extends ConsumerState<AdminCandleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _date = TextEditingController();
  late final TextEditingController _open;
  late final TextEditingController _high;
  late final TextEditingController _low;
  late final TextEditingController _close;
  late final TextEditingController _volume;
  late final TextEditingController _value;
  bool _saving = false;

  bool get _isEdit => widget.candle != null;

  @override
  void initState() {
    super.initState();
    final c = widget.candle;
    _open = TextEditingController(text: c?.openPrice ?? '');
    _high = TextEditingController(text: c?.highestPrice ?? '');
    _low = TextEditingController(text: c?.lowestPrice ?? '');
    _close = TextEditingController(text: c?.closePrice ?? '');
    _volume = TextEditingController(text: c?.tradingVolume.toString() ?? '');
    _value = TextEditingController(text: c?.tradingValue ?? '');
  }

  @override
  void dispose() {
    _date.dispose();
    _open.dispose();
    _high.dispose();
    _low.dispose();
    _close.dispose();
    _volume.dispose();
    _value.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String? _validateDate(String? v, {required bool isVi}) {
    final value = (v ?? '').trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return isVi
          ? 'Nhập ngày theo dạng năm-tháng-ngày, ví dụ 2026-11-11'
          : 'Enter date as YYYY-MM-DD, e.g. 2026-11-11';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || _fmt(parsed) != value) {
      return isVi ? 'Ngày không hợp lệ' : 'Invalid date';
    }
    return null;
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

  String? _validateVolume(String? v, {required bool isVi}) {
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
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) _date.text = _fmt(picked);
  }

  String? _checkCandle(num open, num close, num high, num low, {required bool isVi}) {
    if (high < low) {
      return isVi
          ? 'Giá cao nhất phải lớn hơn hoặc bằng giá thấp nhất.'
          : 'Highest price must be greater than or equal to lowest price.';
    }
    if (open < low || open > high) {
      return isVi
          ? 'Giá mở cửa phải nằm trong khoảng từ giá thấp nhất đến cao nhất.'
          : 'Open price must be between lowest and highest price.';
    }
    if (close < low || close > high) {
      return isVi
          ? 'Giá đóng cửa phải nằm trong khoảng từ giá thấp nhất đến cao nhất.'
          : 'Close price must be between lowest and highest price.';
    }
    return null;
  }

  bool _changed(String text, String original) =>
      num.tryParse(text.trim()) != num.tryParse(original);

  Future<void> _submit() async {
    final isVi = ref.read(l10nProvider).isVietnamese;
    if (!_formKey.currentState!.validate()) return;
    final open = num.parse(_open.text.trim());
    final high = num.parse(_high.text.trim());
    final low = num.parse(_low.text.trim());
    final close = num.parse(_close.text.trim());
    final problem = _checkCandle(open, close, high, low, isVi: isVi);
    if (problem != null) {
      showAdminSnack(context, problem, error: true);
      return;
    }

    final c = widget.candle;
    Map<String, dynamic>? changes;
    if (c != null) {
      final volumeText = _volume.text.trim();
      changes = <String, dynamic>{
        if (_changed(_open.text, c.openPrice)) 'open_price': _open.text.trim(),
        if (_changed(_high.text, c.highestPrice))
          'highest_price': _high.text.trim(),
        if (_changed(_low.text, c.lowestPrice)) 'lowest_price': _low.text.trim(),
        if (_changed(_close.text, c.closePrice))
          'close_price': _close.text.trim(),
        if (int.parse(volumeText) != c.tradingVolume)
          'trading_volume': int.parse(volumeText),
        if (_changed(_value.text, c.tradingValue))
          'trading_value': _value.text.trim(),
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
      if (c != null) {
        await repo.updateCandle(c.candleId, changes!);
      } else {
        final volume = _volume.text.trim();
        final value = _value.text.trim();
        await repo.createCandle({
          'stock_symbol': widget.stock.stockSymbol,
          'recorded_date': _date.text.trim(),
          'open_price': _open.text.trim(),
          'close_price': _close.text.trim(),
          'highest_price': _high.text.trim(),
          'lowest_price': _low.text.trim(),
          'trading_volume': volume.isEmpty ? 0 : int.parse(volume),
          if (value.isNotEmpty) 'trading_value': value,
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
    final c = widget.candle!;
    final ok = await showAdminConfirm(
      context,
      title: isVi ? 'Xóa phiên giá' : 'Delete Price Session',
      message: isVi
          ? 'Xóa vĩnh viễn phiên ${c.displayDate} của ${c.stockSymbol}? '
              'Hành động này không thể hoàn tác.'
          : 'Permanently delete session ${c.displayDate} of ${c.stockSymbol}? '
              'This action cannot be undone.',
      confirmText: isVi ? 'Xóa vĩnh viễn' : 'Delete Permanently',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).deleteCandle(c.candleId);
      if (!mounted) return;
      showAdminSnack(
        context,
        isVi ? 'Đã xóa phiên giá' : 'Price session deleted successfully',
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
    final c = widget.candle;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit
              ? (isVi ? 'Sửa phiên giá' : 'Edit Price Session')
              : (isVi ? 'Thêm phiên giá' : 'Add Price Session'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdminCard(
              child: Column(
                children: [
                  AdminInfoRow(
                    label: isVi ? 'Cổ phiếu' : 'Stock Symbol',
                    value:
                        '${widget.stock.stockSymbol} · ${widget.stock.companyName}',
                  ),
                  if (_isEdit)
                    AdminInfoRow(
                      label: isVi ? 'Ngày' : 'Date',
                      value: c!.displayDate,
                    ),
                ],
              ),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              AppTextField(
                labelText: isVi
                    ? 'Ngày giao dịch (năm-tháng-ngày)'
                    : 'Trading Date (YYYY-MM-DD)',
                controller: _date,
                validator: (v) => _validateDate(v, isVi: isVi),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.darkTextMuted,
                  ),
                  onPressed: _pickDate,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Giá mở cửa' : 'Open Price',
              controller: _open,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Giá cao nhất' : 'Highest Price',
              controller: _high,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Giá thấp nhất' : 'Lowest Price',
              controller: _low,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: isVi ? 'Giá đóng cửa' : 'Close Price',
              controller: _close,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? (isVi ? 'Khối lượng giao dịch' : 'Trading volume')
                  : (isVi
                      ? 'Khối lượng giao dịch (để trống = 0)'
                      : 'Trading volume (leave empty = 0)'),
              controller: _volume,
              keyboardType: TextInputType.number,
              validator: (v) => _validateVolume(v, isVi: isVi),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? (isVi ? 'Giá trị giao dịch' : 'Trading value')
                  : (isVi
                      ? 'Giá trị giao dịch (để trống = 0)'
                      : 'Trading value (leave empty = 0)'),
              controller: _value,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  _validatePrice(v, isRequired: _isEdit, isVi: isVi),
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _isEdit
                  ? (isVi ? 'Lưu thay đổi' : 'Save Changes')
                  : (isVi ? 'Thêm phiên giá' : 'Add Price Session'),
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
                  isVi ? 'Xóa phiên giá' : 'Delete Price Session',
                  style: const TextStyle(color: AppColors.priceDown),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}