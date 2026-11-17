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
  Future<UserModel> googleLogin(String idToken) async {
    return _saveAndReadUser(await datasource.googleLogin(idToken));
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

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    final response = await datasource.updateProfile(body);
    return UserModel.fromJson(response);
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await datasource.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
