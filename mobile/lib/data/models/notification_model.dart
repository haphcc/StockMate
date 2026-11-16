import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String content;
  final String notificationType;
  final int? refId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.notificationType,
    this.refId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({
    int? id,
    String? title,
    String? content,
    String? notificationType,
    int? refId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      notificationType: notificationType ?? this.notificationType,
      refId: refId ?? this.refId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['notification_id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      notificationType: json['notification_type'] ?? 'SYSTEM',
      refId: json['ref_id'] as int?,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': id,
      'title': title,
      'content': content,
      'notification_type': notificationType,
      'ref_id': refId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, content, notificationType, refId, isRead, createdAt];
}
