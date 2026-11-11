import 'package:dio/dio.dart';
import 'admin_exception.dart';
import 'admin_repository.dart';
import 'admin_token_source.dart';
import 'models/admin_account_model.dart';
import 'models/admin_customer_model.dart';
import 'models/admin_dashboard_model.dart';
import 'models/admin_page.dart';
import 'models/admin_stock_model.dart';
import 'models/admin_notification_model.dart';

class ApiAdminRepository implements AdminRepository {
  final Dio _dio;
  final AdminTokenSource _tokenSource;

  ApiAdminRepository({
    required String baseUrl,
    required AdminTokenSource tokenSource,
  })  : _tokenSource = tokenSource,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            responseType: ResponseType.json,
          ),
        );

  // ---------------- Hạ tầng gọi API ----------------

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await _tokenSource.getToken();
      try {
        final response = await _dio.request<dynamic>(
          path,
          data: body,
          queryParameters: query,
          options: Options(
            method: method,
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          ),
        );
        return response.data;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 && attempt == 0) {
          await _tokenSource.invalidate();
          continue;
        }
        throw _toAdminException(e);
      }
    }
    throw const AdminException(
      'Phiên đăng nhập đã hết hạn.',
      code: 'UNAUTHORIZED',
    );
  }

  AdminException _toAdminException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final code = error['code']?.toString() ?? 'ERROR';
      var message = error['message']?.toString() ?? 'Có lỗi xảy ra.';
      final details = error['details'];
      if (details is Map &&
          details['fields'] is List &&
          (details['fields'] as List).isNotEmpty) {
        final first = (details['fields'] as List).first;
        if (first is Map) {
          final loc = first['loc'];
          final field = loc is List && loc.isNotEmpty ? loc.last : '';
          message = '$message ($field: ${first['message']})';
        }
      }
      return AdminException(message, code: code);
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AdminException(
          'Không kết nối được máy chủ. Kiểm tra backend và địa chỉ API.',
          code: 'NETWORK_ERROR',
        );
      default:
        return AdminException(
          'Lỗi ${e.response?.statusCode ?? ''}: ${e.message}',
          code: 'HTTP_ERROR',
        );
    }
  }

  Map<String, dynamic> _asMap(dynamic data) => data as Map<String, dynamic>;

  // ---------------- Khách hàng ----------------

  @override
  Future<AdminPage<AdminCustomerModel>> listCustomers({
    String? q,
    String? role,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _request(
      'GET',
      '/api/admin/customers',
      query: {
        if (q != null && q.isNotEmpty) 'q': q,
        'role': ?role,
        'status': ?status,
        'page': page,
        'page_size': pageSize,
      },
    );
    return AdminPage<AdminCustomerModel>.fromJson(
      _asMap(data),
      AdminCustomerModel.fromJson,
    );
  }

  @override
  Future<AdminCustomerModel> getCustomer(int customerId) async {
    final data = await _request('GET', '/api/admin/customers/$customerId');
    return AdminCustomerModel.fromJson(_asMap(data));
  }

  @override
  Future<AdminCustomerModel> createCustomer(Map<String, dynamic> data) async {
    final result = await _request('POST', '/api/admin/customers', body: data);
    return AdminCustomerModel.fromJson(_asMap(result));
  }

  @override
  Future<AdminCustomerModel> updateCustomer(
    int customerId,
    Map<String, dynamic> data,
  ) async {
    final result = await _request(
      'PUT',
      '/api/admin/customers/$customerId',
      body: data,
    );
    return AdminCustomerModel.fromJson(_asMap(result));
  }

  @override
  Future<void> deleteCustomer(int customerId) async {
    await _request('DELETE', '/api/admin/customers/$customerId');
  }

  // ---------------- Tài khoản đầu tư ----------------

  @override
  Future<AdminPage<AdminAccountModel>> listAccounts({
    String? q,
    int? customerId,
    String? accountType,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _request(
      'GET',
      '/api/admin/accounts',
      query: {
        'customer_id': ?customerId,
        'account_type': ?accountType,
        'status': ?status,
        'page': page,
        'page_size': pageSize,
      },
    );
    return AdminPage<AdminAccountModel>.fromJson(
      _asMap(data),
      AdminAccountModel.fromJson,
    );
  }

  @override
  Future<AdminAccountModel> createAccount(Map<String, dynamic> data) async {
    final result = await _request('POST', '/api/admin/accounts', body: data);
    return AdminAccountModel.fromJson(_asMap(result));
  }

  @override
  Future<AdminAccountModel> updateAccount(
    int accountId,
    Map<String, dynamic> data,
  ) async {
    final result = await _request(
      'PUT',
      '/api/admin/accounts/$accountId',
      body: data,
    );
    return AdminAccountModel.fromJson(_asMap(result));
  }

  @override
  Future<void> deleteAccount(int accountId) async {
    await _request('DELETE', '/api/admin/accounts/$accountId');
  }

    // ---------------- Cổ phiếu ----------------

  @override
  Future<AdminPage<AdminStockModel>> listStocks({
    String? q,
    String? exchange,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _request(
      'GET',
      '/api/admin/stocks',
      query: {
        if (q != null && q.isNotEmpty) 'q': q,
        'exchange': ?exchange,
        'status': ?status,
        'page': page,
        'page_size': pageSize,
      },
    );
    return AdminPage<AdminStockModel>.fromJson(
      _asMap(data),
      AdminStockModel.fromJson,
    );
  }

  @override
  Future<AdminStockModel> createStock(Map<String, dynamic> data) async {
    final result = await _request('POST', '/api/admin/stocks', body: data);
    return AdminStockModel.fromJson(_asMap(result));
  }

  @override
  Future<AdminStockModel> updateStock(
    int stockId,
    Map<String, dynamic> data,
  ) async {
    final result = await _request(
      'PUT',
      '/api/admin/stocks/$stockId',
      body: data,
    );
    return AdminStockModel.fromJson(_asMap(result));
  }

  @override
  Future<void> deleteStock(int stockId) async {
    await _request('DELETE', '/api/admin/stocks/$stockId');
  }
  
    // ---------------- Thông báo ----------------

  @override
  Future<AdminPage<AdminNotificationModel>> listNotifications({
    int? customerId,
    String? notificationType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _request(
      'GET',
      '/api/admin/notifications',
      query: {
        'customer_id': ?customerId,
        'notification_type': ?notificationType,
        'page': page,
        'page_size': pageSize,
      },
    );
    return AdminPage<AdminNotificationModel>.fromJson(
      _asMap(data),
      AdminNotificationModel.fromJson,
    );
  }

  @override
  Future<AdminNotificationModel> sendNotification(
    Map<String, dynamic> data,
  ) async {
    final result = await _request('POST', '/api/admin/notifications', body: data);
    return AdminNotificationModel.fromJson(_asMap(result));
  }

  @override
  Future<void> deleteNotification(int notificationId) async {
    await _request('DELETE', '/api/admin/notifications/$notificationId');
  }
  
  // ---------------- Dashboard ----------------

  @override
  Future<AdminDashboardModel> getDashboard() async {
    final data = await _request('GET', '/api/admin/dashboard');
    return AdminDashboardModel.fromJson(_asMap(data));
  }
}