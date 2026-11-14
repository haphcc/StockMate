import '../../core/network/stockmate_api.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({StockmateApi? api}) : _api = api ?? StockmateApi();
  final StockmateApi _api;

  @override
  Future<UserModel> login(String emailOrPhone, String password) async =>
      UserModel.fromJson(await _api.login(emailOrPhone, password));

  @override
  Future<UserModel> register(Map<String, dynamic> data) async =>
      UserModel.fromJson(await _api.register(data));

  @override
  Future<void> logout() => _api.logout();

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      return UserModel.fromJson(await _api.me());
    } catch (_) {
      await _api.logout();
      return null;
    }
  }
}
