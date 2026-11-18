import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsSheet extends ConsumerStatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  ConsumerState<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<NotificationsSheet> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(notificationsProvider.notifier).refresh(showLoading: false);
      }
    });
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'ORDER_MATCHED':
        return Icons.check_circle_outline_rounded;
      case 'DEPOSIT_SUCCESS':
        return Icons.account_balance_wallet_outlined;
      case 'MARKET_NEWS':
        return Icons.trending_up_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'ORDER_MATCHED':
        return AppColors.primary;
      case 'DEPOSIT_SUCCESS':
        return const Color(0xFF06B6D4);
      case 'MARKET_NEWS':
        return const Color(0xFFFACC15);
      default:
        return const Color(0xFFC084FC);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.darkCardBorder),
          left: BorderSide(color: AppColors.darkCardBorder),
          right: BorderSide(color: AppColors.darkCardBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkCardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Thông báo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Color(0xFF032617),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
                        child: const Text(
                          'Đã đọc tất cả',
                          style: TextStyle(color: AppColors.primary, fontSize: 12),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.darkTextSecondary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter bar (Tất cả / Chưa đọc)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: !_unreadOnly,
                  onSelected: (val) => setState(() => _unreadOnly = !val),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.darkBackground,
                  labelStyle: TextStyle(
                    color: !_unreadOnly ? const Color(0xFF032617) : AppColors.darkTextSecondary,
                    fontSize: 12,
                    fontWeight: !_unreadOnly ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Chưa đọc ($unreadCount)'),
                  selected: _unreadOnly,
                  onSelected: (val) => setState(() => _unreadOnly = val),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.darkBackground,
                  labelStyle: TextStyle(
                    color: _unreadOnly ? const Color(0xFF032617) : AppColors.darkTextSecondary,
                    fontSize: 12,
                    fontWeight: _unreadOnly ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.darkCardBorder, height: 1),

          // Notification List
          Expanded(
            child: notifsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.priceDown, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Lỗi tải thông báo: $err',
                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(notificationsProvider.notifier).refresh(),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Thử lại', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
              data: (list) {
                final displayed = _unreadOnly ? list.where((n) => !n.isRead).toList() : list;

                if (displayed.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _unreadOnly ? 'Không có thông báo chưa đọc nào.' : 'Chưa có thông báo nào.',
                          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.darkCard,
                  onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: displayed.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: AppColors.darkCardBorder,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = displayed[index];
                      final iconColor = _getIconColor(item.notificationType);

                      return InkWell(
                        onTap: () {
                          if (!item.isRead) {
                            ref.read(notificationsProvider.notifier).markAsRead(item.id);
                          }
                          _showNotificationDetail(context, item);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: item.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_getIcon(item.notificationType), color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.content,
                                      style: TextStyle(
                                        color: item.isRead ? AppColors.darkTextSecondary : Colors.white70,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatTime(item.createdAt),
                                      style: const TextStyle(
                                        color: AppColors.darkTextMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  void _showNotificationDetail(BuildContext context, NotificationModel item) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkCardBorder),
        ),
        title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          item.content,
          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
