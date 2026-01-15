/// Constants for SMS detection service
class SmsDetectionConstants {
  /// Default minimum confidence score (0.0-1.0) required for auto-creating transactions
  /// This is a fallback - actual threshold comes from user settings
  static const double defaultAutoCreateConfidenceThreshold = 0.7;

  /// Get the auto-create confidence threshold
  /// This should be overridden by user settings in production
  static double getAutoCreateConfidenceThreshold([double? userThreshold]) {
    return userThreshold ?? defaultAutoCreateConfidenceThreshold;
  }

  /// Hours until pending confirmation expires
  static const int confirmationExpirationHours = 24;

  /// Default currency when none is detected
  static const String defaultCurrency = 'USD';

  /// Transaction source identifier for SMS-created transactions
  static const String smsTransactionSource = 'sms';
}
