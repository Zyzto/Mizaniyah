import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'package:mizaniyah/core/database/daos/pending_sms_confirmation_dao.dart';
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/services/sms_detection/sms_detection_constants.dart';
import 'dart:convert';

/// SMS detection statistics
class SmsDetectionStats {
  final int totalSmsProcessed;
  final int matchedCount;
  final int autoCreatedCount;
  final int pendingCount;
  final double averageConfidence;
  final Map<String, int> senderCounts;
  final Map<int, int> templateUsageCounts;
  final DateTime? lastProcessedAt;

  SmsDetectionStats({
    required this.totalSmsProcessed,
    required this.matchedCount,
    required this.autoCreatedCount,
    required this.pendingCount,
    required this.averageConfidence,
    required this.senderCounts,
    required this.templateUsageCounts,
    this.lastProcessedAt,
  });

  double get matchRate =>
      totalSmsProcessed > 0 ? matchedCount / totalSmsProcessed : 0.0;

  double get autoCreateRate =>
      matchedCount > 0 ? autoCreatedCount / matchedCount : 0.0;
}

/// Service for SMS detection analytics
class SmsAnalyticsService with Loggable {
  final PendingSmsConfirmationDao _pendingSmsDao;
  final TransactionDao _transactionDao;

  SmsAnalyticsService({
    required PendingSmsConfirmationDao pendingSmsDao,
    required TransactionDao transactionDao,
  }) : _pendingSmsDao = pendingSmsDao,
       _transactionDao = transactionDao;

  /// Get SMS detection statistics
  Future<SmsDetectionStats> getStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get all pending confirmations
      final pendingConfirmations = await _pendingSmsDao
          .getAllPendingConfirmations();

      // Get all SMS-created transactions
      final allTransactions = await _transactionDao.getAllTransactions();
      final smsTransactions = allTransactions
          .where((t) => t.source == SmsDetectionConstants.smsTransactionSource)
          .toList();

      // Filter by date range if provided
      List<db.PendingSmsConfirmation> filteredPending = pendingConfirmations;
      List<db.Transaction> filteredTransactions = smsTransactions;

      if (startDate != null || endDate != null) {
        if (startDate != null) {
          filteredPending = filteredPending
              .where((p) => p.createdAt.isAfter(startDate))
              .toList();
          filteredTransactions = filteredTransactions
              .where((t) => t.date.isAfter(startDate))
              .toList();
        }
        if (endDate != null) {
          filteredPending = filteredPending
              .where((p) => p.createdAt.isBefore(endDate))
              .toList();
          filteredTransactions = filteredTransactions
              .where((t) => t.date.isBefore(endDate))
              .toList();
        }
      }

      // Calculate statistics
      final totalProcessed =
          filteredPending.length + filteredTransactions.length;
      final matchedCount =
          totalProcessed; // All pending + transactions are matched
      final autoCreatedCount = filteredTransactions.length;
      final pendingCount = filteredPending.length;

      // Calculate average confidence from pending confirmations
      double totalConfidence = 0.0;
      int confidenceCount = 0;
      final senderCounts = <String, int>{};
      final templateUsageCounts = <int, int>{};

      for (final confirmation in filteredPending) {
        try {
          final parsedDataJson =
              jsonDecode(confirmation.parsedData) as Map<String, dynamic>;
          final confidence = parsedDataJson['confidence'] as double?;
          if (confidence != null) {
            totalConfidence += confidence;
            confidenceCount++;
          }

          // Count senders
          final sender = confirmation.smsSender;
          senderCounts[sender] = (senderCounts[sender] ?? 0) + 1;
        } catch (e) {
          logWarning('Failed to parse confirmation data: $e');
        }
      }

      // Count senders from transactions (if we stored sender info)
      for (final transaction in filteredTransactions) {
        // Note: We'd need to store sender in transaction notes or separate field
        // For now, we'll use store name as proxy
        final storeName = transaction.storeName;
        if (storeName.isNotEmpty) {
          senderCounts[storeName] = (senderCounts[storeName] ?? 0) + 1;
        }
      }

      final averageConfidence = confidenceCount > 0
          ? totalConfidence / confidenceCount
          : 0.0;

      // Get last processed date
      DateTime? lastProcessedAt;
      if (filteredPending.isNotEmpty) {
        final lastPending = filteredPending.reduce(
          (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
        );
        lastProcessedAt = lastPending.createdAt;
      }
      if (filteredTransactions.isNotEmpty) {
        final lastTransaction = filteredTransactions.reduce(
          (a, b) => a.date.isAfter(b.date) ? a : b,
        );
        if (lastProcessedAt == null ||
            lastTransaction.date.isAfter(lastProcessedAt)) {
          lastProcessedAt = lastTransaction.date;
        }
      }

      return SmsDetectionStats(
        totalSmsProcessed: totalProcessed,
        matchedCount: matchedCount,
        autoCreatedCount: autoCreatedCount,
        pendingCount: pendingCount,
        averageConfidence: averageConfidence,
        senderCounts: senderCounts,
        templateUsageCounts: templateUsageCounts,
        lastProcessedAt: lastProcessedAt,
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to get SMS detection stats',
        error: e,
        stackTrace: stackTrace,
      );
      return SmsDetectionStats(
        totalSmsProcessed: 0,
        matchedCount: 0,
        autoCreatedCount: 0,
        pendingCount: 0,
        averageConfidence: 0.0,
        senderCounts: {},
        templateUsageCounts: {},
      );
    }
  }

  /// Get confidence distribution
  Future<Map<String, int>> getConfidenceDistribution() async {
    try {
      final confirmations = await _pendingSmsDao.getAllPendingConfirmations();
      final distribution = <String, int>{
        'high': 0, // >= 0.7
        'medium': 0, // 0.5 - 0.7
        'low': 0, // < 0.5
      };

      for (final confirmation in confirmations) {
        try {
          final parsedDataJson =
              jsonDecode(confirmation.parsedData) as Map<String, dynamic>;
          final confidence = parsedDataJson['confidence'] as double? ?? 0.0;

          if (confidence >= 0.7) {
            distribution['high'] = (distribution['high'] ?? 0) + 1;
          } else if (confidence >= 0.5) {
            distribution['medium'] = (distribution['medium'] ?? 0) + 1;
          } else {
            distribution['low'] = (distribution['low'] ?? 0) + 1;
          }
        } catch (e) {
          // Skip invalid data
        }
      }

      return distribution;
    } catch (e, stackTrace) {
      logError(
        'Failed to get confidence distribution',
        error: e,
        stackTrace: stackTrace,
      );
      return {'high': 0, 'medium': 0, 'low': 0};
    }
  }

  /// Get most common senders
  Future<List<({String sender, int count})>> getTopSenders({
    int limit = 10,
  }) async {
    try {
      final stats = await getStats();
      final senders = stats.senderCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return senders
          .take(limit)
          .map((e) => (sender: e.key, count: e.value))
          .toList();
    } catch (e, stackTrace) {
      logError('Failed to get top senders', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
