import 'package:intl/intl.dart';

/// Centralized currency formatting utility
/// Ensures consistent currency display across the app
class CurrencyFormatter {
  /// Format amount with currency code
  /// Example: format(100.5, 'USD') -> "100.50 USD"
  static String format(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );
    return '${formatter.format(amount)} $currencyCode';
  }

  /// Format amount with currency code and symbol
  /// Example: formatWithSymbol(100.5, 'USD') -> "$100.50"
  static String formatWithSymbol(double amount, String currencyCode) {
    // For now, just return formatted amount with code
    // Can be enhanced later with currency symbols
    return format(amount, currencyCode);
  }

  /// Format amount for compact display (no currency code)
  /// Example: formatCompact(100.5) -> "100.50"
  static String formatCompact(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
