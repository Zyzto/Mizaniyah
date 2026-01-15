import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/services/sms_parsing_service.dart';

/// Enhanced error handling for SMS detection with graceful degradation
class SmsDetectionErrorHandler {
  /// Handle parsing errors gracefully
  /// Returns partial ParsedSmsData if possible, null otherwise
  static ParsedSmsData? handleParsingError(
    String smsBody,
    String sender,
    Object error,
    StackTrace stackTrace,
  ) {
    Log.error(
      'SMS parsing error for sender: $sender',
      error: error,
      stackTrace: stackTrace,
    );

    // Try to extract basic information even if parsing fails
    try {
      // Attempt to extract amount using simple regex
      final amountPattern = RegExp(r'[\d,]+\.?\d*');
      final amountMatch = amountPattern.firstMatch(smsBody);
      double? amount;
      if (amountMatch != null) {
        final amountStr = amountMatch.group(0)?.replaceAll(',', '');
        amount = double.tryParse(amountStr ?? '');
      }

      // Try to extract store name (look for common patterns)
      String? storeName;
      // Look for text before amount or after common prefixes
      final storePatterns = [
        RegExp(r'at\s+([A-Z][A-Z\s]+)', caseSensitive: false),
        RegExp(r'from\s+([A-Z][A-Z\s]+)', caseSensitive: false),
        RegExp(r'([A-Z][A-Z\s]{3,})', caseSensitive: false),
      ];

      for (final pattern in storePatterns) {
        final match = pattern.firstMatch(smsBody);
        if (match != null && match.groupCount > 0) {
          storeName = match.group(1)?.trim();
          if (storeName != null && storeName.length >= 3) {
            break;
          }
        }
      }

      // If we got at least amount, create partial data
      if (amount != null && amount > 0) {
        Log.info(
          'Partial data extracted: amount=$amount, storeName=$storeName',
        );
        return ParsedSmsData(
          storeName: storeName ?? 'Unknown Store',
          amount: amount,
          currency: 'USD', // Default currency
          smsSender: sender,
          smsBody: smsBody,
        );
      }
    } catch (e) {
      Log.warning('Failed to extract partial data: $e');
    }

    return null;
  }

  /// Get user-friendly error message
  static String getUserFriendlyErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission')) {
      return 'SMS permission required. Please enable SMS access in app settings.';
    }

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Connection error. Please check your internet connection.';
    }

    if (errorStr.contains('database') || errorStr.contains('sql')) {
      return 'Database error. Please try again or restart the app.';
    }

    if (errorStr.contains('parse') || errorStr.contains('format')) {
      return 'Unable to parse SMS. The message format may not be supported.';
    }

    if (errorStr.contains('duplicate')) {
      return 'This transaction already exists.';
    }

    // Generic error message
    return 'An error occurred while processing the SMS. Please try again.';
  }

  /// Check if error is recoverable
  static bool isRecoverableError(Object error) {
    final errorStr = error.toString().toLowerCase();

    // Non-recoverable errors
    if (errorStr.contains('permission denied')) {
      return false;
    }

    if (errorStr.contains('invalid') && errorStr.contains('format')) {
      return false;
    }

    // Most other errors are recoverable
    return true;
  }

  /// Log error with context
  static void logErrorWithContext(
    String context,
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? additionalInfo,
  }) {
    final message = 'Error in $context';
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      Log.error(
        '$message - Additional info: $additionalInfo',
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      Log.error(message, error: error, stackTrace: stackTrace);
    }
  }
}
