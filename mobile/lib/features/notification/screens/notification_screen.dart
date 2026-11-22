import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/stockmate_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../market/widgets/market_components.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});
  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _api = StockmateApi();
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  final _items = <_NoticePreview>[
    _NoticePreview(
      title: 'Lệnh FPT khớp một phần',
      content:
          'Lệnh mua 500 cổ phiếu FPT đã khớp 200 cổ phiếu ở mức giá 134.200 ₫.',
      time: '14:32 · Hôm nay',
      type: 'ORDER',
      icon: Icons.swap_horiz_rounded,
      unread: true,
    ),
    _NoticePreview(
      title: 'Xác nhận giao dịch',
      content:
          'Giao dịch bán 300 cổ phiếu SSI đã hoàn tất. Tiền bán dự kiến về tài khoản ngày 18/11.',
      time: '10:08 · Hôm nay',
      type: 'ACCOUNT',
      icon: Icons.check_circle_outline_rounded,
      unread: true,
    ),
    _NoticePreview(
      title: 'Bản tin thị trường',
      content:
          'VN-Index tăng 0,97% trong phiên sáng, thanh khoản tập trung ở nhóm ngân hàng và công nghệ.',
      time: '09:15 · Hôm nay',
      type: 'PRICE_ALERT',
      icon: Icons.candlestick_chart_rounded,
      unread: false,
    ),
    _NoticePreview(
      title: 'Lịch nghỉ giao dịch',
      content:
          'Thị trường chứng khoán sẽ nghỉ giao dịch vào ngày lễ theo lịch công bố của sở giao dịch.',
      time: '16:30 · 12/11',
      type: 'SYSTEM',
      icon: Icons.campaign_outlined,
      unread: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (!AppConfig.useMock) _items.clear();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (AppConfig.useMock) {
      setState(() => _loading = false);
      return;
    }
    try {
      final rows = await _api.notifications();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(
            rows.map((row) {
              final rawType = '${row['notification_type']}';
              final created = DateTime.tryParse(
                '${row['created_at']}',
              )?.toLocal();
              return _NoticePreview(
                id: (row['notification_id'] as num).toInt(),
                title: '${row['title']}',
                content: '${row['content']}',
                time: created == null
                    ? ''
                    : '${created.day}/${created.month} · ${created.hour}:${created.minute.toString().padLeft(2, '0')}',
                type: rawType,
                icon: Icons.notifications_outlined,
                unread: !(row['is_read'] as bool),
              );
            }),
          );
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _items.clear();
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _markRead(_NoticePreview item) async {
    try {
      if (!AppConfig.useMock && item.id != null) await _api.markRead(item.id!);
      if (mounted) setState(() => item.unread = false);
    } catch (error) {
      if (mounted) {
        final l10n = ref.read(l10nProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.isVietnamese ? 'Không cập nhật được thông báo: $error' : 'Failed to update notification: $error')),
        );
      }
    }
  }

  String _getTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'ORDER':
        return l10n.notifTypeOrder;
      case 'PRICE_ALERT':
      case 'MARKET':
        return l10n.notifTypeMarket;
      case 'ACCOUNT':
        return l10n.notifTypeAccount;
      case 'SYSTEM':
        return l10n.notifTypeSystem;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final items = _items
        .where(
          (item) =>
              _filter == 'all' ||
              (_filter == 'unread' ? item.unread : item.type == _filter),
        )
        .toList();
    final unread = _items.where((item) => item.unread).length;
    final filterOptions = [
      ('all', l10n.all),
      ('unread', l10n.unreadOnly),
      ('ORDER', l10n.notifTypeOrder),
      ('PRICE_ALERT', l10n.notifTypeMarket),
      ('SYSTEM', l10n.notifTypeSystem),
    ];
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadNotifications,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.darkCard,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notificationsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.isVietnamese
                            ? '$unread thông báo chưa đọc'
                            : '$unread unread notification${unread == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: unread == 0
                      ? null
                      : () {
                          for (final item in _items.where(
                            (item) => item.unread,
                          )) {
                            _markRead(item);
                          }
                        },
                  child: Text(
                    l10n.isVietnamese ? 'Đọc tất cả' : 'Read all',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!_loading && _error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.isVietnamese ? 'Không tải được thông báo: $_error' : 'Failed to load notifications: $_error',
                  style: const TextStyle(color: AppColors.priceDown),
                ),
              ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterOptions
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChipPill(
                          label: filter.$2,
                          selected: _filter == filter.$1,
                          onTap: () => setState(() => _filter = filter.$1),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            SectionTitle(l10n.isVietnamese ? 'Gần đây' : 'Recent'),
            const SizedBox(height: 10),
            if (items.isEmpty)
              MarketPanel(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.noNotifications,
                      style: const TextStyle(color: AppColors.darkTextSecondary),
                    ),
                  ),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _markRead(item),
                    child: MarketPanel(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: item.unread
                                  ? AppColors.primary.withValues(alpha: .12)
                                  : AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.unread
                                  ? AppColors.primary
                                  : AppColors.darkTextMuted,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: item.unread
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (item.unread)
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
                                  style: const TextStyle(
                                    color: AppColors.darkTextSecondary,
                                    fontSize: 10,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Row(
                                  children: [
                                    Text(
                                      _getTypeLabel(item.type, l10n).toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.darkTextMuted,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: .5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.circle,
                                      color: AppColors.darkTextMuted,
                                      size: 3,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.time,
                                      style: const TextStyle(
                                        color: AppColors.darkTextMuted,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.isVietnamese
                  ? 'Thông báo của tài khoản đang đăng nhập'
                  : 'Notifications for logged in account',
              style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _NoticePreview {
  _NoticePreview({
    this.id,
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    required this.icon,
    required this.unread,
  });
  final int? id;
  final String title, content, time, type;
  final IconData icon;
  bool unread;
}
