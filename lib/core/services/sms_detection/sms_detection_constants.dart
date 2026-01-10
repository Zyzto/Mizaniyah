/// Constants for SMS detection service
class SmsDetectionConstants {
  /// Minimum confidence score (0.0-1.0) required for auto-creating transactions
  static const double autoCreateConfidenceThreshold = 0.7;

  /// Hours until pending confirmation expires
  static const int confirmationExpirationHours = 24;

  /// Default currency when none is detected
  static const String defaultCurrency = 'USD';

  /// Transaction source identifier for SMS-created transactions
  static const String smsTransactionSource = 'sms';
}
