import 'package:flutter_logging_service/flutter_logging_service.dart';

/// Base mixin for common DAO operations
/// Provides standardized error handling and validation patterns
mixin BaseDaoMixin on Loggable {
  /// Execute a database operation with standardized error handling
  Future<T> executeWithErrorHandling<T>({
    required String operationName,
    required Future<T> Function() operation,
    T? Function()? onError,
  }) async {
    logDebug('$operationName() called');
    try {
      final result = await operation();
      logInfo('$operationName() completed successfully');
      return result;
    } catch (e, stackTrace) {
      logError('$operationName() failed', error: e, stackTrace: stackTrace);
      if (onError != null) {
        return onError() as T;
      }
      rethrow;
    }
  }

  /// Validate that a string is not empty or just whitespace
  void validateNonEmptyString(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError('$fieldName cannot be empty');
    }
  }

  /// Validate that a number is positive
  void validatePositiveNumber(num value, String fieldName) {
    if (value <= 0) {
      throw ArgumentError('$fieldName must be greater than 0');
    }
  }

  /// Validate that a number is within a range
  void validateNumberRange(num value, num min, num max, String fieldName) {
    if (value < min || value > max) {
      throw ArgumentError('$fieldName must be between $min and $max');
    }
  }
}
