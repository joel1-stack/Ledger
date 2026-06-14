import 'package:intl/intl.dart';

class CurrencyFormat {
  static String format(double amount) {
    final format = NumberFormat('#,##0', 'en-KE');
    return 'KES ${format.format(amount)}';
  }

  static String formatShort(double amount) {
    if (amount >= 1000000) {
      return 'KES ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'KES ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'KES ${amount.toStringAsFixed(0)}';
  }
}
