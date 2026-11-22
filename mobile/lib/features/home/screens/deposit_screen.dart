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
import '../providers/dashboard_provider.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});
  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amount = TextEditingController();
  Timer? _timer;
  DepositModel? _deposit;
  Money? _initialCash;
  String? _error;
  bool _loading = false;
  bool _completed = false;
  @override
  void dispose() {
    _timer?.cancel();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = ref.read(l10nProvider);
    final accountId = ref.read(selectedAccountProvider);
    if (accountId == null) {
      setState(() => _error = l10n.isVietnamese ? 'Chưa có tài khoản CASH hoạt động.' : 'No active CASH account found.');
      return;
    }
    Money value;
    try {
      value = Money.parse(_amount.text);
    } catch (_) {
      setState(() => _error = l10n.isVietnamese ? 'Số tiền không hợp lệ.' : 'Invalid amount.');
      return;
    }
    if (value.cents <= 0) {
      setState(() => _error = l10n.isVietnamese ? 'Số tiền phải lớn hơn 0.' : 'Amount must be greater than 0.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _initialCash =
          (await ref.read(accountRepositoryProvider).getAssets(accountId))
              .cashBalance;
      _deposit = await ref
          .read(accountRepositoryProvider)
          .createDeposit(accountId, value.decimalString);
      _startPolling(accountId, value);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  void _startPolling(int accountId, Money amount) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final a = await ref
            .read(accountRepositoryProvider)
            .getAssets(accountId);
        if (_initialCash != null &&
            a.cashBalance.cents >= _initialCash!.cents + amount.cents) {
          _timer?.cancel();
          if (mounted) setState(() => _completed = true);
          ref.invalidate(assetsProvider);
          ref.invalidate(portfolioProvider);
          ref.invalidate(dashboardProvider);
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final deposit = _deposit;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final cashAccounts = accounts
        .where(
          (account) =>
              account.accountType == 'CASH' && account.status == 'ACTIVE',
        )
        .toList();
    final selectedId = ref.watch(selectedAccountProvider);
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(title: Text(l10n.depositTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (deposit == null) ...[
            DropdownButtonFormField<int>(
              initialValue:
                  cashAccounts.any((account) => account.accountId == selectedId)
                  ? selectedId
                  : null,
              items: cashAccounts
                  .map(
                    (account) => DropdownMenuItem(
                      value: account.accountId,
                      child: Text(account.accountNumber),
                    ),
                  )
                  .toList(),
              onChanged: _loading
                  ? null
                  : (id) =>
                        ref.read(selectedAccountProvider.notifier).select(id),
              decoration: InputDecoration(
                labelText: l10n.isVietnamese ? 'Tài khoản nạp tiền' : 'Deposit Account',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.depositAmountLabel,
                hintText: l10n.depositAmountHint,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading || cashAccounts.isEmpty ? null : _create,
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(l10n.btnGenerateQR),
            ),
          ] else ...[
            Text(
              '${l10n.isVietnamese ? 'Mã đơn' : 'Order ID'}: ${deposit.orderCode}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              '${l10n.isVietnamese ? 'Trạng thái' : 'Status'}: ${_completed ? 'COMPLETED' : deposit.status}',
              style: const TextStyle(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 16),
            Center(
              child: QrImageView(
                data: deposit.qrCode.isNotEmpty
                    ? deposit.qrCode
                    : deposit.checkoutUrl,
                size: 230,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              deposit.checkoutUrl,
              style: const TextStyle(color: AppColors.primary),
            ),
            if (_completed)
              Text(
                l10n.isVietnamese ? 'Số dư đã được cập nhật.' : 'Balance has been updated.',
                style: const TextStyle(color: AppColors.primary),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.priceDown)),
          ],
        ],
      ),
    );
  }
}
