import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../budget_repository.dart';
import '../../../core/services/budget_service.dart';
import '../../../core/database/app_database.dart' as db;
import '../../transactions/providers/transaction_providers.dart';
import '../../banks/providers/bank_providers.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return BudgetRepository(database);
});

final budgetServiceProvider = Provider<BudgetService>((ref) {
  final budgetRepository = ref.watch(budgetRepositoryProvider);
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return BudgetService(budgetRepository, transactionRepository);
});

final budgetsProvider = StreamProvider<List<db.Budget>>((ref) async* {
  ref.keepAlive();
  final repository = ref.watch(budgetRepositoryProvider);
  try {
    await for (final budgets in repository.watchAllBudgets()) {
      yield budgets;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in budgetsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

final activeBudgetsProvider = FutureProvider<List<db.Budget>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  try {
    return await repository.getActiveBudgets();
  } catch (e, stackTrace) {
    Log.error(
      'Error in activeBudgetsProvider',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
});

final budgetsByCategoryProvider = FutureProvider.family<List<db.Budget>, int>((
  ref,
  categoryId,
) async {
  final repository = ref.watch(budgetRepositoryProvider);
  try {
    return await repository.getBudgetsByCategory(categoryId);
  } catch (e, stackTrace) {
    Log.error(
      'Error in budgetsByCategoryProvider for categoryId=$categoryId',
      error: e,
      stackTrace: stackTrace,
    );
    return [];
  }
});

final budgetProvider = FutureProvider.family<db.Budget?, int>((ref, id) async {
  final repository = ref.watch(budgetRepositoryProvider);
  try {
    return await repository.getBudgetById(id);
  } catch (e, stackTrace) {
    Log.error(
      'Error in budgetProvider for id=$id',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});

final remainingBudgetProvider = FutureProvider.family<double?, int>((
  ref,
  categoryId,
) async {
  final service = ref.watch(budgetServiceProvider);
  try {
    return await service.getRemainingBudgetForCategory(categoryId);
  } catch (e, stackTrace) {
    Log.error(
      'Error in remainingBudgetProvider for categoryId=$categoryId',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});

final budgetStatusColorProvider = FutureProvider.family<int?, int>((
  ref,
  categoryId,
) async {
  final service = ref.watch(budgetServiceProvider);
  try {
    return await service.getBudgetStatusColorForCategory(categoryId);
  } catch (e, stackTrace) {
    Log.error(
      'Error in budgetStatusColorProvider for categoryId=$categoryId',
      error: e,
      stackTrace: stackTrace,
    );
    return null;
  }
});
