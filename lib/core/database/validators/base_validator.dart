/// Base validator with common validation utilities
abstract class BaseValidator {
  /// Validate that a string is not empty or just whitespace
  static void validateNonEmptyString(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError('$fieldName cannot be empty');
    }
  }

  /// Validate that a number is positive
  static void validatePositiveNumber(num value, String fieldName) {
    if (value <= 0) {
      throw ArgumentError('$fieldName must be greater than 0');
    }
  }

  /// Validate that a number is within a range
  static void validateNumberRange(
    num value,
    num min,
    num max,
    String fieldName,
  ) {
    if (value < min || value > max) {
      throw ArgumentError('$fieldName must be between $min and $max');
    }
  }

  /// Validate maximum string length
  static void validateMaxLength(String value, int maxLength, String fieldName) {
    if (value.length > maxLength) {
      throw ArgumentError('$fieldName must be $maxLength characters or less');
    }
  }

  /// Validate exact string length
  static void validateExactLength(
    String value,
    int length,
    String fieldName,
  ) {
    if (value.length != length) {
      throw ArgumentError('$fieldName must be exactly $length characters');
    }
  }

  /// Validate regex pattern
  static void validatePattern(
    String value,
    RegExp pattern,
    String fieldName,
    String errorMessage,
  ) {
    if (!pattern.hasMatch(value)) {
      throw ArgumentError('$fieldName: $errorMessage');
    }
  }
}
