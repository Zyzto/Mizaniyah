import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'error_handler_provider.g.dart';

/// Global error handler for Riverpod providers
/// Logs all provider errors to Siglat and provides user-friendly error messages
@riverpod
class ErrorHandler extends _$ErrorHandler {
  @override
  void build() {
    // Error handler doesn't need initial state
  }

  /// Handle and log a provider error
  void handleError(
    Object error,
    StackTrace? stackTrace, {
    String? component,
    String? userMessage,
  }) {
    // Log to Siglat
    Log.error(
      userMessage ?? 'An error occurred',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Get user-friendly error message
  String getUserFriendlyMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('sqlite') ||
        errorString.contains('drift')) {
      return 'Database error occurred. Please try again.';
    }

    // Network errors (for future use)
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Network error. Please check your connection.';
    }

    // Permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Permission denied. Please grant required permissions.';
    }

    // Generic error
    return 'An unexpected error occurred. Please try again.';
  }
}
