import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/pending_sms_confirmation_dao.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

class PendingSmsRepository with Loggable {
  final db.AppDatabase _db;
  late final PendingSmsConfirmationDao _pendingSmsDao;

  PendingSmsRepository(this._db) {
    logDebug('PendingSmsRepository initialized');
    _pendingSmsDao = PendingSmsConfirmationDao(_db);
  }

  Stream<List<db.PendingSmsConfirmation>> watchAllPendingConfirmations() =>
      _pendingSmsDao.watchAllPendingConfirmations();

  Future<List<db.PendingSmsConfirmation>> getAllPendingConfirmations() =>
      _pendingSmsDao.getAllPendingConfirmations();

  Future<List<db.PendingSmsConfirmation>> getNonExpiredConfirmations() =>
      _pendingSmsDao.getNonExpiredConfirmations();

  Future<db.PendingSmsConfirmation?> getConfirmationById(int id) =>
      _pendingSmsDao.getConfirmationById(id);

  Future<int> createConfirmation(
    db.PendingSmsConfirmationsCompanion confirmation,
  ) async {
    logInfo('createConfirmation()');
    try {
      final id = await _pendingSmsDao.insertConfirmation(confirmation);
      logInfo('createConfirmation() created confirmation with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('createConfirmation() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteConfirmation(int id) async {
    logInfo('deleteConfirmation(id=$id)');
    try {
      final result = await _pendingSmsDao.deleteConfirmation(id);
      logInfo('deleteConfirmation(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError(
        'deleteConfirmation(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> deleteExpiredConfirmations() async {
    logInfo('deleteExpiredConfirmations()');
    try {
      final result = await _pendingSmsDao.deleteExpiredConfirmations();
      logInfo('deleteExpiredConfirmations() deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError(
        'deleteExpiredConfirmations() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
