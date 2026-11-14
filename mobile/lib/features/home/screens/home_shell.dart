import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _destinations = <_Destination>[
    _Destination(Icons.show_chart_rounded, 'Thị trường'),
    _Destination(Icons.bookmark_border_rounded, 'Theo dõi'),
    _Destination(Icons.swap_horiz_rounded, 'Đặt lệnh'),
    _Destination(Icons.receipt_long_rounded, 'Sổ lệnh'),
    _Destination(Icons.pie_chart_outline_rounded, 'Tài sản'),
    _Destination(Icons.admin_panel_settings_outlined, 'Quản trị'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authProvider).value?.isAdmin ?? false;
    final count = isAdmin ? 6 : 5;
    final index = navigationShell.currentIndex.clamp(0, count - 1).toInt();
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xF2131926),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: Row(
                  children: List.generate(count, (itemIndex) {
                    final destination = _destinations[itemIndex];
                    final selected = index == itemIndex;
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!selected) HapticFeedback.selectionClick();
                          navigationShell.goBranch(
                            itemIndex,
                            initialLocation:
                                itemIndex == navigationShell.currentIndex,
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 36,
                              height: 32,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                destination.icon,
                                size: 20,
                                color: selected
                                    ? const Color(0xFF06251C)
                                    : AppColors.darkTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              destination.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.darkTextSecondary,
                                fontSize: 9,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.label);
  final IconData icon;
  final String label;
}
