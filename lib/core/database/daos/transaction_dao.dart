import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/transactions.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'base_dao_mixin.dart';
import '../validators/transaction_validator.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin, Loggable, BaseDaoMixin {
  TransactionDao(super.db);

  Future<List<Transaction>> getAllTransactions() async {
    return executeWithErrorHandling<List<Transaction>>(
      operationName: 'getAllTransactions',
      operation: () async {
        final result = await select(db.transactions).get();
        logInfo('getAllTransactions() returned ${result.length} transactions');
        return result;
      },
      onError: () => <Transaction>[],
    );
  }

  Stream<List<Transaction>> watchAllTransactions() {
    logDebug('watchAllTransactions() called');
    return (select(
      db.transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  /// Get transactions filtered by category and/or search query (optimized)
  Future<List<Transaction>> getTransactionsFiltered({
    int? categoryId,
    String? searchQuery,
    int? limit,
    int offset = 0,
  }) async {
    return executeWithErrorHandling<List<Transaction>>(
      operationName: 'getTransactionsFiltered',
      operation: () async {
        var query = select(db.transactions);

        if (categoryId != null) {
          query = query..where((t) => t.categoryId.equals(categoryId));
        }

        if (searchQuery != null && searchQuery.isNotEmpty) {
          final searchLower = searchQuery.toLowerCase();
          query = query..where((t) => t.storeName.like('%$searchLower%'));
        }

        query = query..orderBy([(t) => OrderingTerm.desc(t.date)]);

        if (limit != null) {
          query = query..limit(limit, offset: offset);
        }

        final result = await query.get();
        logInfo(
          'getTransactionsFiltered() returned ${result.length} transactions',
        );
        return result;
      },
      onError: () => <Transaction>[],
    );
  }

  /// Stream transactions filtered by category and/or search query
  Stream<List<Transaction>> watchTransactionsFiltered({
    int? categoryId,
    String? searchQuery,
  }) {
    logDebug(
      'watchTransactionsFiltered(categoryId=$categoryId, searchQuery=$searchQuery) called',
    );
    var query = select(db.transactions);

    if (categoryId != null) {
      query = query..where((t) => t.categoryId.equals(categoryId));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      query = query..where((t) => t.storeName.like('%$searchLower%'));
    }

    query = query..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.watch();
  }

  Future<Transaction?> getTransactionById(int id) async {
    return executeWithErrorHandling<Transaction?>(
      operationName: 'getTransactionById',
      operation: () async {
        final result = await (select(
          db.transactions,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        logDebug(
          'getTransactionById(id=$id) returned ${result != null ? "transaction" : "null"}',
        );
        return result;
      },
      onError: () => null,
    );
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return executeWithErrorHandling<List<Transaction>>(
      operationName: 'getTransactionsByDateRange',
      operation: () async {
        final result =
            await (select(db.transactions)
                  ..where((t) => t.date.isBiggerOrEqualValue(start))
                  ..where((t) => t.date.isSmallerOrEqualValue(end))
                  ..orderBy([(t) => OrderingTerm.desc(t.date)]))
                .get();
        logInfo(
          'getTransactionsByDateRange() returned ${result.length} transactions',
        );
        return result;
      },
      onError: () => <Transaction>[],
    );
  }

  /// Get transactions by date range and category (optimized for budget calculations)
  Future<List<Transaction>> getTransactionsByDateRangeAndCategory(
    DateTime start,
    DateTime end,
    int categoryId,
  ) async {
    return executeWithErrorHandling<List<Transaction>>(
      operationName: 'getTransactionsByDateRangeAndCategory',
      operation: () async {
        final result =
            await (select(db.transactions)
                  ..where((t) => t.date.isBiggerOrEqualValue(start))
                  ..where((t) => t.date.isSmallerOrEqualValue(end))
                  ..where((t) => t.categoryId.equals(categoryId))
                  ..orderBy([(t) => OrderingTerm.desc(t.date)]))
                .get();
        logInfo(
          'getTransactionsByDateRangeAndCategory() returned ${result.length} transactions',
        );
        return result;
      },
      onError: () => <Transaction>[],
    );
  }

  Future<int> insertTransaction(TransactionsCompanion transaction) async {
    return executeWithErrorHandling<int>(
      operationName: 'insertTransaction',
      operation: () async {
        TransactionValidator.validateInsert(transaction);
        final id = await into(db.transactions).insert(transaction);
        logInfo('insertTransaction() inserted transaction with id=$id');
        return id;
      },
    );
  }

  Future<bool> updateTransaction(TransactionsCompanion transaction) async {
    final id = transaction.id.value;
    return executeWithErrorHandling<bool>(
      operationName: 'updateTransaction',
      operation: () async {
        TransactionValidator.validateUpdate(transaction);
        final result = await update(db.transactions).replace(transaction);
        logInfo('updateTransaction(id=$id) updated successfully');
        return result;
      },
    );
  }

  Future<int> deleteTransaction(int id) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteTransaction',
      operation: () async {
        final result = await (delete(
          db.transactions,
        )..where((t) => t.id.equals(id))).go();
        logInfo('deleteTransaction(id=$id) deleted $result rows');
        return result;
      },
    );
  }

  /// Get transaction statistics for a card (count and total amount)
  /// Optimized: Uses SQL aggregation instead of loading all transactions
  Future<({int count, double total})> getCardStatistics(int cardId) async {
    return executeWithErrorHandling<({int count, double total})>(
      operationName: 'getCardStatistics',
      operation: () async {
        final query = selectOnly(db.transactions)
          ..addColumns([
            db.transactions.id.count(),
            db.transactions.amount.sum(),
          ])
          ..where(db.transactions.cardId.equals(cardId));

        final result = await query.getSingle();

        final count = result.read(db.transactions.id.count()) ?? 0;
        final total = result.read(db.transactions.amount.sum()) ?? 0.0;

        logInfo(
          'getCardStatistics(cardId=$cardId) returned count=$count, total=$total',
        );
        return (count: count, total: total);
      },
      onError: () => (count: 0, total: 0.0),
    );
  }

  /// Get total amount by date range with optional currency filter (optimized)
  /// Uses SQL aggregation instead of loading all transactions
  Future<double> getTotalByDateRange(
    DateTime start,
    DateTime end, {
    String? currencyCode,
  }) async {
    return executeWithErrorHandling<double>(
      operationName: 'getTotalByDateRange',
      operation: () async {
        final query = selectOnly(db.transactions)
          ..addColumns([db.transactions.amount.sum()])
          ..where(db.transactions.date.isBiggerOrEqualValue(start))
          ..where(db.transactions.date.isSmallerOrEqualValue(end));

        if (currencyCode != null) {
          query.where(db.transactions.currencyCode.equals(currencyCode));
        }

        final result = await query.getSingle();
        final total = result.read(db.transactions.amount.sum()) ?? 0.0;
        logInfo('getTotalByDateRange() returned total=$total');
        return total;
      },
      onError: () => 0.0,
    );
  }

  /// Get total transaction count (optimized with SQL aggregation)
  Future<int> getTransactionCount() async {
    return executeWithErrorHandling<int>(
      operationName: 'getTransactionCount',
      operation: () async {
        final query = selectOnly(db.transactions)
          ..addColumns([db.transactions.id.count()]);

        final result = await query.getSingle();
        final count = result.read(db.transactions.id.count()) ?? 0;
        logInfo('getTransactionCount() returned $count');
        return count;
      },
      onError: () => 0,
    );
  }

  /// Get total spent amount (optimized with SQL aggregation)
  Future<double> getTotalSpent() async {
    return executeWithErrorHandling<double>(
      operationName: 'getTotalSpent',
      operation: () async {
        final query = selectOnly(db.transactions)
          ..addColumns([db.transactions.amount.sum()]);

        final result = await query.getSingle();
        final total = result.read(db.transactions.amount.sum()) ?? 0.0;
        logInfo('getTotalSpent() returned $total');
        return total;
      },
      onError: () => 0.0,
    );
  }
}
