import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_notification_model.dart';
import '../data/models/admin_page.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_notification_compose_screen.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  String? _type;
  int _page = 1;

  AdminNotificationQuery get _query =>
      AdminNotificationQuery(notificationType: _type, page: _page);

  Future<void> _compose() async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AdminNotificationComposeScreen(),
      ),
    );
    if (sent == true) {
      setState(() => _page = 1);
      ref.invalidate(adminNotificationsProvider);
    }
  }

  Future<void> _delete(AdminNotificationModel n) async {
    final ok = await showAdminConfirm(
      context,
      title: 'Xóa thông báo',
      message: 'Xóa thông báo "${n.title}" đã gửi cho ${n.customerName}?',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteNotification(n.notificationId);
      ref.invalidate(adminNotificationsProvider);
      if (!mounted) return;
      showAdminSnack(context, 'Đã xóa thông báo');
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminNotificationsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Soạn thông báo',
            icon: const Icon(Icons.edit_notifications_rounded),
            onPressed: _compose,
          ),
        ],
      ),
      body: Column(
        children: [
          AdminFilterChips(
            options: AdminConstants.notificationTypes,
            selected: _type,
            onChanged: (v) => setState(() {
              _type = v;
              _page = 1;
            }),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminNotificationsProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notifications_off_outlined,
                    message: 'Chưa có thông báo nào',
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: page.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _tile(page.items[i]),
                      ),
                    ),
                    _pager(page),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(AdminNotificationModel n) {
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!n.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  n.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AdminStatusBadge(code: n.notificationType),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${n.customerName} · ${formatDateTime(n.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xóa',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.priceDown,
            ),
            onPressed: () => _delete(n),
          ),
        ],
      ),
    );
  }

  Widget _pager(AdminPage<AdminNotificationModel> page) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: page.page > 1
                ? () => setState(() => _page = page.page - 1)
                : null,
            child: const Text('Trước'),
          ),
          Text(
            'Trang ${page.page}/${page.totalPages} · ${page.total} thông báo',
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: page.page < page.totalPages
                ? () => setState(() => _page = page.page + 1)
                : null,
            child: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}