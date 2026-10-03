import 'package:flutter/material.dart';
import 'app_colors.dart';

enum PriceState { ceiling, floor, reference, up, down }

class PriceColors extends ThemeExtension<PriceColors> {
  final Color ceiling;
  final Color floor;
  final Color reference;
  final Color up;
  final Color down;

  const PriceColors({
    required this.ceiling,
    required this.floor,
    required this.reference,
    required this.up,
    required this.down,
  });

  @override
  ThemeExtension<PriceColors> copyWith({
    Color? ceiling,
    Color? floor,
    Color? reference,
    Color? up,
    Color? down,
  }) {
    return PriceColors(
      ceiling: ceiling ?? this.ceiling,
      floor: floor ?? this.floor,
      reference: reference ?? this.reference,
      up: up ?? this.up,
      down: down ?? this.down,
    );
  }

  @override
  ThemeExtension<PriceColors> lerp(ThemeExtension<PriceColors>? other, double t) {
    if (other is! PriceColors) {
      return this;
    }
    return PriceColors(
      ceiling: Color.lerp(ceiling, other.ceiling, t)!,
      floor: Color.lerp(floor, other.floor, t)!,
      reference: Color.lerp(reference, other.reference, t)!,
      up: Color.lerp(up, other.up, t)!,
      down: Color.lerp(down, other.down, t)!,
    );
  }

  static const defaultColors = PriceColors(
    ceiling: AppColors.priceCeiling,
    floor: AppColors.priceFloor,
    reference: AppColors.priceRef,
    up: AppColors.priceUp,
    down: AppColors.priceDown,
  );
}
