import 'dart:async';
import 'package:flutter_logging_service/flutter_logging_service.dart' show Log;

/// Helper class for fire-and-forget logging
/// Ensures logging doesn't block database operations, SMS processing, or UI rendering
class LoggingHelper {
  /// Fire-and-forget info logging
  static void logInfo(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Schedule logging on next microtask to avoid blocking
    scheduleMicrotask(() {
      try {
        Log.info(
          message,
          error: error,
          stackTrace: stackTrace,
        );
      } catch (e) {
        // Silently fail - logging should never break the app
      }
    });
  }

  /// Fire-and-forget debug logging
  static void logDebug(String message, {String? component}) {
    scheduleMicrotask(() {
      try {
        Log.debug(message);
      } catch (e) {
        // Silently fail
      }
    });
  }

  /// Fire-and-forget warning logging
  static void logWarning(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    scheduleMicrotask(() {
      try {
        Log.warning(
          message,
          error: error,
          stackTrace: stackTrace,
        );
      } catch (e) {
        // Silently fail
      }
    });
  }

  /// Fire-and-forget error logging
  static void logError(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    scheduleMicrotask(() {
      try {
        Log.error(
          message,
          error: error,
          stackTrace: stackTrace,
        );
      } catch (e) {
        // Silently fail
      }
    });
  }

  /// Fire-and-forget severe logging
  static void logSevere(
    String message, {
    String? component,
    Object? error,
    StackTrace? stackTrace,
  }) {
    scheduleMicrotask(() {
      try {
        Log.severe(
          message,
          error: error,
          stackTrace: stackTrace,
        );
      } catch (e) {
        // Silently fail
      }
    });
  }
}
