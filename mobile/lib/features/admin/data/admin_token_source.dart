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
/// Hiện app vẫn lưu token giả nên chưa dùng được với backend thật.
class StoredTokenSource implements AdminTokenSource {
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> getToken() => _storage.read(key: 'jwt_token');

  @override
  Future<void> invalidate() async {}
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