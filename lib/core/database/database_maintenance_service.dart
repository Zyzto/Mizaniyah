import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'app_database.dart' as db;

/// Service for database maintenance operations
/// Performs VACUUM, ANALYZE, and optimization tasks
class DatabaseMaintenanceService with Loggable {
  final db.AppDatabase _database;

  DatabaseMaintenanceService(this._database);

  /// Run VACUUM to reclaim unused space and optimize database
  Future<void> vacuum() async {
    logInfo('Running VACUUM to optimize database');
    try {
      await _database.customStatement('VACUUM');
      logInfo('VACUUM completed successfully');
    } catch (e, stackTrace) {
      logError('VACUUM failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Run ANALYZE to update query optimizer statistics
  Future<void> analyze() async {
    logInfo('Running ANALYZE to update query statistics');
    try {
      await _database.customStatement('ANALYZE');
      logInfo('ANALYZE completed successfully');
    } catch (e, stackTrace) {
      logError('ANALYZE failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    logDebug('Getting database size');
    try {
      final result = await _database
          .customSelect(
            'SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()',
            readsFrom: {},
          )
          .getSingle();

      final size = result.read<int>('size');
      logInfo('Database size: $size bytes');
      return size;
    } catch (e, stackTrace) {
      logError('Failed to get database size', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Get table statistics (row counts, etc.)
  Future<Map<String, int>> getTableStatistics() async {
    logDebug('Getting table statistics');
    final stats = <String, int>{};

    try {
      final tables = [
        'transactions',
        'cards',
        'categories',
        'budgets',
        'sms_templates',
        'pending_sms_confirmations',
      ];

      for (final table in tables) {
        try {
          final result = await _database
              .customSelect(
                'SELECT COUNT(*) as count FROM $table',
                readsFrom: {},
              )
              .getSingle();
          stats[table] = result.read<int>('count');
        } catch (e) {
          logWarning('Failed to get count for table $table: $e');
          stats[table] = 0;
        }
      }

      logInfo('Table statistics: $stats');
      return stats;
    } catch (e, stackTrace) {
      logError(
        'Failed to get table statistics',
        error: e,
        stackTrace: stackTrace,
      );
      return stats;
    }
  }

  /// Get index usage statistics
  Future<Map<String, dynamic>> getIndexStatistics() async {
    logDebug('Getting index statistics');
    try {
      final result = await _database.customSelect('''
        SELECT 
          name,
          tbl_name,
          sql
        FROM sqlite_master
        WHERE type = 'index' AND name NOT LIKE 'sqlite_%'
        ORDER BY name
        ''', readsFrom: {}).get();

      final indexes = <String, Map<String, dynamic>>{};
      for (final row in result) {
        final name = row.read<String>('name');
        indexes[name] = {
          'table': row.read<String>('tbl_name'),
          'sql': row.read<String?>('sql'),
        };
      }

      logInfo('Found ${indexes.length} indexes');
      return indexes;
    } catch (e, stackTrace) {
      logError(
        'Failed to get index statistics',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Perform full database maintenance (VACUUM + ANALYZE)
  Future<void> performFullMaintenance() async {
    logInfo('Starting full database maintenance');
    try {
      await vacuum();
      await analyze();
      logInfo('Full database maintenance completed successfully');
    } catch (e, stackTrace) {
      logError(
        'Full database maintenance failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get query plan for a SQL query (for optimization)
  Future<List<Map<String, dynamic>>> explainQuery(String sql) async {
    logDebug('Explaining query: $sql');
    try {
      final result = await _database
          .customSelect('EXPLAIN QUERY PLAN $sql', readsFrom: {})
          .get();

      final plan = <Map<String, dynamic>>[];
      for (final row in result) {
        plan.add({
          'selectid': row.read<int?>('selectid'),
          'order': row.read<int?>('order'),
          'from': row.read<int?>('from'),
          'detail': row.read<String?>('detail'),
        });
      }

      logInfo('Query plan: $plan');
      return plan;
    } catch (e, stackTrace) {
      logError('Failed to explain query', error: e, stackTrace: stackTrace);
      return [];
    }
  }
}
