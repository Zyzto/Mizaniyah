import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/accounts.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import 'base_dao_mixin.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDaoMixin, Loggable, BaseDaoMixin {
  AccountDao(super.db);

  Future<List<Account>> getAllAccounts() async {
    return executeWithErrorHandling<List<Account>>(
      operationName: 'getAllAccounts',
      operation: () async {
        final result = await select(db.accounts).get();
        logInfo('getAllAccounts() returned ${result.length} accounts');
        return result;
      },
      onError: () => <Account>[],
    );
  }

  Stream<List<Account>> watchAllAccounts() {
    logDebug('watchAllAccounts() called');
    return select(db.accounts).watch();
  }

  Future<List<Account>> getActiveAccounts() async {
    return executeWithErrorHandling<List<Account>>(
      operationName: 'getActiveAccounts',
      operation: () async {
        final result = await (select(
          db.accounts,
        )..where((a) => a.isActive.equals(true))).get();
        logInfo('getActiveAccounts() returned ${result.length} accounts');
        return result;
      },
      onError: () => <Account>[],
    );
  }

  Future<Account?> getAccountById(int id) async {
    return executeWithErrorHandling<Account?>(
      operationName: 'getAccountById',
      operation: () async {
        final result = await (select(
          db.accounts,
        )..where((a) => a.id.equals(id))).getSingleOrNull();
        logDebug(
          'getAccountById(id=$id) returned ${result != null ? "account" : "null"}',
        );
        return result;
      },
      onError: () => null,
    );
  }

  Future<int> insertAccount(AccountsCompanion account) async {
    return executeWithErrorHandling<int>(
      operationName: 'insertAccount',
      operation: () async {
        final id = await into(db.accounts).insert(account);
        logInfo('insertAccount() inserted account with id=$id');
        return id;
      },
    );
  }

  Future<bool> updateAccount(AccountsCompanion account) async {
    final id = account.id.value;
    return executeWithErrorHandling<bool>(
      operationName: 'updateAccount',
      operation: () async {
        final result = await update(db.accounts).replace(account);
        logInfo('updateAccount(id=$id) updated successfully');
        return result;
      },
    );
  }

  Future<int> deleteAccount(int id) async {
    return executeWithErrorHandling<int>(
      operationName: 'deleteAccount',
      operation: () async {
        final result = await (delete(
          db.accounts,
        )..where((a) => a.id.equals(id))).go();
        logInfo('deleteAccount(id=$id) deleted $result rows');
        return result;
      },
    );
  }
}
