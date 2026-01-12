import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';

/// Provider for all accounts - persisted and reactive
final accountsProvider = StreamProvider<List<db.Account>>((ref) async* {
  ref.keepAlive();
  final dao = ref.watch(accountDaoProvider);
  try {
    await for (final accounts in dao.watchAllAccounts()) {
      yield accounts;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in accountsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield [];
  }
});

/// Provider for active accounts only - derived from stream
final activeAccountsProvider = Provider<AsyncValue<List<db.Account>>>((ref) {
  ref.keepAlive();
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.whenData(
    (accounts) => accounts.where((a) => a.isActive).toList(),
  );
});

/// Provider for a specific account by ID - kept alive
final accountProvider = FutureProvider.family<db.Account?, int>((ref, accountId) async {
  ref.keepAlive();
  final dao = ref.watch(accountDaoProvider);
  return await dao.getAccountById(accountId);
});

/// Stream provider for cards by account ID - persisted and reactive
final cardsByAccountProvider = StreamProvider.family<List<db.Card>, int?>((ref, accountId) async* {
  ref.keepAlive();
  final cardDao = ref.watch(cardDaoProvider);
  try {
    await for (final allCards in cardDao.watchAllCards()) {
      if (accountId == null) {
        // Return cards without an account
        yield allCards.where((card) => card.accountId == null).toList();
      } else {
        yield allCards.where((card) => card.accountId == accountId).toList();
      }
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in cardsByAccountProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield [];
  }
});
