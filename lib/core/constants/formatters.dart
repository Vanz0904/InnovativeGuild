import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormat = NumberFormat.decimalPattern('en_US');

  static String currency(double amount, {String symbol = 'MWK'}) {
    return '$symbol ${_currencyFormat.format(amount)}';
  }

  static String compactCurrency(double amount, {String symbol = 'MWK'}) {
    if (amount >= 1000000) {
      return '$symbol ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$symbol ${amount.toStringAsFixed(0)}';
  }

  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }

  static String date(DateTime dateTime) => DateFormat('MMM d, yyyy').format(dateTime);

  static String dateTime(DateTime dateTime) => DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
}
