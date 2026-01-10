import 'package:drift/drift.dart';
import 'models/transactions.dart';
import 'models/accounts.dart';
import 'models/cards.dart';
import 'models/categories.dart';
import 'models/budgets.dart';
import 'models/sms_templates.dart';
import 'models/pending_sms_confirmations.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'database_connection.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Transactions,
    Cards,
    Categories,
    Budgets,
    SmsTemplates,
    PendingSmsConfirmations,
  ],
)
class AppDatabase extends _$AppDatabase with Loggable {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection()) {
    logDebug('AppDatabase initialized');
  }

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        try {
          await m.createAll();
          logInfo('Database created successfully');
        } catch (e, stackTrace) {
          logError(
            'Database creation failed',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      },
      beforeOpen: (details) async {
        // Optimize SQLite connection settings for better performance
        try {
          // Enable foreign key constraints
          await customStatement('PRAGMA foreign_keys = ON');
          // Optimize for performance
          await customStatement('PRAGMA journal_mode = WAL'); // Write-Ahead Logging
          await customStatement('PRAGMA synchronous = NORMAL'); // Balance safety/performance
          await customStatement('PRAGMA cache_size = -64000'); // 64MB cache
          await customStatement('PRAGMA temp_store = MEMORY'); // Use memory for temp tables
          await customStatement('PRAGMA mmap_size = 268435456'); // 256MB memory-mapped I/O
          logInfo('Database connection optimized');
        } catch (e, stackTrace) {
          logWarning(
            'Failed to optimize database connection',
            error: e,
            stackTrace: stackTrace,
          );
        }

        // Create indexes and check constraints after tables are created
        if (details.wasCreated) {
          try {
            // Single-column indexes
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date '
              'ON transactions(date)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_category '
              'ON transactions(category_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_card '
              'ON transactions(card_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_budgets_category '
              'ON budgets(category_id)',
            );

            // Composite indexes for common query patterns
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date_category '
              'ON transactions(date, category_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_card_date '
              'ON transactions(card_id, date)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date_amount '
              'ON transactions(date, amount)',
            );

            logInfo('Database indexes created successfully');
          } catch (e, stackTrace) {
            logError(
              'Failed to create indexes',
              error: e,
              stackTrace: stackTrace,
            );
            // Continue even if index creation fails
          }
        } else {
          // Ensure indexes exist on existing databases
          try {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date_category '
              'ON transactions(date, category_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_card_date '
              'ON transactions(card_id, date)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date_amount '
              'ON transactions(date, amount)',
            );
          } catch (e, stackTrace) {
            logWarning(
              'Failed to create additional indexes',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      },
      onUpgrade: (Migrator m, int from, int to) async {
        logInfo('Database upgraded from $from to $to');
        // Fresh start: drop all tables and recreate for version 2
        if (from < 2) {
          logInfo('Performing fresh start migration to version 2');
          await m.deleteTable('pending_sms_confirmations');
          await m.deleteTable('sms_templates');
          await m.deleteTable('transactions');
          await m.deleteTable('cards');
          await m.deleteTable('categories');
          await m.deleteTable('banks');
          await m.createAll();
          logInfo('Fresh start migration completed');
        }
        // Add indexes in version 3
        if (from < 3) {
          logInfo('Adding database indexes in version 3');
          // Indexes will be created in beforeOpen callback
        }
        // Add database constraints in version 4
        if (from < 4) {
          logInfo('Adding database constraints in version 4');
          try {
            // Enable foreign key constraints
            await m.database.customStatement('PRAGMA foreign_keys = ON');
            logInfo('Database constraints enabled');
          } catch (e, stackTrace) {
            logError(
              'Failed to enable constraints',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
        // Add performance optimizations and additional indexes in version 5
        if (from < 5) {
          logInfo('Adding performance optimizations in version 5');
          try {
            // Optimize connection settings
            await m.database.customStatement('PRAGMA journal_mode = WAL');
            await m.database.customStatement('PRAGMA synchronous = NORMAL');
            await m.database.customStatement('PRAGMA cache_size = -64000');
            await m.database.customStatement('PRAGMA temp_store = MEMORY');
            await m.database.customStatement('PRAGMA mmap_size = 268435456');

            // Add additional composite indexes
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_card_date '
              'ON transactions(card_id, date)',
            );
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date_amount '
              'ON transactions(date, amount)',
            );

            logInfo('Performance optimizations applied');
          } catch (e, stackTrace) {
            logError(
              'Failed to apply performance optimizations',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
        // Remove banks feature and make SMS independent in version 6
        if (from < 6) {
          logInfo('Performing fresh start migration to version 6 - removing banks');
          // Fresh start: drop all tables and recreate
          await m.deleteTable('pending_sms_confirmations');
          await m.deleteTable('sms_templates');
          await m.deleteTable('transactions');
          await m.deleteTable('cards');
          await m.deleteTable('categories');
          await m.deleteTable('budgets');
          await m.deleteTable('banks');
          await m.createAll();
          logInfo('Fresh start migration to version 6 completed');
        }
        // Add sortOrder column to categories table in version 7
        if (from < 7) {
          logInfo('Adding sortOrder column to categories table in version 7');
          try {
            // Add the sortOrder column with default value
            await m.database.customStatement(
              'ALTER TABLE categories ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
            );
            // Set sortOrder for existing categories based on their creation order
            await m.database.customStatement(
              'UPDATE categories SET sort_order = (SELECT COUNT(*) FROM categories c2 WHERE c2.created_at <= categories.created_at) - 1',
            );
            logInfo('sortOrder column added successfully');
          } catch (e, stackTrace) {
            logError(
              'Failed to add sortOrder column',
              error: e,
              stackTrace: stackTrace,
            );
            rethrow;
          }
        }
        // Add Accounts table and accountId to Cards in version 8
        if (from < 8) {
          logInfo('Adding Accounts table and accountId to Cards in version 8');
          try {
            // Create Accounts table
            await m.createTable(accounts);
            // Add accountId column to Cards table (nullable for backward compatibility)
            await m.database.customStatement(
              'ALTER TABLE cards ADD COLUMN account_id INTEGER REFERENCES accounts(id) ON DELETE SET NULL',
            );
            logInfo('Accounts table and accountId column added successfully');
          } catch (e, stackTrace) {
            logError(
              'Failed to add Accounts table',
              error: e,
              stackTrace: stackTrace,
            );
            rethrow;
          }
        }
      },
    );
  }
}
