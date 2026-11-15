import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(Map<String, dynamic> data);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateProfile({String? fullName, String? phoneNumber, String? avatarUrl});
  Future<void> changePassword({required String oldPassword, required String newPassword});
}
