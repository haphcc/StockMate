import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

final stockmateApiProvider = Provider<StockmateApi>((ref) => StockmateApi());

/// Small typed boundary for the REST contract documented in docs/API_CONTRACT.md.
class StockmateApi {
  StockmateApi() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'access_token');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          final options = error.requestOptions;
          final publicAuthCall =
              options.path.endsWith('/auth/login') ||
              options.path.endsWith('/auth/register') ||
              options.path.endsWith('/auth/refresh');
          if (error.response?.statusCode == 401 &&
              !publicAuthCall &&
              options.extra['auth_retry'] != true) {
            try {
              final token = await _refreshAccessToken();
              options.extra['auth_retry'] = true;
              options.headers['Authorization'] = 'Bearer $token';
              final retryClient = Dio(
                BaseOptions(baseUrl: AppConfig.apiBaseUrl),
              );
              handler.resolve(await retryClient.fetch(options));
              return;
            } catch (_) {
              await logout();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio dio;
  final storage = const FlutterSecureStorage();
  Future<String>? _refreshing;

  Future<String> _refreshAccessToken() {
    final current = _refreshing;
    if (current != null) return current;
    final next = _doRefresh();
    _refreshing = next;
    return next.whenComplete(() => _refreshing = null);
  }

  Future<String> _doRefresh() async {
    final refresh = await storage.read(key: 'refresh_token');
    if (refresh == null) throw StateError('Phiên đăng nhập đã hết hạn.');
    final response = await Dio(
      BaseOptions(baseUrl: AppConfig.apiBaseUrl),
    ).post('/api/auth/refresh', data: {'refresh_token': refresh});
    final result = Map<String, dynamic>.from(response.data as Map);
    final access = result['access_token'] as String;
    await storage.write(key: 'access_token', value: access);
    final rotated = result['refresh_token'];
    if (rotated is String) {
      await storage.write(key: 'refresh_token', value: rotated);
    }
    return access;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post(
      '/api/auth/login',
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    await storage.write(
      key: 'access_token',
      value: data['access_token'] as String,
    );
    await storage.write(
      key: 'refresh_token',
      value: data['refresh_token'] as String,
    );
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final response = await dio.post('/api/auth/register', data: payload);
    final data = Map<String, dynamic>.from(response.data as Map);
    await storage.write(
      key: 'access_token',
      value: data['access_token'] as String,
    );
    await storage.write(
      key: 'refresh_token',
      value: data['refresh_token'] as String,
    );
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  Future<Map<String, dynamic>> me() async =>
      _map((await dio.get('/api/auth/me')).data);
  Future<List<Map<String, dynamic>>> accounts() async =>
      _list((await dio.get('/api/accounts')).data);
  Future<int> firstAccountId() async {
    final rows = await accounts();
    final selected = int.tryParse(
      await storage.read(key: 'selected_account_id') ?? '',
    );
    if (selected != null &&
        rows.any((row) => (row['account_id'] as num).toInt() == selected)) {
      return selected;
    }
    // Ưu tiên tài khoản CASH đang ACTIVE để đồng bộ với Danh mục đầu tư và Dashboard
    final cashAccount = rows.firstWhere(
      (row) =>
          row['account_type'] == 'CASH' && row['status'] == 'ACTIVE',
      orElse: () => rows.firstWhere(
        (row) => row['status'] == 'ACTIVE',
        orElse: () => rows.isNotEmpty ? rows.first : <String, dynamic>{},
      ),
    );
    if (cashAccount.isNotEmpty) {
      final id = (cashAccount['account_id'] as num).toInt();
      await selectAccount(id);
      return id;
    }
    if (rows.isEmpty) throw Exception('Tài khoản chưa có tài khoản đầu tư.');
    return (rows.first['account_id'] as num).toInt();
  }

  Future<void> selectAccount(int accountId) =>
      storage.write(key: 'selected_account_id', value: '$accountId');

  Future<Map<String, dynamic>> assets(int accountId) async =>
      _map((await dio.get('/api/accounts/$accountId/assets')).data);
  Future<List<Map<String, dynamic>>> portfolio(int accountId) async =>
      _list((await dio.get('/api/accounts/$accountId/portfolio')).data);

  Future<List<Map<String, dynamic>>> market({
    String? exchange,
    String? query,
    bool live = true,
  }) async => _page(
    (await dio.get(
      '/api/market/board',
      queryParameters: {
        if (exchange != null && exchange != 'Tất cả') 'exchange': exchange,
        if (query != null && query.isNotEmpty) 'q': query,
        'page': 1,
        'page_size': 100,
        'live': live,
      },
    )).data,
  );
  Future<Map<String, dynamic>> stock(String symbol, {bool live = true}) async =>
      _map(
        (await dio.get(
          '/api/stocks/$symbol',
          queryParameters: {'live': live},
        )).data,
      );
  Future<List<Map<String, dynamic>>> chart(
    String symbol,
    String range, {
    bool live = true,
  }) async => _list(
    (await dio.get(
      '/api/stocks/$symbol/chart',
      queryParameters: {'range': range, 'live': live},
    )).data,
  );

  Future<List<Map<String, dynamic>>> watchlist() async =>
      _list((await dio.get('/api/watchlist')).data);
  Future<void> addWatch(String symbol) async {
    await dio.post('/api/watchlist', data: {'stock_symbol': symbol});
  }

  Future<void> removeWatch(String symbol) async {
    await dio.delete('/api/watchlist/$symbol');
  }

  Future<List<Map<String, dynamic>>> orders(
    int accountId, {
    String? status,
  }) async => _page(
    (await dio.get(
      '/api/accounts/$accountId/orders',
      queryParameters: {
        'page': 1,
        'page_size': 100,
        'status': ?status,
      },
    )).data,
  );
  Future<Map<String, dynamic>> placeOrder(
    int accountId,
    Map<String, dynamic> payload,
  ) async => _map(
    (await dio.post('/api/accounts/$accountId/orders', data: payload)).data,
  );
  Future<Map<String, dynamic>> cancelOrder(int orderId) async =>
      _map((await dio.delete('/api/orders/$orderId')).data);
  Future<List<Map<String, dynamic>>> transactions(int accountId) async => _page(
    (await dio.get(
      '/api/accounts/$accountId/transactions',
      queryParameters: {'page': 1, 'page_size': 100},
    )).data,
  );

  Future<List<Map<String, dynamic>>> notifications({
    bool unread = false,
  }) async => _page(
    (await dio.get(
      '/api/notifications',
      queryParameters: {'page': 1, 'page_size': 100, 'unread': unread},
    )).data,
  );
  Future<void> markRead(int id) async {
    await dio.post('/api/notifications/$id/read');
  }

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'selected_account_id');
  }

  static Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);
  static List<Map<String, dynamic>> _list(dynamic value) =>
      (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  static List<Map<String, dynamic>> _page(dynamic value) =>
      _list(_map(value)['items']);
}
