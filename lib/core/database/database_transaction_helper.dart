import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'app_database.dart';

/// Helper class for database transactions
/// Ensures data consistency for multi-step operations
class DatabaseTransactionHelper with Loggable {
  final AppDatabase _database;

  DatabaseTransactionHelper(this._database);

  /// Execute multiple database operations in a transaction
  /// If any operation fails, all changes are rolled back
  Future<T> transaction<T>(
    Future<T> Function() action,
  ) async {
    logDebug('Starting database transaction');
    try {
      final result = await _database.transaction(action);
      logInfo('Database transaction completed successfully');
      return result;
    } catch (e, stackTrace) {
      logError(
        'Database transaction failed, rolling back',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Execute multiple operations atomically
  /// All operations must succeed or all are rolled back
  Future<void> executeAtomically(
    List<Future<void> Function()> operations,
  ) async {
    logDebug('Executing ${operations.length} operations atomically');
    await transaction(() async {
      for (final operation in operations) {
        await operation();
      }
    });
    logInfo('Atomic operations completed successfully');
  }
}
