import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_customer_model.dart';
import '../data/models/admin_page.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_customer_detail_screen.dart';
import 'admin_customer_form_screen.dart';

class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() =>
      _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _q = '';
  String? _role;
  String? _status;
  int _page = 1;

  AdminCustomerQuery get _query =>
      AdminCustomerQuery(q: _q, role: _role, status: _status, page: _page);

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

  Future<void> _openDetail(AdminCustomerModel customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AdminCustomerDetailScreen(customerId: customer.customerId),
      ),
    );
    ref.invalidate(adminCustomersProvider);
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AdminCustomerFormScreen(),
      ),
    );
    if (created == true) ref.invalidate(adminCustomersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminCustomersProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Khách hàng'),
        actions: [
          IconButton(
            tooltip: 'Thêm khách hàng',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: _openCreate,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Tìm theo tên, email, số điện thoại',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.darkTextMuted,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          AdminFilterChips(
            options: AdminConstants.customerStatuses,
            selected: _status,
            onChanged: (v) => setState(() {
              _status = v;
              _page = 1;
            }),
          ),
          AdminFilterChips(
            options: AdminConstants.customerRoles,
            selected: _role,
            onChanged: (v) => setState(() {
              _role = v;
              _page = 1;
            }),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminCustomersProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline_rounded,
                    message: 'Không tìm thấy khách hàng nào',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: page.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _customerTile(page.items[i]),
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

  Widget _customerTile(AdminCustomerModel c) {
    return AdminCard(
      onTap: () => _openDetail(c),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              _initial(c.fullName),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  c.phoneNumber,
                  style: const TextStyle(
                    color: AppColors.darkTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AdminStatusBadge(code: c.status),
              if (c.isAdmin) ...[
                const SizedBox(height: 6),
                const AdminStatusBadge(code: 'ADMIN'),
              ],
              const SizedBox(height: 6),
              Text(
                '${c.accountsCount} tài khoản',
                style: const TextStyle(
                  color: AppColors.darkTextMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pager(AdminPage<AdminCustomerModel> page) {
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
            'Trang ${page.page}/${page.totalPages} · ${page.total} khách hàng',
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

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}