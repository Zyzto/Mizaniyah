import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';

/// Provider for all accounts
final accountsProvider = StreamProvider<List<db.Account>>((ref) {
  final dao = ref.watch(accountDaoProvider);
  return dao.watchAllAccounts();
});

/// Provider for active accounts only
final activeAccountsProvider = FutureProvider<List<db.Account>>((ref) async {
  final dao = ref.watch(accountDaoProvider);
  return await dao.getActiveAccounts();
});

/// Provider for a specific account by ID
final accountProvider = FutureProvider.family<db.Account?, int>((ref, accountId) async {
  final dao = ref.watch(accountDaoProvider);
  return await dao.getAccountById(accountId);
});

/// Provider for cards by account ID (null for cards without account)
final cardsByAccountProvider = FutureProvider.family<List<db.Card>, int?>((ref, accountId) async {
  final cardDao = ref.watch(cardDaoProvider);
  final allCards = await cardDao.getAllCards();
  if (accountId == null) {
    // Return cards without an account
    return allCards.where((card) => card.accountId == null).toList();
  }
  return allCards.where((card) => card.accountId == accountId).toList();
});

/// Stream provider for cards by account ID
final cardsByAccountStreamProvider = StreamProvider.family<List<db.Card>, int?>((ref, accountId) {
  final cardDao = ref.watch(cardDaoProvider);
  return cardDao.watchAllCards().map((allCards) {
    if (accountId == null) {
      return allCards.where((card) => card.accountId == null).toList();
    }
    return allCards.where((card) => card.accountId == accountId).toList();
  });
});
