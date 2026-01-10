import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';

// All transactions stream - auto-dispose when not in use
final transactionsProvider = StreamProvider.autoDispose<List<db.Transaction>>((ref) async* {
  final dao = ref.watch(transactionDaoProvider);
  try {
    await for (final transactions in dao.watchAllTransactions()) {
      yield transactions;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in transactionsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

// Single transaction provider - cached per ID, auto-dispose when not watched
final transactionProvider = FutureProvider.autoDispose.family<db.Transaction?, int>((
  ref,
  id,
) async {
  final dao = ref.watch(transactionDaoProvider);
  try {
    return await dao.getTransactionById(id);
  } catch (e, stackTrace) {
    Log.error(
      'Error in transactionProvider for id=$id',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});

/// Filter parameters for transactions
class TransactionFilters {
  final int? categoryId;
  final String? searchQuery;

  const TransactionFilters({
    this.categoryId,
    this.searchQuery,
  });

  TransactionFilters copyWith({
    int? categoryId,
    String? searchQuery,
  }) {
    return TransactionFilters(
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilters &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => categoryId.hashCode ^ searchQuery.hashCode;
}

/// Search query state notifier - manages search query for transactions
class TransactionSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final transactionSearchQueryProvider =
    NotifierProvider<TransactionSearchQueryNotifier, String>(() {
  return TransactionSearchQueryNotifier();
});

/// Stream provider for filtered transactions (optimized - filters in database)
/// Auto-dispose when not watched to free resources
final filteredTransactionsProvider = StreamProvider.autoDispose.family<
    List<db.Transaction>, TransactionFilters>((ref, filters) async* {
  final dao = ref.watch(transactionDaoProvider);
  try {
    await for (final transactions
        in dao.watchTransactionsFiltered(
      categoryId: filters.categoryId,
      searchQuery: filters.searchQuery,
    )) {
      yield transactions;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in filteredTransactionsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});
