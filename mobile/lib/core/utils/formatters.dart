import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _percentFormat = NumberFormat.decimalPattern('vi_VN');

  static String formatCurrency(int amount) {
    return _currencyFormat.format(amount);
  }

  static String formatPrice(num price) {
    final format = NumberFormat("#,##0.00", "vi_VN");
    return format.format(price);
  }

  static String formatPercent(double percent) {
    final sign = percent > 0 ? '+' : '';
    return '$sign${_percentFormat.format(percent)}%';
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
