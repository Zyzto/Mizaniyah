import 'package:drift/drift.dart';
import 'models/transactions.dart';
import 'models/accounts.dart';
import 'models/cards.dart';
import 'models/categories.dart';
import 'models/budgets.dart';
import 'models/sms_templates.dart';
import 'models/pending_sms_confirmations.dart';
import 'models/notification_history.dart';
import 'models/category_mappings.dart';
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
    NotificationHistory,
    CategoryMappings,
  ],
)
class AppDatabase extends _$AppDatabase with Loggable {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection()) {
    logDebug('AppDatabase initialized');
  }

  @override
  int get schemaVersion => 11;

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
          await customStatement(
            'PRAGMA journal_mode = WAL',
          ); // Write-Ahead Logging
          await customStatement(
            'PRAGMA synchronous = NORMAL',
          ); // Balance safety/performance
          await customStatement('PRAGMA cache_size = -64000'); // 64MB cache
          await customStatement(
            'PRAGMA temp_store = MEMORY',
          ); // Use memory for temp tables
          await customStatement(
            'PRAGMA mmap_size = 268435456',
          ); // 256MB memory-mapped I/O
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
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_source_date '
              'ON transactions(source, date)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sms_templates_sender_active '
              'ON sms_templates(sender_pattern, is_active)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_pending_sms_confirmations_created_at '
              'ON pending_sms_confirmations(created_at)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_cards_account_id '
              'ON cards(account_id)',
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
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_source_date '
              'ON transactions(source, date)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_sms_templates_sender_active '
              'ON sms_templates(sender_pattern, is_active)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_pending_sms_confirmations_created_at '
              'ON pending_sms_confirmations(created_at)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_cards_account_id '
              'ON cards(account_id)',
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
          logInfo(
            'Performing fresh start migration to version 6 - removing banks',
          );
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
            // Check if column already exists
            final result = await m.database
                .customSelect('PRAGMA table_info(categories)')
                .get();
            final hasSortOrder = result.any(
              (row) => row.data['name'] == 'sort_order',
            );

            if (!hasSortOrder) {
              // Add the sortOrder column with default value
              await m.database.customStatement(
                'ALTER TABLE categories ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
              );
              // Set sortOrder for existing categories based on their creation order
              await m.database.customStatement(
                'UPDATE categories SET sort_order = (SELECT COUNT(*) FROM categories c2 WHERE c2.created_at <= categories.created_at) - 1',
              );
              logInfo('sortOrder column added successfully');
            } else {
              logInfo('sortOrder column already exists, skipping');
            }
          } catch (e, stackTrace) {
            // Check if it's a duplicate column error
            if (e.toString().contains('duplicate column') ||
                e.toString().contains('sort_order')) {
              logWarning(
                'sortOrder column already exists, continuing migration',
                error: e,
              );
              // Continue migration - column already exists
            } else {
              logError(
                'Failed to add sortOrder column',
                error: e,
                stackTrace: stackTrace,
              );
              rethrow;
            }
          }
        }
        // Add Accounts table and accountId to Cards in version 8
        if (from < 8) {
          logInfo('Adding Accounts table and accountId to Cards in version 8');
          try {
            // Create Accounts table (only if it doesn't exist)
            try {
              await m.createTable(accounts);
              logInfo('Accounts table created');
            } catch (e) {
              if (e.toString().contains('already exists') ||
                  e.toString().contains('duplicate')) {
                logInfo('Accounts table already exists, skipping');
              } else {
                rethrow;
              }
            }

            // Check if account_id column already exists
            try {
              final result = await m.database
                  .customSelect('PRAGMA table_info(cards)')
                  .get();
              final hasAccountId = result.any(
                (row) => row.data['name'] == 'account_id',
              );

              if (!hasAccountId) {
                // Add accountId column to Cards table (nullable for backward compatibility)
                await m.database.customStatement(
                  'ALTER TABLE cards ADD COLUMN account_id INTEGER REFERENCES accounts(id) ON DELETE SET NULL',
                );
                logInfo('accountId column added successfully');
              } else {
                logInfo('accountId column already exists, skipping');
              }
            } catch (e) {
              // Check if it's a duplicate column error
              if (e.toString().contains('duplicate column') ||
                  e.toString().contains('account_id')) {
                logWarning(
                  'accountId column already exists, continuing migration',
                );
                // Continue migration - column already exists
              } else {
                rethrow;
              }
            }

            logInfo('Accounts table and accountId column migration completed');
          } catch (e, stackTrace) {
            logError(
              'Failed to add Accounts table',
              error: e,
              stackTrace: stackTrace,
            );
            rethrow;
          }
        }
        // Add NotificationHistory table in version 9
        if (from < 9) {
          logInfo('Adding NotificationHistory table in version 9');
          try {
            await m.createTable(notificationHistory);
            // Create index for faster queries
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_notification_history_created_at '
              'ON notification_history(created_at)',
            );
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_notification_history_type '
              'ON notification_history(notification_type)',
            );
            logInfo('NotificationHistory table added successfully');
          } catch (e, stackTrace) {
            logError(
              'Failed to add NotificationHistory table',
              error: e,
              stackTrace: stackTrace,
            );
            rethrow;
          }
        }
        // Add smsHash column to transactions table in version 10
        if (from < 10) {
          logInfo('Adding smsHash column to transactions table in version 10');
          try {
            // Check if column already exists
            final result = await m.database
                .customSelect('PRAGMA table_info(transactions)')
                .get();
            final hasSmsHash = result.any(
              (row) => row.data['name'] == 'sms_hash',
            );

            if (!hasSmsHash) {
              // Add the smsHash column
              await m.database.customStatement(
                'ALTER TABLE transactions ADD COLUMN sms_hash TEXT',
              );
              // Create index for faster duplicate detection
              await m.database.customStatement(
                'CREATE INDEX IF NOT EXISTS idx_transactions_sms_hash '
                'ON transactions(sms_hash)',
              );
              logInfo('smsHash column added successfully');
            } else {
              logInfo('smsHash column already exists, skipping');
            }
          } catch (e, stackTrace) {
            // Check if it's a duplicate column error
            if (e.toString().contains('duplicate column') ||
                e.toString().contains('sms_hash')) {
              logWarning(
                'smsHash column already exists, continuing migration',
                error: e,
              );
              // Continue migration - column already exists
            } else {
              logError(
                'Failed to add smsHash column',
                error: e,
                stackTrace: stackTrace,
              );
              rethrow;
            }
          }
        }
        // Add CategoryMappings table in version 11
        if (from < 11) {
          logInfo('Adding CategoryMappings table in version 11');
          try {
            // Create table using SQL (will be generated by build_runner)
            await m.database.customStatement('''
              CREATE TABLE IF NOT EXISTS category_mappings (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                store_name_pattern TEXT NOT NULL CHECK(length(store_name_pattern) >= 1 AND length(store_name_pattern) <= 200),
                category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
                confidence REAL NOT NULL DEFAULT 1.0,
                is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
              )
            ''');
            // Create index for faster lookups
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_category_mappings_pattern_active '
              'ON category_mappings(store_name_pattern, is_active)',
            );
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS idx_category_mappings_category '
              'ON category_mappings(category_id)',
            );
            logInfo('CategoryMappings table added successfully');
          } catch (e, stackTrace) {
            logError(
              'Failed to add CategoryMappings table',
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
