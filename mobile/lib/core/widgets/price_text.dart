import 'package:flutter/material.dart';
import '../theme/price_colors.dart';

class PriceText extends StatelessWidget {
  final String text;
  final PriceState state;
  final TextStyle? style;

  const PriceText({
    super.key,
    required this.text,
    required this.state,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final priceColors = Theme.of(context).extension<PriceColors>() ?? PriceColors.defaultColors;
    Color color;

    switch (state) {
      case PriceState.ceiling:
        color = priceColors.ceiling;
        break;
      case PriceState.floor:
        color = priceColors.floor;
        break;
      case PriceState.reference:
        color = priceColors.reference;
        break;
      case PriceState.up:
        color = priceColors.up;
        break;
      case PriceState.down:
        color = priceColors.down;
        break;
    }

    return Text(
      text,
      style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(color: color),
    );
  }
}
