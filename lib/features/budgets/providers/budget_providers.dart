import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers/dao_providers.dart';
import '../../../core/services/providers/budget_service_provider.dart'
    show budgetServiceProvider;

/// All budgets stream - persisted across navigation
final budgetsProvider = StreamProvider<List<db.Budget>>((ref) async* {
  ref.keepAlive();
  final dao = ref.watch(budgetDaoProvider);
  await for (final budgets in dao.watchAllBudgets()) {
    yield budgets;
  }
});

/// Active budgets provider - kept alive
final activeBudgetsProvider = FutureProvider<List<db.Budget>>((ref) async {
  ref.keepAlive();
  final dao = ref.watch(budgetDaoProvider);
  return dao.getActiveBudgets();
});

/// Budgets by category provider - kept alive
final budgetsByCategoryProvider = FutureProvider.family<List<db.Budget>, int>((
  ref,
  categoryId,
) async {
  ref.keepAlive();
  final dao = ref.watch(budgetDaoProvider);
  return dao.getBudgetsByCategory(categoryId);
});

/// Single budget provider - kept alive
final budgetProvider = FutureProvider.family<db.Budget, int>((ref, id) async {
  ref.keepAlive();
  final dao = ref.watch(budgetDaoProvider);
  final result = await dao.getBudgetById(id);
  if (result == null) {
    throw Exception('Budget with id $id not found');
  }
  return result;
});

/// Remaining budget for a category - kept alive
final remainingBudgetProvider = FutureProvider.family<double, int>((
  ref,
  categoryId,
) async {
  ref.keepAlive();
  final service = ref.watch(budgetServiceProvider);
  final result = await service.getRemainingBudgetForCategory(categoryId);
  return result ?? 0.0;
});

/// Budget status color for a category - kept alive
final budgetStatusColorProvider = FutureProvider.family<int, int>((
  ref,
  categoryId,
) async {
  ref.keepAlive();
  final service = ref.watch(budgetServiceProvider);
  final result = await service.getBudgetStatusColorForCategory(categoryId);
  return result ?? 0;
});
