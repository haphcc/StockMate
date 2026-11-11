import 'models/admin_account_model.dart';
import 'models/admin_customer_model.dart';
import 'models/admin_page.dart';
import 'models/admin_dashboard_model.dart';
import 'models/admin_stock_model.dart';

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
}