import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/data/models/notification_model.dart';
import 'package:stockmate/data/models/user_model.dart';
import 'package:stockmate/data/repositories/auth_repository.dart';
import 'package:stockmate/data/repositories/notification_repository.dart';
import 'package:stockmate/features/auth/providers/auth_provider.dart';
import 'package:stockmate/features/home/providers/notification_provider.dart';
import 'package:stockmate/providers/app_providers.dart';

class _FakeAuthRepository implements AuthRepository {
  UserModel? currentUser;

  final Map<String, UserModel> usersByEmail;

  _FakeAuthRepository(this.usersByEmail, {this.currentUser});

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  Future<UserModel> login(String emailOrPhone, String password) async {
    final user = usersByEmail[emailOrPhone]!;
    currentUser = user;
    return user;
  }

  @override
  Future<UserModel> googleLogin({String? idToken, String? accessToken}) {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> register(Map<String, dynamic> data) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    currentUser = null;
  }

  @override
  Future<UserModel> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({
    String? oldPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }
}

class _FakeNotificationRepository implements NotificationRepository {
  final _FakeAuthRepository auth;
  final Map<int, List<NotificationModel>> byCustomer;

  _FakeNotificationRepository(this.auth, this.byCustomer);

  @override
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 50,
  }) async {
    final id = auth.currentUser?.id;
    if (id == null) return const [];
    return List<NotificationModel>.from(byCustomer[id] ?? const []);
  }

  @override
  Future<NotificationModel> markAsRead(int notificationId) async {
    final id = auth.currentUser!.id;
    final list = byCustomer[id]!;
    final idx = list.indexWhere((n) => n.id == notificationId);
    final updated = list[idx].copyWith(isRead: true);
    list[idx] = updated;
    return updated;
  }
}

void main() {
  test('notificationsProvider tự xóa và tải lại theo từng tài khoản đăng nhập', () async {
    const userA = UserModel(
      id: 1,
      fullName: 'Nguyen Van An',
      email: 'an@gmail.com',
      phoneNumber: '0901000001',
      status: 'ACTIVE',
      role: 'ADMIN',
    );
    const userB = UserModel(
      id: 208,
      fullName: 'Phuoc Ha',
      email: 'phuoc@gmail.com',
      phoneNumber: '0901000208',
      status: 'ACTIVE',
      role: 'CUSTOMER',
    );

    final authRepo = _FakeAuthRepository(
      {'an@gmail.com': userA, 'phuoc@gmail.com': userB},
      currentUser: userA,
    );
    final notifRepo = _FakeNotificationRepository(authRepo, {
      1: [
        NotificationModel(
          id: 101,
          title: 'Khớp lệnh SELL HPG',
          content: 'Thông báo riêng của An',
          notificationType: 'TRANSACTION',
          isRead: false,
          createdAt: DateTime(2026, 11, 18, 11, 12),
        ),
      ],
      208: [
        NotificationModel(
          id: 202,
          title: 'Chào mừng tài khoản mới',
          content: 'Thông báo riêng của Phước',
          notificationType: 'SYSTEM',
          isRead: false,
          createdAt: DateTime(2026, 11, 18, 11, 20),
        ),
      ],
    });

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        notificationRepositoryProvider.overrideWithValue(notifRepo),
      ],
    );
    addTearDown(container.dispose);

    // 1. Khi đang đăng nhập User A -> chỉ thấy thông báo của User A
    expect(await container.read(authProvider.future), userA);
    final notifsA = await container.read(notificationsProvider.future);
    expect(notifsA.map((n) => n.title).toList(), ['Khớp lệnh SELL HPG']);

    // 2. Sau khi đăng xuất -> danh sách thông báo về rỗng (không còn của User A)
    await container.read(authProvider.notifier).logout();
    final notifsAfterLogout = await container.read(notificationsProvider.future);
    expect(notifsAfterLogout, isEmpty);

    // 3. Sau khi đăng nhập User B -> chỉ thấy thông báo của User B
    await container.read(authProvider.notifier).login('phuoc@gmail.com', 'pass');
    final notifsB = await container.read(notificationsProvider.future);
    expect(notifsB.map((n) => n.title).toList(), ['Chào mừng tài khoản mới']);
  });
}
