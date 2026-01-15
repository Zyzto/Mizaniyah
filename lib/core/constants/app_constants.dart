/// Application-wide constants
/// Centralizes magic numbers and configuration values
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  /// Database batch operations
  static const int databaseBatchSize = 100;

  /// Database cache sizes (in KB, negative values mean pages)
  static const int databaseCacheSizePages = -64000; // 64MB cache
  static const int databaseMmapSizeBytes = 268435456; // 256MB memory-mapped I/O

  /// Notification constants
  static const String notificationChannelSmsTransactions = 'sms_transactions';
  static const String notificationChannelSmsTransactionsName =
      'SMS Transactions';

  /// Text field length limits
  static const int maxAccountNameLength = 100;
  static const int maxCardNameLength = 100;
  static const int maxCategoryNameLength = 100;
  static const int maxStoreNameLength = 200;

  /// Currency code length (ISO 4217)
  static const int currencyCodeLength = 3;

  /// Default values
  static const double defaultCurrencyAmount = 0.0;
  static const int defaultSortOrder = 0;

  /// UI constants
  static const double bottomNavBarHeight = 100.0;
  static const double skeletonLineHeight = 12.0;
  static const double skeletonLineWidth = 100.0;
  static const double skeletonItemHeight = 100.0;
}

/// Database-specific constants
class DatabaseConstants {
  DatabaseConstants._();

  /// SQLite PRAGMA settings
  static const String journalMode = 'WAL'; // Write-Ahead Logging
  static const String synchronousMode = 'NORMAL';
  static const String tempStore = 'MEMORY';
}

/// Notification-specific constants
class NotificationConstants {
  NotificationConstants._();

  /// Notification types
  static const String typeSmsConfirmation = 'sms_confirmation';
  static const String typeTransactionCreated = 'transaction_created';

  /// Notification payload prefixes
  static const String payloadSmsConfirmationPrefix = 'sms_confirmation:';
}
