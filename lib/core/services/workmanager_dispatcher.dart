import 'package:workmanager/workmanager.dart';
import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/pending_sms_confirmation_dao.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

/// WorkManager callback dispatcher
/// This is the entry point for background tasks scheduled by WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    Log.info('WorkManager task started: $task');

    try {
      // Initialize database and DAO in background context
      Log.debug('WorkManager: Initializing database and DAO');
      final appDatabase = db.AppDatabase();
      final pendingSmsDao = PendingSmsConfirmationDao(appDatabase);

      // Clean up expired pending SMS confirmations
      Log.debug('WorkManager: Cleaning up expired confirmations');
      await pendingSmsDao.deleteExpiredConfirmations();
      Log.debug('WorkManager: Completed cleanup');

      Log.info('WorkManager task completed successfully: $task');
      return Future.value(true);
    } catch (e, stackTrace) {
      Log.error(
        'WorkManager task failed: $task',
        error: e,
        stackTrace: stackTrace,
      );
      return Future.value(false);
    }
  });
}
