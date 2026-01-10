import 'package:drift/drift.dart' as drift;
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'app_database.dart' as db;

/// Service for maintaining database data integrity
/// Performs cleanup operations and validates data consistency
class DataIntegrityService with Loggable {
  final db.AppDatabase _database;

  DataIntegrityService(this._database);

  /// Clean up orphaned records (transactions with invalid foreign keys)
  Future<int> cleanupOrphanedTransactions() async {
    logDebug('Cleaning up orphaned transactions');
    try {
      // Find transactions with invalid category references
      final orphanedByCategory = await _database.customSelect(
        '''
        SELECT id FROM transactions 
        WHERE category_id IS NOT NULL 
        AND category_id NOT IN (SELECT id FROM categories)
        ''',
        readsFrom: {_database.transactions, _database.categories},
      ).get();

      // Find transactions with invalid card references
      final orphanedByCard = await _database.customSelect(
        '''
        SELECT id FROM transactions 
        WHERE card_id IS NOT NULL 
        AND card_id NOT IN (SELECT id FROM cards)
        ''',
        readsFrom: {_database.transactions, _database.cards},
      ).get();

      // Find transactions with invalid budget references
      final orphanedByBudget = await _database.customSelect(
        '''
        SELECT id FROM transactions 
        WHERE budget_id IS NOT NULL 
        AND budget_id NOT IN (SELECT id FROM budgets)
        ''',
        readsFrom: {_database.transactions, _database.budgets},
      ).get();

      int cleaned = 0;

      // Set orphaned foreign keys to NULL
      for (final row in orphanedByCategory) {
        await (_database.update(_database.transactions)
              ..where((t) => t.id.equals(row.read<int>('id'))))
            .write(db.TransactionsCompanion(
              categoryId: const drift.Value.absent(),
            ));
        cleaned++;
      }

      for (final row in orphanedByCard) {
        await (_database.update(_database.transactions)
              ..where((t) => t.id.equals(row.read<int>('id'))))
            .write(db.TransactionsCompanion(
              cardId: const drift.Value.absent(),
            ));
        cleaned++;
      }

      for (final row in orphanedByBudget) {
        await (_database.update(_database.transactions)
              ..where((t) => t.id.equals(row.read<int>('id'))))
            .write(db.TransactionsCompanion(
              budgetId: const drift.Value.absent(),
            ));
        cleaned++;
      }

      logInfo('Cleaned up $cleaned orphaned transaction references');
      return cleaned;
    } catch (e, stackTrace) {
      logError(
        'Failed to cleanup orphaned transactions',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Validate database integrity
  /// Returns a map of validation results
  Future<Map<String, dynamic>> validateIntegrity() async {
    logDebug('Validating database integrity');
    final results = <String, dynamic>{};

    try {
      // Check for orphaned transactions
      final orphanedCount = await _database.customSelect(
        '''
        SELECT COUNT(*) as count FROM transactions 
        WHERE (category_id IS NOT NULL AND category_id NOT IN (SELECT id FROM categories))
           OR (card_id IS NOT NULL AND card_id NOT IN (SELECT id FROM cards))
           OR (budget_id IS NOT NULL AND budget_id NOT IN (SELECT id FROM budgets))
        ''',
        readsFrom: {
          _database.transactions,
          _database.categories,
          _database.cards,
          _database.budgets,
        },
      ).getSingle();

      results['orphaned_transactions'] = orphanedCount.read<int>('count');

      // Check for invalid amounts
      final invalidAmounts = await _database.customSelect(
        'SELECT COUNT(*) as count FROM transactions WHERE amount <= 0',
        readsFrom: {_database.transactions},
      ).getSingle();

      results['invalid_amounts'] = invalidAmounts.read<int>('count');

      // Check for invalid budget amounts
      final invalidBudgets = await _database.customSelect(
        'SELECT COUNT(*) as count FROM budgets WHERE amount <= 0',
        readsFrom: {_database.budgets},
      ).getSingle();

      results['invalid_budget_amounts'] = invalidBudgets.read<int>('count');

      logInfo('Database integrity validation completed: $results');
      return results;
    } catch (e, stackTrace) {
      logError(
        'Failed to validate database integrity',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Run all integrity checks and cleanup operations
  Future<void> performMaintenance() async {
    logInfo('Starting database maintenance');
    try {
      final validation = await validateIntegrity();
      logInfo('Validation results: $validation');

      if (validation['orphaned_transactions'] as int > 0) {
        await cleanupOrphanedTransactions();
      }

      logInfo('Database maintenance completed');
    } catch (e, stackTrace) {
      logError(
        'Database maintenance failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
