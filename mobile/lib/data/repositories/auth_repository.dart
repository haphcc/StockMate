import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String emailOrPhone, String password);
  Future<UserModel> register(Map<String, dynamic> data);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}
