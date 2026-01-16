import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';

part 'transaction_providers.g.dart';

/// All transactions stream - persisted across navigation
final transactionsProvider = StreamProvider<List<db.Transaction>>((ref) async* {
  ref.keepAlive();
  final dao = ref.watch(transactionDaoProvider);
  await for (final transactions in dao.watchAllTransactions()) {
    yield transactions;
  }
});

/// Single transaction provider - kept alive to avoid refetching
final transactionProvider = FutureProvider.family<db.Transaction, int>((
  ref,
  id,
) async {
  ref.keepAlive();
  final dao = ref.watch(transactionDaoProvider);
  final result = await dao.getTransactionById(id);
  if (result == null) {
    throw Exception('Transaction with id $id not found');
  }
  return result;
});

/// Search query state notifier - manages search query for transactions
@riverpod
class TransactionSearchQuery extends _$TransactionSearchQuery {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Stream provider for filtered transactions (optimized - filters in database)
/// Persisted across navigation for smooth UX
/// categoryId: -1 means no filter, searchQuery: empty string means no filter
final filteredTransactionsProvider =
    StreamProvider.family<
      List<db.Transaction>,
      ({int categoryId, String searchQuery})
    >((ref, params) async* {
      ref.keepAlive();
      final dao = ref.watch(transactionDaoProvider);
      await for (final transactions in dao.watchTransactionsFiltered(
        categoryId: params.categoryId == -1 ? null : params.categoryId,
        searchQuery: params.searchQuery.isEmpty ? null : params.searchQuery,
      )) {
        yield transactions;
      }
    });
