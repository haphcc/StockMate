import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_account_model.dart';
import '../data/models/admin_page.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_account_form_screen.dart';

class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  ConsumerState<AdminAccountsScreen> createState() =>
      _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends ConsumerState<AdminAccountsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _q = '';
  String? _status;
  String? _type;
  int _page = 1;

  AdminAccountQuery get _query => AdminAccountQuery(
        q: _q,
        accountType: _type,
        status: _status,
        page: _page,
      );

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _q = value.trim();
        _page = 1;
      });
    });
  }

  Future<void> _openForm({AdminAccountModel? account}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminAccountFormScreen(account: account),
      ),
    );
    if (changed == true) ref.invalidate(adminAccountsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminAccountsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tài khoản đầu tư'),
        actions: [
          IconButton(
            tooltip: 'Mở tài khoản mới',
            icon: const Icon(Icons.add_card_rounded),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Tìm theo số tài khoản hoặc tên khách hàng',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.darkTextMuted,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          AdminFilterChips(
            options: AdminConstants.accountStatuses,
            selected: _status,
            onChanged: (v) => setState(() {
              _status = v;
              _page = 1;
            }),
          ),
          AdminFilterChips(
            options: AdminConstants.accountTypes,
            selected: _type,
            onChanged: (v) => setState(() {
              _type = v;
              _page = 1;
            }),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminAccountsProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    message: 'Không tìm thấy tài khoản nào',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: page.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _accountTile(page.items[i]),
                      ),
                    ),
                    _pager(page),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountTile(AdminAccountModel a) {
    return AdminCard(
      onTap: () => _openForm(account: a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.accountNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                AdminConstants.label(a.accountType),
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              AdminStatusBadge(code: a.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            a.customerName,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tiền mặt: ${formatVnd(a.cashBalance)}',
                  style: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                formatVnd(a.totalAssetValue),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pager(AdminPage<AdminAccountModel> page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: page.page > 1
                ? () => setState(() => _page = page.page - 1)
                : null,
            child: const Text('Trước'),
          ),
          Text(
            'Trang ${page.page}/${page.totalPages} · ${page.total} tài khoản',
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: page.page < page.totalPages
                ? () => setState(() => _page = page.page + 1)
                : null,
            child: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}