import 'package:equatable/equatable.dart';

class AdminNotificationModel extends Equatable {
  final int notificationId;
  final int customerId;
  final String customerName;
  final String title;
  final String content;
  final String notificationType;
  final int? refId;
  final bool isRead;
  final String createdAt;

  const AdminNotificationModel({
    required this.notificationId,
    required this.customerId,
    this.customerName = '',
    required this.title,
    required this.content,
    required this.notificationType,
    this.refId,
    this.isRead = false,
    this.createdAt = '',
  });

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    return AdminNotificationModel(
      notificationId: json['notification_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      notificationType: json['notification_type'] ?? 'SYSTEM',
      refId: json['ref_id'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        notificationId,
        customerId,
        customerName,
        title,
        content,
        notificationType,
        refId,
        isRead,
        createdAt,
      ];
}