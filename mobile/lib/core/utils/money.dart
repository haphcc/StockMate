import 'package:equatable/equatable.dart';

class Money extends Equatable implements Comparable<Money> {
  final int cents;

  const Money.fromCents(this.cents);

  factory Money.zero() => const Money.fromCents(0);

  factory Money.parse(Object? value) {
    if (value == null) return Money.zero();
    final raw = value.toString().trim().replaceAll(',', '');
    final match = RegExp(r'^([+-]?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(raw);
    if (match == null) throw FormatException('Invalid money value: $value');
    final sign = match.group(1) == '-' ? -1 : 1;
    final whole = int.parse(match.group(2)!);
    final fraction = (match.group(3) ?? '').padRight(2, '0');
    return Money.fromCents(sign * (whole * 100 + int.parse(fraction)));
  }

  Money operator +(Money other) => Money.fromCents(cents + other.cents);
  Money operator -(Money other) => Money.fromCents(cents - other.cents);
  Money operator -() => Money.fromCents(-cents);

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  String get decimalString {
    final sign = cents < 0 ? '-' : '';
    final value = cents.abs();
    return '$sign${value ~/ 100}.${(value % 100).toString().padLeft(2, '0')}';
  }

  String formatVnd() {
    final sign = cents < 0 ? '-' : '';
    final value = cents.abs();
    final whole = (value ~/ 100).toString();
    final grouped = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return '$sign$grouped₫';
  }

  @override
  List<Object?> get props => [cents];

  @override
  String toString() => decimalString;
}
