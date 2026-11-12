import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/deposit_model.dart';
import '../../../providers/account_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/selected_account_provider.dart';

class DepositScreen extends ConsumerStatefulWidget { const DepositScreen({super.key}); @override ConsumerState<DepositScreen> createState() => _DepositScreenState(); }
class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amount = TextEditingController(); Timer? _timer; DepositModel? _deposit; Money? _initialCash; String? _error; bool _loading = false; bool _completed = false;
  @override void dispose() { _timer?.cancel(); _amount.dispose(); super.dispose(); }
  Future<void> _create() async {
    final accountId = ref.read(selectedAccountProvider); if (accountId == null) { setState(() => _error = 'Chưa có tài khoản CASH hoạt động.'); return; }
    Money value; try { value = Money.parse(_amount.text); } catch (_) { setState(() => _error = 'Số tiền không hợp lệ.'); return; }
    if (value.cents <= 0) { setState(() => _error = 'Số tiền phải lớn hơn 0.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      _initialCash = (await ref.read(accountRepositoryProvider).getAssets(accountId)).cashBalance;
      _deposit = await ref.read(accountRepositoryProvider).createDeposit(accountId, value.decimalString);
      _startPolling(accountId, value);
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    if (mounted) setState(() => _loading = false);
  }
  void _startPolling(int accountId, Money amount) { _timer?.cancel(); _timer = Timer.periodic(const Duration(seconds: 5), (_) async { try { final a = await ref.read(accountRepositoryProvider).getAssets(accountId); if (_initialCash != null && a.cashBalance.cents >= _initialCash!.cents + amount.cents) { _timer?.cancel(); if (mounted) setState(() => _completed = true); ref.invalidate(assetsProvider); ref.invalidate(portfolioProvider); } } catch (_) {} }); }
  @override Widget build(BuildContext context) { final d = _deposit; return Scaffold(backgroundColor: AppColors.darkBackground, appBar: AppBar(title: const Text('Nạp tiền')), body: ListView(padding: const EdgeInsets.all(20), children: [if (d == null) ...[TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Số tiền (VND)', hintText: '1000000')), const SizedBox(height: 16), ElevatedButton(onPressed: _loading ? null : _create, child: _loading ? const CircularProgressIndicator() : const Text('Tạo yêu cầu nạp tiền'))] else ...[Text('Mã đơn: ${d.orderCode}', style: const TextStyle(color: Colors.white)), Text('Trạng thái: ${_completed ? 'COMPLETED' : d.status}', style: const TextStyle(color: AppColors.darkTextSecondary)), const SizedBox(height: 16), Center(child: QrImageView(data: d.qrCode.isNotEmpty ? d.qrCode : d.checkoutUrl, size: 230, backgroundColor: Colors.white)), const SizedBox(height: 12), SelectableText(d.checkoutUrl, style: const TextStyle(color: AppColors.primary)), if (_completed) const Text('Số dư đã được cập nhật.', style: TextStyle(color: AppColors.primary))], if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: AppColors.priceDown))]])); }
}
