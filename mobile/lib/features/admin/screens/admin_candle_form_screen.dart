import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
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

  String? _validateDate(String? v) {
    final value = (v ?? '').trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return 'Nhập ngày theo dạng năm-tháng-ngày, ví dụ 2026-11-11';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null || _fmt(parsed) != value) return 'Ngày không hợp lệ';
    return null;
  }

  String? _validatePrice(String? v, {required bool isRequired}) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return isRequired ? 'Không được để trống' : null;
    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
      return 'Nhập số không âm, tối đa 2 chữ số thập phân';
    }
    return null;
  }

  String? _validateVolume(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return _isEdit ? 'Không được để trống' : null;
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Chỉ nhập số nguyên không âm';
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

  String? _checkCandle(num open, num close, num high, num low) {
    if (high < low) {
      return 'Giá cao nhất phải lớn hơn hoặc bằng giá thấp nhất.';
    }
    if (open < low || open > high) {
      return 'Giá mở cửa phải nằm trong khoảng từ giá thấp nhất đến cao nhất.';
    }
    if (close < low || close > high) {
      return 'Giá đóng cửa phải nằm trong khoảng từ giá thấp nhất đến cao nhất.';
    }
    return null;
  }

  bool _changed(String text, String original) =>
      num.tryParse(text.trim()) != num.tryParse(original);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final open = num.parse(_open.text.trim());
    final high = num.parse(_high.text.trim());
    final low = num.parse(_low.text.trim());
    final close = num.parse(_close.text.trim());
    final problem = _checkCandle(open, close, high, low);
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
        showAdminSnack(context, 'Chưa có thay đổi nào.');
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
    final c = widget.candle!;
    final ok = await showAdminConfirm(
      context,
      title: 'Xóa phiên giá',
      message: 'Xóa vĩnh viễn phiên ${c.displayDate} của ${c.stockSymbol}? '
          'Hành động này không thể hoàn tác.',
      confirmText: 'Xóa vĩnh viễn',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).deleteCandle(c.candleId);
      if (!mounted) return;
      showAdminSnack(context, 'Đã xóa phiên giá');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candle;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEdit ? 'Sửa phiên giá' : 'Thêm phiên giá'),
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
                    label: 'Cổ phiếu',
                    value:
                        '${widget.stock.stockSymbol} · ${widget.stock.companyName}',
                  ),
                  if (_isEdit)
                    AdminInfoRow(label: 'Ngày', value: c!.displayDate),
                ],
              ),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              AppTextField(
                labelText: 'Ngày giao dịch (năm-tháng-ngày)',
                controller: _date,
                validator: _validateDate,
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
              labelText: 'Giá mở cửa',
              controller: _open,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Giá cao nhất',
              controller: _high,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Giá thấp nhất',
              controller: _low,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: 'Giá đóng cửa',
              controller: _close,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: true),
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? 'Khối lượng giao dịch'
                  : 'Khối lượng giao dịch (để trống = 0)',
              controller: _volume,
              keyboardType: TextInputType.number,
              validator: _validateVolume,
            ),
            const SizedBox(height: 16),
            AppTextField(
              labelText: _isEdit
                  ? 'Giá trị giao dịch'
                  : 'Giá trị giao dịch (để trống = 0)',
              controller: _value,
              keyboardType: TextInputType.number,
              validator: (v) => _validatePrice(v, isRequired: _isEdit),
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _isEdit ? 'Lưu thay đổi' : 'Thêm phiên giá',
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
                  'Xóa phiên giá',
                  style: TextStyle(color: AppColors.priceDown),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}