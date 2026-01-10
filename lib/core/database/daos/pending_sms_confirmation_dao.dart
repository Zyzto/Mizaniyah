import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/pending_sms_confirmations.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'base_dao_mixin.dart';

part 'pending_sms_confirmation_dao.g.dart';

@DriftAccessor(tables: [PendingSmsConfirmations])
class PendingSmsConfirmationDao extends DatabaseAccessor<AppDatabase>
    with _$PendingSmsConfirmationDaoMixin, Loggable, BaseDaoMixin {
  PendingSmsConfirmationDao(super.db);

  Future<List<PendingSmsConfirmation>> getAllPendingConfirmations() async {
    return executeWithErrorHandling<List<PendingSmsConfirmation>>(
      operationName: 'getAllPendingConfirmations',
      operation: () async {
        final result = await select(db.pendingSmsConfirmations).get();
        logInfo(
          'getAllPendingConfirmations() returned ${result.length} confirmations',
        );
        return result;
      },
      onError: () => <PendingSmsConfirmation>[],
    );
  }

  Stream<List<PendingSmsConfirmation>> watchAllPendingConfirmations() {
    logDebug('watchAllPendingConfirmations() called');
    return select(db.pendingSmsConfirmations).watch();
  }

  Future<List<PendingSmsConfirmation>> getNonExpiredConfirmations() async {
    return executeWithErrorHandling<List<PendingSmsConfirmation>>(
      operationName: 'getNonExpiredConfirmations',
      operation: () async {
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
      },
      onError: () => <PendingSmsConfirmation>[],
    );
  }

  Future<PendingSmsConfirmation?> getConfirmationById(int id) async {
    return executeWithErrorHandling<PendingSmsConfirmation?>(
      operationName: 'getConfirmationById',
      operation: () async {
        final result = await (select(
          db.pendingSmsConfirmations,
        )..where((p) => p.id.equals(id))).getSingleOrNull();
        logDebug(
          'getConfirmationById(id=$id) returned ${result != null ? "confirmation" : "null"}',
        );
        return result;
      },
      onError: () => null,
    );
  }

  Future<int> insertConfirmation(
    PendingSmsConfirmationsCompanion confirmation,
  ) async {
    return executeWithErrorHandling<int>(
      operationName: 'insertConfirmation',
      operation: () async {
        // Validate data before insertion
        final smsBody = confirmation.smsBody.value;
        validateNonEmptyString(smsBody, 'SMS body');

        final id = await into(db.pendingSmsConfirmations).insert(confirmation);
        logInfo('insertConfirmation() inserted confirmation with id=$id');
        return id;
      },
    );
  }

  Future<int> deleteConfirmation(int id) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteConfirmation',
      operation: () async {
        final result = await (delete(
          db.pendingSmsConfirmations,
        )..where((p) => p.id.equals(id))).go();
        logInfo('deleteConfirmation(id=$id) deleted $result rows');
        return result;
      },
    );
  }

  Future<int> deleteExpiredConfirmations() async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteExpiredConfirmations',
      operation: () async {
        final now = DateTime.now();
        final result = await (delete(
          db.pendingSmsConfirmations,
        )..where((p) => p.expiresAt.isSmallerOrEqualValue(now))).go();
        logInfo('deleteExpiredConfirmations() deleted $result rows');
        return result;
      },
    );
  }

  /// Get count of non-expired confirmations (optimized with SQL aggregation)
  Future<int> getNonExpiredConfirmationsCount() async {
    return executeWithErrorHandling<int>(
      operationName: 'getNonExpiredConfirmationsCount',
      operation: () async {
        final now = DateTime.now();
        final query = selectOnly(db.pendingSmsConfirmations)
          ..addColumns([db.pendingSmsConfirmations.id.count()])
          ..where(
            db.pendingSmsConfirmations.expiresAt.isBiggerThanValue(now),
          );

        final result = await query.getSingle();
        final count = result.read(db.pendingSmsConfirmations.id.count()) ?? 0;
        logInfo('getNonExpiredConfirmationsCount() returned $count');
        return count;
      },
      onError: () => 0,
    );
  }
}
