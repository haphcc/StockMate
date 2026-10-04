import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      icon: Icons.trending_up_rounded,
      activeIcon: Icons.trending_up_rounded,
      label: 'Thị trường',
    ),
    _NavDestination(
      icon: Icons.receipt_long_rounded,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Sổ lệnh',
    ),
    _NavDestination(
      icon: Icons.bolt_rounded,
      activeIcon: Icons.bolt_rounded,
      label: 'Đặt lệnh',
    ),
    _NavDestination(
      icon: Icons.pie_chart_outline_rounded,
      activeIcon: Icons.pie_chart_rounded,
      label: 'Danh mục',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.2,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth / _destinations.length;
                      const indicatorSize = 38.0;

                      return Stack(
                        children: [
                          // Animated Sliding Indicator (Vòng tròn / Pill xanh di chuyển mượt mà giữa các tab)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            left: currentIndex * itemWidth + (itemWidth - indicatorSize) / 2,
                            top: 6,
                            child: Container(
                              width: indicatorSize,
                              height: indicatorSize,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF00E6A8),
                                    Color(0xFF00C896),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.45),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Tab items
                          Row(
                            children: List.generate(_destinations.length, (index) {
                              final item = _destinations[index];
                              final isSelected = index == currentIndex;

                              return Expanded(
                                child: _NavBarItem(
                                  item: item,
                                  isSelected: isSelected,
                                  onTap: () {
                                    if (!isSelected) {
                                      HapticFeedback.selectionClick();
                                      navigationShell.goBranch(
                                        index,
                                        initialLocation: index == navigationShell.currentIndex,
                                      );
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavBarItem extends StatelessWidget {
  final _NavDestination item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              // Icon container khớp với kích thước của sliding indicator
              SizedBox(
                width: 38,
                height: 38,
                child: Center(
                  child: AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: isSelected ? 23 : 22,
                      color: isSelected
                          ? const Color(0xFF032617) // Tương phản rõ nét trên nền xanh ngọc
                          : const Color(0xFF94A3B8), // Slate gray tinh tế khi chưa chọn
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Text label với animation chuyển màu & font weight mượt mà
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'Be Vietnam Pro',
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
