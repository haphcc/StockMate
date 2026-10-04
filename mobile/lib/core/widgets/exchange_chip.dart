import 'package:flutter/material.dart';

class ExchangeChip extends StatelessWidget {
  final String exchange;

  const ExchangeChip({super.key, required this.exchange});

  @override
  Widget build(BuildContext context) {
    Color bgColor;

    switch (exchange.toUpperCase()) {
      case 'HOSE':
        bgColor = const Color(0xFF00C896); // Emerald
        break;
      case 'HNX':
        bgColor = const Color(0xFF3B82F6); // Blue
        break;
      case 'UPCOM':
        bgColor = const Color(0xFF8B5CF6); // Purple
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: bgColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        exchange.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: bgColor),
      ),
    );
  }
}
