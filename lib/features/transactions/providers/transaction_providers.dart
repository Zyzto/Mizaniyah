import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transaction_repository.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../banks/providers/bank_providers.dart';
import '../../../core/database/app_database.dart' as db;

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return TransactionRepository(database);
});

final transactionsProvider = StreamProvider<List<db.Transaction>>((ref) async* {
  ref.keepAlive();
  final repository = ref.watch(transactionRepositoryProvider);
  try {
    await for (final transactions in repository.watchAllTransactions()) {
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

final transactionProvider = FutureProvider.family<db.Transaction?, int>((
  ref,
  id,
) async {
  final repository = ref.watch(transactionRepositoryProvider);
  try {
    return await repository.getTransactionById(id);
  } catch (e, stackTrace) {
    Log.error(
      'Error in transactionProvider for id=$id',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});
