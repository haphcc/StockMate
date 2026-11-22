import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/admin_constants.dart';
import '../data/models/admin_customer_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminNotificationComposeScreen extends ConsumerStatefulWidget {
  /// Khách hàng chọn sẵn (khi mở từ màn hình chi tiết khách hàng).
  final AdminCustomerModel? presetCustomer;

  const AdminNotificationComposeScreen({super.key, this.presetCustomer});

  @override
  ConsumerState<AdminNotificationComposeScreen> createState() =>
      _AdminNotificationComposeScreenState();
}

class _AdminNotificationComposeScreenState
    extends ConsumerState<AdminNotificationComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  late bool _broadcast;
  AdminCustomerModel? _customer;
  String _type = 'SYSTEM';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.presetCustomer;
    _broadcast = widget.presetCustomer == null;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final repo = ref.read(adminRepositoryProvider);
    try {
      final page = await repo.listCustomers(pageSize: 100);
      if (!mounted) return;
      final picked = await showModalBottomSheet<AdminCustomerModel>(
        context: context,
        backgroundColor: AppColors.darkSurface,
        builder: (sheetContext) => ListView(
          children: [
            for (final c in page.items)
              ListTile(
                title: Text(
                  c.fullName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  c.email,
                  style: const TextStyle(color: AppColors.darkTextSecondary),
                ),
                onTap: () => Navigator.pop(sheetContext, c),
              ),
          ],
        ),
      );
      if (picked != null && mounted) setState(() => _customer = picked);
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  /// Lấy phần trong ngoặc vuông, ví dụ "Broadcast đến 9 khách hàng".
  String _summary(String content) {
    final end = content.indexOf(']');
    if (content.startsWith('[') && end > 1) return content.substring(1, end);
    return 'thông báo';
  }

  Future<void> _submit() async {
    if (!_broadcast && _customer == null) {
      showAdminSnack(context, 'Hãy chọn khách hàng nhận thông báo', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_broadcast) {
      final ok = await showAdminConfirm(
        context,
        title: 'Gửi cho tất cả khách hàng',
        message: 'Thông báo sẽ được gửi tới toàn bộ khách hàng đang hoạt động. '
            'Mỗi người nhận một bản riêng và không thể thu hồi hàng loạt. '
            'Tiếp tục?',
        confirmText: 'Gửi',
        danger: true,
      );
      if (!ok) return;
    }
    setState(() => _saving = true);
    try {
      final result = await ref.read(adminRepositoryProvider).sendNotification({
        'customer_id': _broadcast ? null : _customer!.customerId,
        'title': _title.text.trim(),
        'content': _content.text.trim(),
        'notification_type': _type,
      });
      if (!mounted) return;
      showAdminSnack(
        context,
        _broadcast
            ? 'Đã gửi: ${_summary(result.content)}'
            : 'Đã gửi cho ${result.customerName}',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Soạn thông báo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionLabel('Người nhận'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  'Tất cả khách hàng',
                  _broadcast,
                  () => setState(() => _broadcast = true),
                ),
                _chip(
                  'Một khách hàng',
                  !_broadcast,
                  () => setState(() => _broadcast = false),
                ),
              ],
            ),
            if (!_broadcast) ...[
              const SizedBox(height: 12),
              AdminCard(
                onTap: _saving ? null : _pickCustomer,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _customer == null
                            ? 'Chọn khách hàng...'
                            : '${_customer!.fullName} · ${_customer!.email}',
                        style: TextStyle(
                          color: _customer == null
                              ? AppColors.darkTextMuted
                              : Colors.white,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.darkTextMuted,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            _sectionLabel('Loại thông báo'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in AdminConstants.notificationTypes)
                  _chip(
                    AdminConstants.label(type),
                    _type == type,
                    () => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              labelText: 'Tiêu đề',
              controller: _title,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.length < 2) return 'Tiêu đề tối thiểu 2 ký tự';
                if (value.length > 200) return 'Tiêu đề tối đa 200 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _sectionLabel('Nội dung'),
            TextFormField(
              controller: _content,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              validator: (v) => (v ?? '').trim().length < 2
                  ? 'Nội dung tối thiểu 2 ký tự'
                  : null,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung thông báo',
                hintStyle: const TextStyle(
                  color: AppColors.darkTextMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.darkInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.darkInputBorder),
                ),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: _broadcast ? 'Gửi cho tất cả khách hàng' : 'Gửi thông báo',
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.darkCard,
      side: const BorderSide(color: AppColors.darkBorder),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF052B19) : AppColors.darkTextSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}