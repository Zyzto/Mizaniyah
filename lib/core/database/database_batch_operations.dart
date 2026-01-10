import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'app_database.dart' as db;
import 'database_transaction_helper.dart';

/// Service for batch database operations
/// Optimizes bulk inserts/updates by using transactions
class DatabaseBatchOperations with Loggable {
  final db.AppDatabase _database;
  final DatabaseTransactionHelper _transactionHelper;

  DatabaseBatchOperations(this._database)
      : _transactionHelper = DatabaseTransactionHelper(_database);

  /// Batch insert transactions (optimized with single transaction)
  Future<List<int>> batchInsertTransactions(
    List<db.TransactionsCompanion> transactions,
  ) async {
    logDebug('batchInsertTransactions(count=${transactions.length}) called');
    if (transactions.isEmpty) {
      return [];
    }

    try {
      return await _transactionHelper.transaction(() async {
        final ids = <int>[];
        for (final transaction in transactions) {
          final id = await _database.into(_database.transactions).insert(
                transaction,
              );
          ids.add(id);
        }
        logInfo(
          'batchInsertTransactions() inserted ${transactions.length} transactions',
        );
        return ids;
      });
    } catch (e, stackTrace) {
      logError(
        'batchInsertTransactions() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Batch update transactions (optimized with single transaction)
  Future<int> batchUpdateTransactions(
    List<db.TransactionsCompanion> transactions,
  ) async {
    logDebug('batchUpdateTransactions(count=${transactions.length}) called');
    if (transactions.isEmpty) {
      return 0;
    }

    try {
      return await _transactionHelper.transaction(() async {
        int updated = 0;
        for (final transaction in transactions) {
          if (transaction.id.present) {
            await _database.update(_database.transactions).replace(transaction);
            updated++;
          }
        }
        logInfo('batchUpdateTransactions() updated $updated transactions');
        return updated;
      });
    } catch (e, stackTrace) {
      logError(
        'batchUpdateTransactions() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Batch delete transactions by IDs (optimized with single transaction)
  Future<int> batchDeleteTransactions(List<int> ids) async {
    logDebug('batchDeleteTransactions(count=${ids.length}) called');
    if (ids.isEmpty) {
      return 0;
    }

    try {
      return await _transactionHelper.transaction(() async {
        int deleted = 0;
        for (final id in ids) {
          final result = await (_database.delete(_database.transactions)
                ..where((t) => t.id.equals(id)))
              .go();
          deleted += result;
        }
        logInfo('batchDeleteTransactions() deleted $deleted transactions');
        return deleted;
      });
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
    int batchSize = 100,
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
          i + batchSize > transactions.length ? transactions.length : i + batchSize,
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
