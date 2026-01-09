import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/transactions.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin, Loggable {
  TransactionDao(super.db);

  Future<List<Transaction>> getAllTransactions() async {
    logDebug('getAllTransactions() called');
    try {
      final result = await select(db.transactions).get();
      logInfo('getAllTransactions() returned ${result.length} transactions');
      return result;
    } catch (e, stackTrace) {
      logError('getAllTransactions() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Transaction>> watchAllTransactions() {
    logDebug('watchAllTransactions() called');
    return select(db.transactions).watch();
  }

  Future<Transaction?> getTransactionById(int id) async {
    logDebug('getTransactionById(id=$id) called');
    try {
      final result = await (select(
        db.transactions,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      logDebug(
        'getTransactionById(id=$id) returned ${result != null ? "transaction" : "null"}',
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'getTransactionById(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    logDebug('getTransactionsByDateRange(start=$start, end=$end) called');
    try {
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
    } catch (e, stackTrace) {
      logError(
        'getTransactionsByDateRange() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> insertTransaction(TransactionsCompanion transaction) async {
    logDebug('insertTransaction(store=${transaction.storeName.value}) called');
    try {
      final id = await into(db.transactions).insert(transaction);
      logInfo('insertTransaction() inserted transaction with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('insertTransaction() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateTransaction(TransactionsCompanion transaction) async {
    final id = transaction.id.value;
    logDebug('updateTransaction(id=$id) called');
    try {
      final result = await update(db.transactions).replace(transaction);
      logInfo('updateTransaction(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError(
        'updateTransaction(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> deleteTransaction(int id) async {
    logDebug('deleteTransaction(id=$id) called');
    try {
      final result = await (delete(
        db.transactions,
      )..where((t) => t.id.equals(id))).go();
      logInfo('deleteTransaction(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError(
        'deleteTransaction(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
