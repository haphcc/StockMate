import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../data/admin_repository.dart';
import '../data/mock_admin_repository.dart';
import '../data/models/admin_account_model.dart';
import '../data/models/admin_customer_model.dart';
import '../data/models/admin_page.dart';
import '../data/models/admin_dashboard_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (AppConfig.useMock) {
    return MockAdminRepository();
  }
  // TODO(Bước 7): trả về ApiAdminRepository khi nối API thật.
  throw UnimplementedError('API admin repository chưa được triển khai');
});

/// Bộ lọc danh sách khách hàng (tìm kiếm, lọc, trang).
class AdminCustomerQuery extends Equatable {
  final String q;
  final String? role;
  final String? status;
  final int page;

  const AdminCustomerQuery({
    this.q = '',
    this.role,
    this.status,
    this.page = 1,
  });

  @override
  List<Object?> get props => [q, role, status, page];
}

/// Bộ lọc danh sách tài khoản đầu tư.
class AdminAccountQuery extends Equatable {
  final String q;
  final int? customerId;
  final String? accountType;
  final String? status;
  final int page;

  const AdminAccountQuery({
    this.q = '',
    this.customerId,
    this.accountType,
    this.status,
    this.page = 1,
  });

  @override
  List<Object?> get props => [q, customerId, accountType, status, page];
}

final adminCustomersProvider = FutureProvider.autoDispose
    .family<AdminPage<AdminCustomerModel>, AdminCustomerQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).listCustomers(
        q: query.q.isEmpty ? null : query.q,
        role: query.role,
        status: query.status,
        page: query.page,
      );
});

final adminCustomerDetailProvider =
    FutureProvider.autoDispose.family<AdminCustomerModel, int>((ref, id) {
  return ref.watch(adminRepositoryProvider).getCustomer(id);
});

final adminAccountsProvider = FutureProvider.autoDispose
    .family<AdminPage<AdminAccountModel>, AdminAccountQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).listAccounts(
        q: query.q.isEmpty ? null : query.q,
        customerId: query.customerId,
        accountType: query.accountType,
        status: query.status,
        page: query.page,
      );
});

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardModel>((ref) {
  return ref.watch(adminRepositoryProvider).getDashboard();
});