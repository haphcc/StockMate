import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/selected_account_provider.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login(String emailOrPhone, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).login(emailOrPhone, password);
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).register(data);
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await ref.read(authRepositoryProvider).logout();
    ref.read(selectedAccountProvider.notifier).select(null);
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final updated = await ref.read(authRepositoryProvider).updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );
    state = AsyncValue.data(updated);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await ref.read(authRepositoryProvider).changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
