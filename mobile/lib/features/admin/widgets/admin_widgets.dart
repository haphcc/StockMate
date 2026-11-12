import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_constants.dart';

/// Thẻ nền tối có viền, bấm được (có hiệu ứng gợn sóng).
class AdminCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const AdminCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Nhãn màu theo trạng thái hoặc vai trò (ACTIVE, LOCKED, PENDING, ADMIN...).
class AdminStatusBadge extends StatelessWidget {
  final String code;

  const AdminStatusBadge({super.key, required this.code});

  Color get _color {
      switch (code) {
      case 'ACTIVE':
      case 'COMPLETED':
        return AppColors.priceUp;
      case 'LOCKED':
      case 'SUSPENDED':
      case 'REJECTED':
        return AppColors.priceDown;
      case 'HALTED':
      case 'PENDING':
      case 'PARTIAL':
        return AppColors.priceRef;
      case 'ADMIN':
        return AppColors.accent;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AdminConstants.label(code),
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Một dòng "nhãn: giá trị" trong khung thông tin.
class AdminInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const AdminInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hộp thoại xác nhận. Trả về true nếu người dùng bấm xác nhận.
Future<bool> showAdminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Xác nhận',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.darkSurface,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: danger ? AppColors.priceDown : AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showAdminSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.priceDown : AppColors.primaryDark,
    ),
  );
}

/// Định dạng tiền VND từ chuỗi, ví dụ "50000000.00" thành "50.000.000 ₫".
/// Không chuyển qua double nên không mất độ chính xác.
String formatVnd(String raw) {
  final intPart = raw.split('.').first;
  final negative = intPart.startsWith('-');
  final digits = negative ? intPart.substring(1) : intPart;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer ₫';
}

/// Hàng chip lọc cuộn ngang: "Tất cả" + các tùy chọn.
class AdminFilterChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const AdminFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('Tất cả', null),
          for (final option in options)
            _chip(AdminConstants.label(option), option),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onChanged(value),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.darkCard,
        side: const BorderSide(color: AppColors.darkBorder),
        labelStyle: TextStyle(
          color: isSelected
              ? const Color(0xFF052B19)
              : AppColors.darkTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Định dạng số từ chuỗi, ví dụ "25350.00" thành "25.350". Không qua double.
String formatNumber(String raw) {
  final intPart = raw.split('.').first;
  final negative = intPart.startsWith('-');
  final digits = negative ? intPart.substring(1) : intPart;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer';
}

/// Đổi thời gian ISO (thường là UTC) sang giờ máy: "dd/MM/yyyy HH:mm".
String formatDateTime(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final t = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} '
      '${two(t.hour)}:${two(t.minute)}';
}

/// Bottom sheet chọn phần tử có thanh tìm kiếm dùng chung cho Admin.
Future<T?> showAdminSearchPicker<T>(
  BuildContext context, {
  required String title,
  required String searchHint,
  required Future<List<T>> Function(String query) loadItems,
  required String Function(T item) itemTitle,
  required String Function(T item) itemSubtitle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AdminSearchPickerSheet<T>(
      title: title,
      searchHint: searchHint,
      loadItems: loadItems,
      itemTitle: itemTitle,
      itemSubtitle: itemSubtitle,
    ),
  );
}

class _AdminSearchPickerSheet<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final Future<List<T>> Function(String query) loadItems;
  final String Function(T item) itemTitle;
  final String Function(T item) itemSubtitle;

  const _AdminSearchPickerSheet({
    required this.title,
    required this.searchHint,
    required this.loadItems,
    required this.itemTitle,
    required this.itemSubtitle,
  });

  @override
  State<_AdminSearchPickerSheet<T>> createState() =>
      _AdminSearchPickerSheetState<T>();
}

class _AdminSearchPickerSheetState<T>
    extends State<_AdminSearchPickerSheet<T>> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<T> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetch(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.loadItems(query.trim());
      if (!mounted) return;
      setState(() {
        _items = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _fetch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.darkTextMuted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: const TextStyle(color: AppColors.darkTextMuted),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.darkTextMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(color: AppColors.priceDown),
                            ),
                          ),
                        )
                      : _items.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy kết quả phù hợp',
                                style:
                                    TextStyle(color: AppColors.darkTextMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _items.length,
                              itemBuilder: (_, i) {
                                final item = _items[i];
                                return ListTile(
                                  title: Text(
                                    widget.itemTitle(item),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    widget.itemSubtitle(item),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(context, item),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}