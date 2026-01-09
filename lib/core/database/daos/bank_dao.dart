import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/banks.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'bank_dao.g.dart';

@DriftAccessor(tables: [Banks])
class BankDao extends DatabaseAccessor<AppDatabase>
    with _$BankDaoMixin, Loggable {
  BankDao(super.db);

  Future<List<Bank>> getAllBanks() async {
    logDebug('getAllBanks() called');
    try {
      final result = await select(db.banks).get();
      logInfo('getAllBanks() returned ${result.length} banks');
      return result;
    } catch (e, stackTrace) {
      logError('getAllBanks() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Bank>> watchAllBanks() {
    logDebug('watchAllBanks() called');
    return select(db.banks).watch();
  }

  Future<List<Bank>> getActiveBanks() async {
    logDebug('getActiveBanks() called');
    try {
      final result = await (select(
        db.banks,
      )..where((b) => b.isActive.equals(true))).get();
      logInfo('getActiveBanks() returned ${result.length} banks');
      return result;
    } catch (e, stackTrace) {
      logError('getActiveBanks() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Bank?> getBankById(int id) async {
    logDebug('getBankById(id=$id) called');
    try {
      final result = await (select(
        db.banks,
      )..where((b) => b.id.equals(id))).getSingleOrNull();
      logDebug(
        'getBankById(id=$id) returned ${result != null ? "bank" : "null"}',
      );
      return result;
    } catch (e, stackTrace) {
      logError('getBankById(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> insertBank(BanksCompanion bank) async {
    logDebug('insertBank(name=${bank.name.value}) called');
    try {
      final id = await into(db.banks).insert(bank);
      logInfo('insertBank() inserted bank with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('insertBank() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateBank(BanksCompanion bank) async {
    final id = bank.id.value;
    logDebug('updateBank(id=$id) called');
    try {
      final result = await update(db.banks).replace(bank);
      logInfo('updateBank(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('updateBank(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteBank(int id) async {
    logDebug('deleteBank(id=$id) called');
    try {
      final result = await (delete(
        db.banks,
      )..where((b) => b.id.equals(id))).go();
      logInfo('deleteBank(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteBank(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
