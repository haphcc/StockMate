import 'auth_repository.dart';
import '../models/user_model.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel> login(String emailOrPhone, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = const UserModel(
      id: 1,
      fullName: 'NGUYEN VAN A',
      email: 'investor@stockmate.vn',
      phoneNumber: '0912345678',
      status: 'ACTIVE',
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> register(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = UserModel(
      id: 2,
      fullName: data['full_name'] ?? 'NGUYEN VAN A',
      email: data['email'] ?? 'investor@stockmate.vn',
      phoneNumber: data['phone_number'] ?? '0912345678',
      status: 'ACTIVE',
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser; // return null giả lập chưa đăng nhập ban đầu
  }
}
