import '../../core/network/dio_client.dart';
import '../../core/storage/token_storage.dart';
import '../datasources/auth_datasource.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final AuthDatasource datasource;
  final TokenStorage tokenStorage;

  ApiAuthRepository({required DioClient client, TokenStorage? tokenStorage})
      : datasource = AuthDatasource(client),
        tokenStorage = tokenStorage ?? client.tokenStorage;

  Future<UserModel> _saveAndReadUser(Map<String, dynamic> body) async {
    await tokenStorage.saveTokens(
      accessToken: body['access_token'].toString(),
      refreshToken: body['refresh_token'].toString(),
    );
    return UserModel.fromJson(Map<String, dynamic>.from(body['user'] as Map));
  }

  @override
  Future<UserModel> login(String email, String password) async {
    return _saveAndReadUser(await datasource.login(email.trim().toLowerCase(), password));
  }

  @override
  Future<UserModel> register(Map<String, dynamic> data) async {
    return _saveAndReadUser(await datasource.register(data));
  }

  @override
  Future<void> logout() => tokenStorage.clear();

  @override
  Future<UserModel?> getCurrentUser() async {
    final token = await tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      return UserModel.fromJson(await datasource.me());
    } catch (_) {
      await tokenStorage.clear();
      return null;
    }
  }
}
