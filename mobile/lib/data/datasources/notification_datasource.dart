import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationDatasource {
  final Dio _dio;

  NotificationDatasource(DioClient client) : _dio = client.dio;

  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.notifications,
        queryParameters: {
          'unread': unreadOnly,
          'page': page,
          'page_size': pageSize,
        },
      );
      final data = response.data;
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<NotificationModel> markAsRead(int notificationId) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.readNotification(notificationId),
      );
      return NotificationModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
