import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'admin_exception.dart';

/// Nguồn cung cấp access token cho các lời gọi /api/admin/...
abstract class AdminTokenSource {
  Future<String?> getToken();

  /// Gọi khi server trả 401 để lần sau lấy token mới.
  Future<void> invalidate();
}

/// Đọc token đã lưu lúc đăng nhập. Dùng được khi đăng nhập thật của Sơn xong.
/// Hỗ trợ tự làm mới token qua /api/auth/refresh nếu có refresh_token.
class StoredTokenSource implements AdminTokenSource {
  static const _defaultStorage = FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  final String? baseUrl;
  final Dio? _dio;

  StoredTokenSource({
    this.baseUrl,
    FlutterSecureStorage? storage,
    Dio? dio,
  })  : _storage = storage ?? _defaultStorage,
        _dio = dio;

  @override
  Future<String?> getToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null && token.isNotEmpty) return token;
    final alt = await _storage.read(key: 'access_token');
    return (alt != null && alt.isNotEmpty) ? alt : null;
  }

  @override
  Future<void> invalidate() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty || baseUrl == null) {
      return;
    }
    final client = _dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl!,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
    try {
      final response = await client.post<dynamic>(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      if (data is Map) {
        final newAccess = data['access_token']?.toString();
        final newRefresh = data['refresh_token']?.toString();
        if (newAccess != null && newAccess.isNotEmpty) {
          await _storage.write(key: 'jwt_token', value: newAccess);
        }
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await _storage.write(key: 'refresh_token', value: newRefresh);
        }
      }
    } on DioException {
      // Refresh token hết hạn hoặc không hợp lệ -> xóa phiên lỗi để không lặp vô ích.
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    }
  }
}

/// TẠM THỜI: tự đăng nhập bằng tài khoản truyền qua --dart-define để thử màn
/// hình admin với backend thật khi chưa có đăng nhập thật. Xóa khi Sơn xong FE-02.
class DevLoginTokenSource implements AdminTokenSource {
  final String baseUrl;
  final String email;
  final String password;
  String? _token;

  DevLoginTokenSource({
    required this.baseUrl,
    required this.email,
    required this.password,
  });

  @override
  Future<String?> getToken() async {
    if (_token != null) return _token;
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    try {
      final response = await dio.post<dynamic>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      if (data is Map) _token = data['access_token']?.toString();
    } on DioException catch (e) {
      throw AdminException(
        'Đăng nhập thử thất bại (${e.response?.statusCode ?? e.type.name}). '
        'Kiểm tra backend đang chạy và tài khoản trong --dart-define.',
        code: 'DEV_LOGIN_FAILED',
      );
    }
    return _token;
  }

  @override
  Future<void> invalidate() async {
    _token = null;
  }
}