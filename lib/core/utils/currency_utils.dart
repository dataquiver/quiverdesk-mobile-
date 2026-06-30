import 'package:intl/intl.dart';

class QDCurrency {
  static final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _inrDecimal = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static String format(double amount, {bool showDecimals = false}) =>
      showDecimals ? _inrDecimal.format(amount) : _inr.format(amount);

  static String compact(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return format(amount);
  }
}
