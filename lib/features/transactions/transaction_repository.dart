import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/transaction_dao.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

class TransactionRepository with Loggable {
  final db.AppDatabase _db;
  late final TransactionDao _transactionDao;

  TransactionRepository(this._db) {
    logDebug('TransactionRepository initialized');
    _transactionDao = TransactionDao(_db);
  }

  // Transactions
  Stream<List<db.Transaction>> watchAllTransactions() =>
      _transactionDao.watchAllTransactions();

  Future<List<db.Transaction>> getAllTransactions() =>
      _transactionDao.getAllTransactions();

  Future<db.Transaction?> getTransactionById(int id) =>
      _transactionDao.getTransactionById(id);

  Future<List<db.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) => _transactionDao.getTransactionsByDateRange(start, end);

  Future<int> createTransaction(db.TransactionsCompanion transaction) async {
    logInfo('createTransaction(store=${transaction.storeName.value})');
    try {
      final transactionId = await _transactionDao.insertTransaction(
        transaction,
      );
      logInfo('createTransaction() created transaction with id=$transactionId');
      return transactionId;
    } catch (e, stackTrace) {
      logError('createTransaction() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateTransaction(db.TransactionsCompanion transaction) async {
    final id = transaction.id.value;
    logInfo('updateTransaction(id=$id)');
    try {
      final result = await _transactionDao.updateTransaction(transaction);
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
    logInfo('deleteTransaction(id=$id)');
    try {
      final result = await _transactionDao.deleteTransaction(id);
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

  // Helper methods for statistics
  Future<double> getTotalByDateRange(
    DateTime start,
    DateTime end, {
    String? currencyCode,
  }) async {
    logDebug(
      'getTotalByDateRange(start=$start, end=$end, currencyCode=$currencyCode)',
    );
    try {
      final transactions = await getTransactionsByDateRange(start, end);
      double total = 0.0;
      for (final transaction in transactions) {
        if (currencyCode == null || transaction.currencyCode == currencyCode) {
          total += transaction.amount;
        }
      }
      logInfo('getTotalByDateRange() returned total=$total');
      return total;
    } catch (e, stackTrace) {
      logError(
        'getTotalByDateRange() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
