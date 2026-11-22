import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stockmate_brand.dart';

class MarketHeader extends StatelessWidget {
  const MarketHeader({super.key, this.onNotifications, this.trailing});
  final VoidCallback? onNotifications;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
    child: Row(
      children: [
        const StockMateBrand(iconSize: 26, fontSize: 17),
        const Spacer(),
        ?trailing,
        if (onNotifications != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onNotifications,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 23,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.darkCard,
              fixedSize: const Size(42, 42),
            ),
          ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      if (action != null)
        TextButton(
          onPressed: onTap,
          child: Text(
            action!,
            style: const TextStyle(color: AppColors.primary, fontSize: 12),
          ),
        ),
    ],
  );
}

class MarketPanel extends StatelessWidget {
  const MarketPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.darkCardBorder),
    ),
    child: child,
  );
}

class SymbolBadge extends StatelessWidget {
  const SymbolBadge(this.symbol, {super.key, this.size = 44});
  final String symbol;
  final double size;
  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF173C35),
      Color(0xFF30254B),
      Color(0xFF3A2D1B),
      Color(0xFF1C3448),
    ];
    final index =
        symbol.codeUnits.fold<int>(0, (sum, value) => sum + value) %
        colors.length;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors[index],
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class ChangeLabel extends StatelessWidget {
  const ChangeLabel({
    super.key,
    required this.change,
    required this.percent,
    required this.color,
    this.compact = false,
  });
  final String change;
  final String percent;
  final Color color;
  final bool compact;
  @override
  Widget build(BuildContext context) => Text(
    '$change  $percent',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: color,
      fontSize: compact ? 11 : 13,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: .14)
            : AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: .5)
              : AppColors.darkCardBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.darkTextSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ),
  );
}
