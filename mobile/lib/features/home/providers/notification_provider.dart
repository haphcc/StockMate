import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/app_providers.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return _fetch();
  }

  Future<List<NotificationModel>> _fetch({bool unreadOnly = false}) async {
    final repo = ref.read(notificationRepositoryProvider);
    return repo.getNotifications(unreadOnly: unreadOnly);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> markAsRead(int notificationId) async {
    final currentList = state.value ?? [];
    try {
      final updated = await ref
          .read(notificationRepositoryProvider)
          .markAsRead(notificationId);
      state = AsyncValue.data(
        currentList.map((n) => n.id == notificationId ? updated : n).toList(),
      );
    } catch (_) {
      // optimistic update
      state = AsyncValue.data(
        currentList
            .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
            .toList(),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final currentList = state.value ?? [];
    for (final n in currentList.where((e) => !e.isRead)) {
      try {
        await ref.read(notificationRepositoryProvider).markAsRead(n.id);
      } catch (_) {}
    }
    state = AsyncValue.data(
      currentList.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }
}

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(notificationsProvider);
  return notifsAsync.value?.where((n) => !n.isRead).length ?? 0;
});
