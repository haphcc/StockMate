import 'models/admin_account_model.dart';
import 'models/admin_customer_model.dart';
import 'models/admin_page.dart';
import 'models/admin_dashboard_model.dart';
import 'models/admin_stock_model.dart';
import 'models/admin_notification_model.dart';
import 'models/admin_order_model.dart';
import 'models/admin_transaction_model.dart';
import 'models/admin_portfolio_model.dart';
import 'models/admin_candle_model.dart';

abstract class AdminRepository {
  // Khách hàng
  Future<AdminPage<AdminCustomerModel>> listCustomers({
    String? q,
    String? role,
    String? status,
    int page = 1,
    int pageSize = 20,
  });
  Future<AdminCustomerModel> getCustomer(int customerId);
  Future<AdminCustomerModel> createCustomer(Map<String, dynamic> data);
  Future<AdminCustomerModel> updateCustomer(
    int customerId,
    Map<String, dynamic> data,
  );
  Future<void> deleteCustomer(int customerId);

  // Tài khoản đầu tư
  Future<AdminPage<AdminAccountModel>> listAccounts({
    String? q,
    int? customerId,
    String? accountType,
    String? status,
    int page = 1,
    int pageSize = 20,
  });
  Future<AdminAccountModel> createAccount(Map<String, dynamic> data);
  Future<AdminAccountModel> updateAccount(
    int accountId,
    Map<String, dynamic> data,
  );
  Future<void> deleteAccount(int accountId);

  Future<AdminDashboardModel> getDashboard();

    // Cổ phiếu
  Future<AdminPage<AdminStockModel>> listStocks({
    String? q,
    String? exchange,
    String? status,
    int page = 1,
    int pageSize = 20,
  });
  Future<AdminStockModel> createStock(Map<String, dynamic> data);
  Future<AdminStockModel> updateStock(int stockId, Map<String, dynamic> data);
  Future<void> deleteStock(int stockId);

    // Thông báo
  Future<AdminPage<AdminNotificationModel>> listNotifications({
    int? customerId,
    String? notificationType,
    int page = 1,
    int pageSize = 20,
  });

  /// customer_id = null nghĩa là gửi cho toàn bộ khách hàng đang hoạt động.
  Future<AdminNotificationModel> sendNotification(Map<String, dynamic> data);
  Future<void> deleteNotification(int notificationId);

  // Lệnh đặt
  Future<AdminPage<AdminOrderModel>> listOrders({
    int? accountId,
    String? stockSymbol,
    String? status,
    String? orderType,
    int page = 1,
    int pageSize = 20,
  });
  Future<AdminOrderModel> updateOrder(int orderId, Map<String, dynamic> data);
  Future<void> deleteOrder(int orderId);

  // Giao dịch (chỉ xem)
  Future<AdminPage<AdminTransactionModel>> listTransactions({
    int? accountId,
    String? stockSymbol,
    String? transactionType,
    int page = 1,
    int pageSize = 20,
  });

  // Danh mục nắm giữ
  Future<AdminPage<AdminPortfolioModel>> listPortfolios({
    int? accountId,
    String? stockSymbol,
    int page = 1,
    int pageSize = 20,
  });
  Future<AdminPortfolioModel> createPortfolio(Map<String, dynamic> data);
  Future<AdminPortfolioModel> updatePortfolio(
    int portfolioId,
    Map<String, dynamic> data,
  );
  Future<void> deletePortfolio(int portfolioId);

    // Lịch sử giá (nến)
  Future<AdminPage<AdminCandleModel>> listCandles({
    String? stockSymbol,
    int page = 1,
    int pageSize = 30,
  });
  Future<AdminCandleModel> createCandle(Map<String, dynamic> data);
  Future<AdminCandleModel> updateCandle(
    int candleId,
    Map<String, dynamic> data,
  );
  Future<void> deleteCandle(int candleId);
}