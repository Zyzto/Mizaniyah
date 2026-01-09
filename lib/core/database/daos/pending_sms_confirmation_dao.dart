import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/pending_sms_confirmations.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'pending_sms_confirmation_dao.g.dart';

@DriftAccessor(tables: [PendingSmsConfirmations])
class PendingSmsConfirmationDao extends DatabaseAccessor<AppDatabase>
    with _$PendingSmsConfirmationDaoMixin, Loggable {
  PendingSmsConfirmationDao(super.db);

  Future<List<PendingSmsConfirmation>> getAllPendingConfirmations() async {
    logDebug('getAllPendingConfirmations() called');
    try {
      final result = await select(db.pendingSmsConfirmations).get();
      logInfo(
        'getAllPendingConfirmations() returned ${result.length} confirmations',
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'getAllPendingConfirmations() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Stream<List<PendingSmsConfirmation>> watchAllPendingConfirmations() {
    logDebug('watchAllPendingConfirmations() called');
    return select(db.pendingSmsConfirmations).watch();
  }

  Future<List<PendingSmsConfirmation>> getNonExpiredConfirmations() async {
    logDebug('getNonExpiredConfirmations() called');
    try {
      final now = DateTime.now();
      final result =
          await (select(db.pendingSmsConfirmations)
                ..where((p) => p.expiresAt.isBiggerThanValue(now))
                ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
              .get();
      logInfo(
        'getNonExpiredConfirmations() returned ${result.length} confirmations',
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'getNonExpiredConfirmations() failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<PendingSmsConfirmation?> getConfirmationById(int id) async {
    logDebug('getConfirmationById(id=$id) called');
    try {
      final result = await (select(
        db.pendingSmsConfirmations,
      )..where((p) => p.id.equals(id))).getSingleOrNull();
      logDebug(
        'getConfirmationById(id=$id) returned ${result != null ? "confirmation" : "null"}',
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'getConfirmationById(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> insertConfirmation(
    PendingSmsConfirmationsCompanion confirmation,
  ) async {
    logDebug('insertConfirmation() called');
    try {
      final id = await into(db.pendingSmsConfirmations).insert(confirmation);
      logInfo('insertConfirmation() inserted confirmation with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('insertConfirmation() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteConfirmation(int id) async {
    logDebug('deleteConfirmation(id=$id) called');
    try {
      final result = await (delete(
        db.pendingSmsConfirmations,
      )..where((p) => p.id.equals(id))).go();
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
    logDebug('deleteExpiredConfirmations() called');
    try {
      final now = DateTime.now();
      final result = await (delete(
        db.pendingSmsConfirmations,
      )..where((p) => p.expiresAt.isSmallerOrEqualValue(now))).go();
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
