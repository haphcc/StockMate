import 'models/admin_account_model.dart';
import 'models/admin_customer_model.dart';
import 'models/admin_page.dart';

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
}