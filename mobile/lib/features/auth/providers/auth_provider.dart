import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<UserModel?> build() async {
    // Kiểm tra token để tự động đăng nhập
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      return ref.read(authRepositoryProvider).getCurrentUser();
    }
    return null;
  }

  Future<void> login(String emailOrPhone, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).login(emailOrPhone, password);
      // Giả lập lưu token
      await _storage.write(key: 'jwt_token', value: 'mock_token_123');
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).register(data);
      // Giả lập lưu token
      await _storage.write(key: 'jwt_token', value: 'mock_token_123');
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await ref.read(authRepositoryProvider).logout();
    await _storage.delete(key: 'jwt_token');
    state = const AsyncValue.data(null);
  }
}
