import 'dart:async';
import 'dart:math';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Represents a failed SMS processing attempt
class FailedSmsProcessing {
  final String sender;
  final String body;
  final DateTime receivedAt;
  final int attemptCount;
  final String? lastError;
  final DateTime? nextRetryAt;

  FailedSmsProcessing({
    required this.sender,
    required this.body,
    required this.receivedAt,
    this.attemptCount = 0,
    this.lastError,
    this.nextRetryAt,
  });

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'body': body,
    'received_at': receivedAt.toIso8601String(),
    'attempt_count': attemptCount,
    'last_error': lastError,
    'next_retry_at': nextRetryAt?.toIso8601String(),
  };

  factory FailedSmsProcessing.fromJson(Map<String, dynamic> json) =>
      FailedSmsProcessing(
        sender: json['sender'] as String,
        body: json['body'] as String,
        receivedAt: DateTime.parse(json['received_at'] as String),
        attemptCount: json['attempt_count'] as int? ?? 0,
        lastError: json['last_error'] as String?,
        nextRetryAt: json['next_retry_at'] != null
            ? DateTime.tryParse(json['next_retry_at'] as String)
            : null,
      );

  FailedSmsProcessing copyWith({
    String? sender,
    String? body,
    DateTime? receivedAt,
    int? attemptCount,
    String? lastError,
    DateTime? nextRetryAt,
  }) => FailedSmsProcessing(
    sender: sender ?? this.sender,
    body: body ?? this.body,
    receivedAt: receivedAt ?? this.receivedAt,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError ?? this.lastError,
    nextRetryAt: nextRetryAt ?? this.nextRetryAt,
  );
}

/// Service for retrying failed SMS processing with exponential backoff
class SmsRetryService with Loggable {
  static const String _failedProcessingsKey = 'failed_sms_processings';
  static const int _maxRetryAttempts = 5;
  static const Duration _initialRetryDelay = Duration(minutes: 5);
  static const Duration _maxRetryDelay = Duration(hours: 24);

  final SharedPreferences _prefs;
  Timer? _retryTimer;

  SmsRetryService(this._prefs);

  /// Queue a failed SMS for retry
  Future<void> queueForRetry(String sender, String body, Object error) async {
    try {
      final failed = FailedSmsProcessing(
        sender: sender,
        body: body,
        receivedAt: DateTime.now(),
        attemptCount: 0,
        lastError: error.toString(),
      );

      final updated = failed.copyWith(
        attemptCount: 1,
        nextRetryAt: _calculateNextRetryTime(1),
      );

      await _addFailedProcessing(updated);
      logInfo(
        'Queued SMS for retry: sender=$sender, attempt=1, nextRetry=${updated.nextRetryAt}',
      );

      // Schedule retry check
      _scheduleRetryCheck();
    } catch (e, stackTrace) {
      logError(
        'Failed to queue SMS for retry',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get all failed processings ready for retry
  Future<List<FailedSmsProcessing>> getReadyForRetry() async {
    try {
      final all = await _getAllFailedProcessings();
      final now = DateTime.now();
      return all.where((f) {
        if (f.attemptCount >= _maxRetryAttempts) {
          return false; // Max attempts reached
        }
        if (f.nextRetryAt == null) {
          return true; // Ready immediately
        }
        return f.nextRetryAt!.isBefore(now) ||
            f.nextRetryAt!.isAtSameMomentAs(now);
      }).toList();
    } catch (e, stackTrace) {
      logError(
        'Failed to get ready for retry',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Mark a processing as successfully completed
  Future<void> markSuccess(String sender, String body) async {
    try {
      await _removeFailedProcessing(sender, body);
      logInfo('Marked SMS as successfully processed: sender=$sender');
    } catch (e, stackTrace) {
      logError(
        'Failed to mark SMS as success',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Increment retry attempt for a failed processing
  Future<void> incrementRetryAttempt(
    String sender,
    String body,
    Object error,
  ) async {
    try {
      final all = await _getAllFailedProcessings();
      final failed = all.firstWhere(
        (f) => f.sender == sender && f.body == body,
        orElse: () => FailedSmsProcessing(
          sender: sender,
          body: body,
          receivedAt: DateTime.now(),
        ),
      );

      final newAttemptCount = failed.attemptCount + 1;
      if (newAttemptCount >= _maxRetryAttempts) {
        // Max attempts reached, remove from queue
        await _removeFailedProcessing(sender, body);
        logWarning(
          'Max retry attempts reached for SMS: sender=$sender, removing from queue',
        );
        return;
      }

      final updated = failed.copyWith(
        attemptCount: newAttemptCount,
        nextRetryAt: _calculateNextRetryTime(newAttemptCount),
        lastError: error.toString(),
      );

      await _updateFailedProcessing(updated);
      logInfo(
        'Incremented retry attempt: sender=$sender, attempt=$newAttemptCount, nextRetry=${updated.nextRetryAt}',
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to increment retry attempt',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Calculate next retry time using exponential backoff
  DateTime _calculateNextRetryTime(int attemptCount) {
    // Exponential backoff: 5min, 15min, 45min, 2h, 6h, 24h (max)
    final baseDelay = _initialRetryDelay.inSeconds;
    final delaySeconds = min(
      baseDelay * pow(3, attemptCount - 1).toInt(),
      _maxRetryDelay.inSeconds,
    );
    return DateTime.now().add(Duration(seconds: delaySeconds));
  }

  /// Schedule a check for retries
  void _scheduleRetryCheck() {
    _retryTimer?.cancel();
    // Check every 5 minutes for ready retries
    _retryTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final ready = await getReadyForRetry();
      if (ready.isNotEmpty) {
        logInfo('Found ${ready.length} SMS ready for retry');
        // The actual retry will be handled by the SMS detection service
      }
    });
  }

  /// Get all failed processings
  Future<List<FailedSmsProcessing>> _getAllFailedProcessings() async {
    try {
      final json = _prefs.getString(_failedProcessingsKey);
      if (json == null || json.isEmpty) {
        return [];
      }
      final list = jsonDecode(json) as List;
      return list
          .map((e) => FailedSmsProcessing.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logWarning('Failed to get failed processings: $e');
      return [];
    }
  }

  /// Add a failed processing
  Future<void> _addFailedProcessing(FailedSmsProcessing failed) async {
    final all = await _getAllFailedProcessings();
    // Remove existing if any
    all.removeWhere((f) => f.sender == failed.sender && f.body == failed.body);
    all.add(failed);
    await _saveFailedProcessings(all);
  }

  /// Update a failed processing
  Future<void> _updateFailedProcessing(FailedSmsProcessing failed) async {
    final all = await _getAllFailedProcessings();
    final index = all.indexWhere(
      (f) => f.sender == failed.sender && f.body == failed.body,
    );
    if (index >= 0) {
      all[index] = failed;
      await _saveFailedProcessings(all);
    }
  }

  /// Remove a failed processing
  Future<void> _removeFailedProcessing(String sender, String body) async {
    final all = await _getAllFailedProcessings();
    all.removeWhere((f) => f.sender == sender && f.body == body);
    await _saveFailedProcessings(all);
  }

  /// Save all failed processings
  Future<void> _saveFailedProcessings(List<FailedSmsProcessing> all) async {
    final json = jsonEncode(all.map((f) => f.toJson()).toList());
    await _prefs.setString(_failedProcessingsKey, json);
  }

  /// Clear all failed processings
  Future<void> clearAll() async {
    await _prefs.remove(_failedProcessingsKey);
    logInfo('Cleared all failed SMS processings');
  }

  /// Dispose the service
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
