import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../data/admin_repository.dart';
import '../data/mock_admin_repository.dart';
import '../data/models/admin_account_model.dart';
import '../data/models/admin_customer_model.dart';
import '../data/models/admin_page.dart';
import '../data/models/admin_dashboard_model.dart';
import '../data/admin_token_source.dart';
import '../data/api_admin_repository.dart';
import '../data/models/admin_stock_model.dart';
import '../data/models/admin_notification_model.dart';
import '../data/models/admin_order_model.dart';
import '../data/models/admin_transaction_model.dart';
import '../data/models/admin_portfolio_model.dart';
import '../data/models/admin_candle_model.dart';

// Bật bằng cờ lúc chạy, không ghi mật khẩu vào code:
// --dart-define=ADMIN_USE_API=true --dart-define=ADMIN_DEV_EMAIL=... --dart-define=ADMIN_DEV_PASSWORD=...
const _adminUseApi = bool.fromEnvironment('ADMIN_USE_API');
const _devEmail = String.fromEnvironment('ADMIN_DEV_EMAIL');
const _devPassword = String.fromEnvironment('ADMIN_DEV_PASSWORD');

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (_adminUseApi || !AppConfig.useMock) {
    final AdminTokenSource tokenSource = _devEmail.isNotEmpty
        ? DevLoginTokenSource(
            baseUrl: AppConfig.apiBaseUrl,
            email: _devEmail,
            password: _devPassword,
          )
        : StoredTokenSource(baseUrl: AppConfig.apiBaseUrl);
    return ApiAdminRepository(
      baseUrl: AppConfig.apiBaseUrl,
      tokenSource: tokenSource,
    );
  }
  return MockAdminRepository();
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

/// Bộ lọc danh sách cổ phiếu.
class AdminStockQuery extends Equatable {
  final String q;
  final String? exchange;
  final String? status;
  final int page;

  const AdminStockQuery({
    this.q = '',
    this.exchange,
    this.status,
    this.page = 1,
  });

  @override
  List<Object?> get props => [q, exchange, status, page];
}

final adminStocksProvider = FutureProvider.autoDispose
    .family<AdminPage<AdminStockModel>, AdminStockQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).listStocks(
        q: query.q.isEmpty ? null : query.q,
        exchange: query.exchange,
        status: query.status,
        page: query.page,
      );
});

/// Bộ lọc danh sách thông báo.
class AdminNotificationQuery extends Equatable {
  final String? notificationType;
  final int page;

  const AdminNotificationQuery({this.notificationType, this.page = 1});

  @override
  List<Object?> get props => [notificationType, page];
}

final adminNotificationsProvider = FutureProvider.autoDispose
    .family<AdminPage<AdminNotificationModel>, AdminNotificationQuery>(
        (ref, query) {
  return ref.watch(adminRepositoryProvider).listNotifications(
        notificationType: query.notificationType,
        page: query.page,
      );
});

/// Bộ lọc sổ lệnh.
class AdminOrderQuery extends Equatable {
  final String stockSymbol;
  final String? status;
  final String? orderType;
  final int page;

  const AdminOrderQuery({
    this.stockSymbol = '',
    this.status,
    this.orderType,
    this.page = 1,
  });

  @override
  List<Object?> get props => [stockSymbol, status, orderType, page];
}

final adminOrdersProvider = FutureProvider.autoDispose
    .family<AdminPage<AdminOrderModel>, AdminOrderQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).listOrders(
        stockSymbol: query.stockSymbol.isEmpty ? null : query.stockSymbol,
        status: query.status,
        orderType: query.orderType,
        page: query.page,
      );
});

/// Bộ lọc lịch sử giao dịch.
class AdminTransactionQuery extends Equatable {
  final String stockSymbol;
  final String? transactionType;
  final int page;

  const AdminTransactionQuery({
    this.stockSymbol = '',
    this.transactionType,
    this.page = 1,
  });

  @override
  List<Object?> get props => [stockSymbol, transactionType, page];
}

final adminTransactionsProvider = FutureProvider.autoDispose
    .family<AdminPage<AdminTransactionModel>, AdminTransactionQuery>(
        (ref, query) {
  return ref.watch(adminRepositoryProvider).listTransactions(
        stockSymbol: query.stockSymbol.isEmpty ? null : query.stockSymbol,
        transactionType: query.transactionType,
        page: query.page,
      );
});

/// Bộ lọc danh mục nắm giữ.
class AdminPortfolioQuery extends Equatable {
  final String stockSymbol;
  final int page;

  const AdminPortfolioQuery({this.stockSymbol = '', this.page = 1});

  @override
  List<Object?> get props => [stockSymbol, page];
}

final adminPortfoliosProvider = FutureProvider.autoDispose
    .family<AdminPage<AdminPortfolioModel>, AdminPortfolioQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).listPortfolios(
        stockSymbol: query.stockSymbol.isEmpty ? null : query.stockSymbol,
        page: query.page,
      );
});

/// Bộ lọc lịch sử giá: một mã cổ phiếu và số trang.
class AdminCandleQuery extends Equatable {
  final String stockSymbol;
  final int page;

  const AdminCandleQuery({required this.stockSymbol, this.page = 1});

  @override
  List<Object?> get props => [stockSymbol, page];
}

final adminCandlesProvider = FutureProvider.autoDispose
    .family<AdminPage<AdminCandleModel>, AdminCandleQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).listCandles(
        stockSymbol: query.stockSymbol,
        page: query.page,
      );
});