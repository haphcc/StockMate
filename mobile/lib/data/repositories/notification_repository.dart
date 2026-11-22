import '../../core/network/dio_client.dart';
import '../datasources/notification_datasource.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({bool unreadOnly = false, int page = 1, int pageSize = 50});
  Future<NotificationModel> markAsRead(int notificationId);
}

class ApiNotificationRepository implements NotificationRepository {
  final NotificationDatasource datasource;

  ApiNotificationRepository({required DioClient client})
      : datasource = NotificationDatasource(client);

  @override
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 50,
  }) {
    return datasource.getNotifications(
      unreadOnly: unreadOnly,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<NotificationModel> markAsRead(int notificationId) {
    return datasource.markAsRead(notificationId);
  }
}

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationModel> _mockList = [
    NotificationModel(
      id: 1,
      title: 'Khớp lệnh mua MWG',
      content: 'Lệnh mua 500 MWG giá 64,500đ đã khớp thành công. Giá trị 32,250,000đ.',
      notificationType: 'ORDER_MATCHED',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationModel(
      id: 2,
      title: 'Nạp tiền thành công',
      content: 'Tài khoản của bạn đã được cộng 10,000,000đ qua VietQR.',
      notificationType: 'DEPOSIT_SUCCESS',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 3,
      title: 'Chào mừng bạn đến với StockMate',
      content: 'Tài khoản giao dịch chứng khoán của bạn đã được kích hoạt thành công.',
      notificationType: 'SYSTEM',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (unreadOnly) {
      return _mockList.where((n) => !n.isRead).toList();
    }
    return List.from(_mockList);
  }

  @override
  Future<NotificationModel> markAsRead(int notificationId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _mockList.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final updated = _mockList[index].copyWith(isRead: true);
      _mockList[index] = updated;
      return updated;
    }
    throw Exception('Notification not found');
  }
}
