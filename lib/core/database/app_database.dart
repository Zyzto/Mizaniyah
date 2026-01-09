import 'package:drift/drift.dart';
import 'models/transactions.dart';
import 'models/banks.dart';
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
    Transactions,
    Banks,
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
  int get schemaVersion => 2;

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
      },
    );
  }
}
