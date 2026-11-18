import 'auth_repository.dart';
import '../models/user_model.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel> login(String email, String password) async {
    final admin = email.trim().toLowerCase() == 'an.nguyen@gmail.com';
    _currentUser = UserModel(
      id: admin ? 100 : 1,
      fullName: admin ? 'NGUYEN AN' : 'NGUYEN VAN A',
      email: email,
      phoneNumber: '0912345678',
      status: 'ACTIVE',
      role: admin ? 'ADMIN' : 'CUSTOMER',
      authProvider: 'LOCAL',
      hasPassword: true,
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> googleLogin({String? idToken, String? accessToken}) async {
    _currentUser = const UserModel(
      id: 3,
      fullName: 'GOOGLE INVESTOR',
      email: 'investor.google@stockmate.vn',
      phoneNumber: 'G999999999',
      status: 'ACTIVE',
      role: 'CUSTOMER',
      authProvider: 'GOOGLE',
      hasPassword: false,
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> register(Map<String, dynamic> data) async {
    _currentUser = UserModel(
      id: 2,
      fullName: data['full_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phone_number'] as String? ?? '',
      status: 'ACTIVE',
      role: 'CUSTOMER',
      authProvider: 'LOCAL',
      hasPassword: true,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) throw Exception('Not logged in');
    _currentUser = _currentUser!.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );
    return _currentUser!;
  }

  @override
  Future<void> changePassword({
    String? oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) throw Exception('Not logged in');
    _currentUser = _currentUser!.copyWith(hasPassword: true);
  }
}
