import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> googleLogin({String? idToken, String? accessToken});
  Future<UserModel> register(Map<String, dynamic> data);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateProfile({String? fullName, String? phoneNumber, String? avatarUrl});
  Future<void> changePassword({String? oldPassword, required String newPassword});
}
