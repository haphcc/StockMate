import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/core/utils/money.dart';

void main() {
  group('Money', () {
    test('parses whole and decimal values into cents', () {
      expect(Money.parse('1,234.5').cents, 123450);
      expect(Money.parse('-0.01').cents, -1);
    });

    test('rejects malformed values', () {
      expect(() => Money.parse('12.345'), throwsFormatException);
      expect(() => Money.parse('VND 100'), throwsFormatException);
    });

    test('adds and subtracts precisely', () {
      final total =
          Money.parse('1.20') + Money.parse('2.35') - Money.parse('0.05');
      expect(total.decimalString, '3.50');
    });

    test('formats VND without fractional cents', () {
      expect(Money.parse('1234567.89').formatVnd(), '1.234.567₫');
      expect(Money.parse('-1000').formatVnd(), '-1.000₫');
    });
  });
}
