import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'app_database.dart' as db;
import '../constants/app_constants.dart';

/// Service for batch database operations
/// Optimizes bulk inserts/updates by using Drift's batch API
class DatabaseBatchOperations with Loggable {
  final db.AppDatabase _database;

  DatabaseBatchOperations(this._database);

  /// Batch insert transactions (optimized with single transaction using batch API)
  Future<List<int>> batchInsertTransactions(
    List<db.TransactionsCompanion> transactions,
  ) async {
    logDebug('batchInsertTransactions(count=${transactions.length}) called');
    if (transactions.isEmpty) {
      return [];
    }

    try {
      final ids = <int>[];
      await _database.batch((batch) {
        for (final transaction in transactions) {
          batch.insert(_database.transactions, transaction);
        }
      });
      // Get IDs by querying the inserted transactions
      // Note: This is a limitation - we can't get IDs directly from batch.insert
      // For now, we'll return empty list and caller should query for IDs if needed
      // TODO: Consider using individual inserts if IDs are needed
      logInfo(
        'batchInsertTransactions() inserted ${transactions.length} transactions',
      );
      return ids;
    } catch (e, stackTrace) {
      logError(
        'batchInsertTransactions() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Batch update transactions (optimized with single transaction using batch API)
  Future<int> batchUpdateTransactions(
    List<db.TransactionsCompanion> transactions,
  ) async {
    logDebug('batchUpdateTransactions(count=${transactions.length}) called');
    if (transactions.isEmpty) {
      return 0;
    }

    try {
      int updated = 0;
      await _database.batch((batch) {
        for (final transaction in transactions) {
          if (transaction.id.present) {
            batch.update(_database.transactions, transaction);
            updated++;
          }
        }
      });
      logInfo('batchUpdateTransactions() updated $updated transactions');
      return updated;
    } catch (e, stackTrace) {
      logError(
        'batchUpdateTransactions() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Batch delete transactions by IDs (optimized with single transaction using batch API)
  Future<int> batchDeleteTransactions(List<int> ids) async {
    logDebug('batchDeleteTransactions(count=${ids.length}) called');
    if (ids.isEmpty) {
      return 0;
    }

    try {
      // Use individual deletes within a batch transaction for better performance
      // Note: Drift's batch doesn't have deleteWhere, so we use customStatement
      int deleted = 0;
      await _database.batch((batch) {
        for (final id in ids) {
          batch.customStatement('DELETE FROM transactions WHERE id = ?', [id]);
          deleted++;
        }
      });
      logInfo('batchDeleteTransactions() deleted $deleted transactions');
      return deleted;
    } catch (e, stackTrace) {
      logError(
        'batchDeleteTransactions() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Bulk insert with optimized batch size
  /// Splits large batches into chunks to avoid memory issues
  Future<List<int>> bulkInsertTransactions(
    List<db.TransactionsCompanion> transactions, {
    int batchSize = AppConstants.databaseBatchSize,
  }) async {
    logDebug(
      'bulkInsertTransactions(total=${transactions.length}, batchSize=$batchSize) called',
    );
    if (transactions.isEmpty) {
      return [];
    }

    try {
      final allIds = <int>[];
      for (var i = 0; i < transactions.length; i += batchSize) {
        final batch = transactions.sublist(
          i,
          i + batchSize > transactions.length
              ? transactions.length
              : i + batchSize,
        );
        final batchIds = await batchInsertTransactions(batch);
        allIds.addAll(batchIds);
      }
      logInfo(
        'bulkInsertTransactions() inserted ${transactions.length} transactions in ${(transactions.length / batchSize).ceil()} batches',
      );
      return allIds;
    } catch (e, stackTrace) {
      logError(
        'bulkInsertTransactions() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
