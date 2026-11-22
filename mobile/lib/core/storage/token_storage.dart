import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const accessKey = 'jwt_token';
  static const refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  const TokenStorage({FlutterSecureStorage storage = const FlutterSecureStorage()})
      : _storage = storage;

  Future<String?> readAccessToken() async {
    final token = await _storage.read(key: accessKey);
    if (token != null && token.isNotEmpty) return token;
    return _storage.read(key: 'access_token');
  }

  Future<String?> readRefreshToken() => _storage.read(key: refreshKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: accessKey, value: accessToken);
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: refreshKey, value: refreshToken);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: accessKey),
      _storage.delete(key: refreshKey),
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'selected_account_id'),
    ]);
  }
}
